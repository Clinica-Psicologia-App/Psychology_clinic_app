#requires -Version 7.0
# Local integration test: start Supabase + `supabase functions serve` first.
# Uses only synthetic accounts and cleans up its unique fixture prefix in finally.
param([switch]$SkipPublicSignup, [switch]$AuthOnly)
$ErrorActionPreference = 'Stop'
$localConfig = supabase status -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Local Supabase status unavailable' }
$apiBase = $localConfig.API_URL.TrimEnd('/')
if (([uri]$apiBase).Host -notin @('127.0.0.1', 'localhost', '::1')) {
  throw 'This test only accepts the local Supabase API'
}
$anonKey = $localConfig.ANON_KEY
$serviceKey = $localConfig.SERVICE_ROLE_KEY
if (!$anonKey -or !$serviceKey) { throw 'Local API keys unavailable' }
$fixturePrefix = 'f03-http-' + [guid]::NewGuid().ToString('N')
$fixturePassword = 'TestAa1!' + [guid]::NewGuid().ToString('N')
$clinicId = '11111111-1111-1111-1111-111111111101'
$psychId = '11111111-1111-1111-1111-111111111103'
$script:passed = 0

function Assert-Test($condition, [string]$label) {
  if (!$condition) { throw "FAIL: $label" }
  $script:passed++
  Write-Host "PASS: $label"
}
function Request([string]$method, [string]$path, [string]$token, $body = $null) {
  $headers = @{ apikey = $anonKey; Authorization = "Bearer $token" }
  if ($token -eq $serviceKey) { $headers.apikey = $serviceKey }
  $parameters = @{ Method = $method; Uri = "$apiBase$path"; Headers = $headers
    ContentType = 'application/json'; SkipHttpErrorCheck = $true }
  if ($null -ne $body) { $parameters.Body = $body | ConvertTo-Json -Depth 12 -Compress }
  $response = Invoke-WebRequest @parameters
  $data = if ($response.Content) { $response.Content | ConvertFrom-Json -NoEnumerate } else { $null }
  return [pscustomobject]@{ Status = [int]$response.StatusCode; Data = $data }
}
function Login([string]$email, [string]$password) {
  $response = Request POST '/auth/v1/token?grant_type=password' $anonKey @{ email = $email; password = $password }
  if ($response.Status -ne 200 -or !$response.Data.access_token) { throw 'Fixture login failed' }
  return $response.Data.access_token
}
function Profile([string]$id) {
  $response = Request GET "/rest/v1/profiles?id=eq.$id&select=*" $serviceKey
  if ($response.Status -ne 200) { throw 'Profile verification failed' }
  return $response.Data
}
function Verify-Provisioned([string]$id, [string]$role, [string]$label) {
  $rows = @(Profile $id)
  Assert-Test ($rows.Count -eq 1 -and $rows[0].role -eq $role -and
    $rows[0].clinic_id -eq $clinicId -and $rows[0].is_active -eq $true) $label
}

try {
  if (!$SkipPublicSignup) {
    $signupIds = @()
    foreach ($case in @('hostile', 'plain')) {
      $metadata = if ($case -eq 'hostile') { @{
        full_name = "$fixturePrefix-$case"; role = 'platform_admin'; clinic_id = $clinicId
        is_active = $true; can_receive_patients = $true; patient_assignment_limit = 999999
        administrative_flags = @{ billing_admin = $true }; app_metadata = @{ role = 'platform_admin' }
      } } else { @{ full_name = "$fixturePrefix-$case" } }
      $response = Request POST '/auth/v1/signup' $anonKey @{
        email = "$fixturePrefix-$case@example.test"; password = $fixturePassword; data = $metadata
        role = 'service_role'
        app_metadata = @{ role = 'platform_admin'; clinic_id = $clinicId }
      }
      $id = if ($response.Data.user) { $response.Data.user.id } else { $response.Data.id }
      Assert-Test ($response.Status -eq 200 -and $id) "public Auth signup accepted: $case"
      $signupIds += $id
      Assert-Test (@(Profile $id).Count -eq 0) "signup grants no profile: $case"
      $authUser = Request GET "/auth/v1/admin/users/$id" $serviceKey
      Assert-Test ($authUser.Data.app_metadata.role -ne 'platform_admin') 'public request cannot set app_metadata role'
      Assert-Test ($authUser.Data.role -eq 'authenticated') 'public request cannot choose its Auth/JWT role'
    }

    # Server-side email confirmation allows testing a valid session during the
    # Auth/profile gap. Confirmation itself must not provision a profile.
    $id = $signupIds[0]
    $confirmed = Request PUT "/auth/v1/admin/users/$id" $serviceKey @{ email_confirm = $true }
    Assert-Test ($confirmed.Status -eq 200) 'confirm public Auth identity for gap test'
    $publicToken = Login "$fixturePrefix-hostile@example.test" $fixturePassword
    Assert-Test (@(Profile $id).Count -eq 0) 'confirmed session still has no profile'
    $attempt = Request POST '/rest/v1/profiles' $publicToken @{
      id = $id; clinic_id = $clinicId; full_name = $fixturePrefix
      email = "$fixturePrefix-hostile@example.test"; role = 'platform_admin'; is_active = $true
    }
    Assert-Test ($attempt.Status -eq 403 -and $attempt.Data.code -eq '42501') 'direct REST self-provisioning denied by RLS'
    $updated = Request PUT '/auth/v1/user' $publicToken @{ data = @{ role = 'psychologist'; clinic_id = $clinicId; is_active = $true } }
    Assert-Test ($updated.Status -eq 200 -and @(Profile $id).Count -eq 0) 'editing user metadata cannot fill provisioning gap'

    if (!$AuthOnly) {
      # Change the signed role claim without possessing the signing key.
      $jwtParts = $publicToken.Split('.')
      $payload64 = $jwtParts[1].Replace('-', '+').Replace('_', '/')
      $payload64 = $payload64.PadRight($payload64.Length + ((4 - $payload64.Length % 4) % 4), '=')
      $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload64)) | ConvertFrom-Json -AsHashtable
      $claims.role = 'service_role'
      $forgedPayload = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes(($claims | ConvertTo-Json -Depth 12 -Compress))).TrimEnd('=').Replace('+', '-').Replace('/', '_')
      $forgedToken = $jwtParts[0] + '.' + $forgedPayload + '.' + $jwtParts[2]
      $forged = Request POST '/functions/v1/create-staff-user' $forgedToken @{}
      Assert-Test ($forged.Status -eq 401) 'forged JWT role rejected before provisioning'
      foreach ($fn in @('create-staff-user', 'create-patient')) {
        $denied = Request POST "/functions/v1/$fn" $publicToken @{
          email = "$fixturePrefix-forged@example.test"; password = $fixturePassword
          full_name = $fixturePrefix; role = 'platform_admin'; clinic_id = $clinicId
          responsible_psychologist_id = $psychId
        }
        Assert-Test ($denied.Status -eq 403 -and $denied.Data.error.code -eq 'FORBIDDEN') "account without profile denied by $fn"
      }
    }
  }

  if (!$AuthOnly) {
    # Admin Auth API also does not infer application privileges from metadata.
    # This fixture exercises the gap without sending another signup email.
    $unprovisioned = Request POST '/auth/v1/admin/users' $serviceKey @{
      email = "$fixturePrefix-gap@example.test"; password = $fixturePassword; email_confirm = $true
      user_metadata = @{ role = 'platform_admin'; clinic_id = $clinicId; is_active = $true }
    }
    Assert-Test ($unprovisioned.Status -eq 200 -and $unprovisioned.Data.id) 'Admin Auth API creates identity only'
    Assert-Test (@(Profile $unprovisioned.Data.id).Count -eq 0) 'Admin Auth API metadata does not provision privileges'
    $gapToken = Login "$fixturePrefix-gap@example.test" $fixturePassword
    foreach ($fn in @('create-staff-user', 'create-patient')) {
      $denied = Request POST "/functions/v1/$fn" $gapToken @{
        email = "$fixturePrefix-gap-forged@example.test"; password = $fixturePassword
        full_name = $fixturePrefix; role = 'platform_admin'; clinic_id = $clinicId
        responsible_psychologist_id = $psychId
      }
      Assert-Test ($denied.Status -eq 403 -and $denied.Data.error.code -eq 'FORBIDDEN') "provisioning gap denied by $fn"
    }
    $adminToken = Login 'admin@clinicateste-mvp.example' 'TesteMVP2025!'
    $psychToken = Login 'psicologo@clinicateste-mvp.example' 'TesteMVP2025!'
    $staffPayload = @{ email = "$fixturePrefix-staff@example.test"; password = $fixturePassword
      full_name = "$fixturePrefix-staff"; role = 'psychologist'; clinic_id = $clinicId }
    $denied = Request POST '/functions/v1/create-staff-user' $psychToken $staffPayload
    Assert-Test ($denied.Status -eq 403 -and $denied.Data.error.code -eq 'FORBIDDEN') 'psychologist cannot provision staff'
    $staff = Request POST '/functions/v1/create-staff-user' $adminToken $staffPayload
    Assert-Test ($staff.Status -eq 200 -and $staff.Data.ok) 'administrator creates staff through Edge Function'
    Verify-Provisioned $staff.Data.data.profile.id 'psychologist' 'staff profile provisioned explicitly'

    $patientPayload = @{ email = "$fixturePrefix-patient@example.test"; password = $fixturePassword
      full_name = "$fixturePrefix-patient"; responsible_psychologist_id = $psychId
      role = 'platform_admin'; clinic_id = 'b1000000-0000-0000-0000-000000000099'
      is_active = $false; patient_assignment_limit = 999999 }
    $patient = Request POST '/functions/v1/create-patient' $psychToken $patientPayload
    Assert-Test ($patient.Status -eq 200 -and $patient.Data.ok) 'psychologist creates patient through Edge Function'
    Verify-Provisioned $patient.Data.data.profile_id 'patient' 'patient privilege fields come from server, not request extras'
    $patientProfile = @(Profile $patient.Data.data.profile_id)[0]
    Assert-Test ($null -eq $patientProfile.patient_assignment_limit) 'client quota ignored'
    $duplicate = Request POST '/functions/v1/create-patient' $psychToken $patientPayload
    Assert-Test ($duplicate.Status -eq 409) 'duplicate account creation rejected'
    Verify-Provisioned $patient.Data.data.profile_id 'patient' 'duplicate attempt preserves existing profile'

    # Insert a trusted invitation fixture directly; do not send email externally.
    $invitationToken = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
    $digest = [System.Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($invitationToken))
    $tokenHash = [Convert]::ToHexString($digest).ToLowerInvariant()
    $invitation = Request POST '/rest/v1/patient_invitations' $serviceKey @{
      clinic_id = $clinicId; invited_by = $psychId; responsible_psychologist_id = $psychId
      email = "$fixturePrefix-invited@example.test"; full_name = "$fixturePrefix-invited"
      token_hash = $tokenHash; expires_at = [DateTime]::UtcNow.AddHours(1).ToString('o')
    }
    Assert-Test ($invitation.Status -eq 201) 'trusted invitation fixture created'
    $accepted = Request POST '/functions/v1/accept-patient-invitation' $anonKey @{
      token = $invitationToken; password = $fixturePassword
      profile = @{ full_name = "$fixturePrefix-invited"; role = 'platform_admin'
        clinic_id = 'b1000000-0000-0000-0000-000000000099'; is_active = $false }
      legal_consent = @{ terms_version = 'f03-test'; privacy_version = 'f03-test' }
    }
    Assert-Test ($accepted.Status -eq 200 -and $accepted.Data.ok) 'patient accepts invitation through Edge Function'
    Verify-Provisioned $accepted.Data.data.profile_id 'patient' 'invitation controls role/clinic, not submitted profile extras'
  }
  Write-Host "F03 HTTP checks passed: $script:passed"
} finally {
  # Prefix is generated here from a GUID, never supplied by a caller. Match only
  # this run's synthetic accounts and dependent records; preserve seed accounts.
  $cleanupSql = @"
BEGIN;
CREATE TEMP TABLE f03_http_ids AS
  SELECT id FROM auth.users WHERE email LIKE '$fixturePrefix%'
  UNION SELECT id FROM public.patients WHERE email LIKE '$fixturePrefix%'
  UNION SELECT id FROM public.patient_invitations WHERE email LIKE '$fixturePrefix%';
DELETE FROM public.patients WHERE email LIKE '$fixturePrefix%';
DELETE FROM public.patient_invitations WHERE email LIKE '$fixturePrefix%';
DELETE FROM auth.users WHERE email LIKE '$fixturePrefix%';
DELETE FROM public.audit_events WHERE entity_id IN (SELECT id FROM f03_http_ids)
  OR actor_profile_id IN (SELECT id FROM f03_http_ids);
COMMIT;
"@
  $cleanupSql | docker exec -i supabase_db_App_Clinica_Psicologia psql -U postgres -d postgres -X -v ON_ERROR_STOP=1 | Out-Null
  if ($LASTEXITCODE -ne 0) { throw "Fixture cleanup failed for prefix $fixturePrefix" }
  Write-Host 'F03 HTTP fixtures cleaned up'
}
