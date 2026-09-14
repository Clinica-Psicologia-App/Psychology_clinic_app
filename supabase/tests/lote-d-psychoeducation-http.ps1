#requires -Version 7.0
# Local Auth/PostgREST only; synthetic identities are removed in finally.
$ErrorActionPreference='Stop'
$config=supabase status -o json | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) { throw 'Local status unavailable' }
$base=$config.API_URL.TrimEnd('/')
if (([uri]$base).Host -notin @('127.0.0.1','localhost','::1')) { throw 'Local only' }
$anon=$config.ANON_KEY; $service=$config.SERVICE_ROLE_KEY
$prefix='lote-d-http-'+[guid]::NewGuid().ToString('N')
$password='TestAa1!'+[guid]::NewGuid().ToString('N')
$ids=[Collections.Generic.List[string]]::new()
$script:passed=0
function Check($ok,$label) {
 if (!$ok) { throw "FAIL: $label" }
 $script:passed++; Write-Host "PASS: $label"
}
function Request($method,$path,$token,$body) {
 $key=if($token -eq $service){$service}else{$anon}
 $p=@{Method=$method;Uri="$base$path";Headers=@{apikey=$key;Authorization="Bearer $token"};ContentType='application/json';SkipHttpErrorCheck=$true}
 if($null -ne $body){$p.Body=$body|ConvertTo-Json -Depth 8 -Compress}
 $r=Invoke-WebRequest @p
 return @{Status=[int]$r.StatusCode;Text=$r.Content;Data=($r.Content|ConvertFrom-Json -NoEnumerate)}
}
try {
 $baseline=$null
 foreach($case in @('anon','missing','inactive_patient','inactive_psychologist','platform_admin','patient','psychologist')) {
  $token=$anon
  if($case -ne 'anon') {
   $email="$prefix-$case@example.test"
   $u=Request POST '/auth/v1/admin/users' $service @{email=$email;password=$password;email_confirm=$true}
   if($u.Status -ne 200 -or !$u.Data.id){throw 'Auth fixture failed'}
   $id=$u.Data.id; $ids.Add($id)
   if($case -ne 'missing') {
    $role=$case.Replace('inactive_','')
    $p=Request POST '/rest/v1/profiles' $service @{id=$id;email=$email;full_name='Lote D fixture';role=$role;clinic_id='11111111-1111-1111-1111-111111111101';is_active=(!$case.StartsWith('inactive_'))}
    if($p.Status -ne 201){throw 'Profile fixture failed'}
   }
   $login=Request POST '/auth/v1/token?grant_type=password' $anon @{email=$email;password=$password}
   $token=$login.Data.access_token
   if(!$token){throw 'Fixture login failed'}
  }
  $r=Request POST '/rest/v1/rpc/get_psychoeducation_journey' $token @{}
  $allowed=$case -in @('patient','psychologist')
  $expected=if($allowed){200}elseif($case -eq 'anon'){401}else{403}
  Check ($r.Status -eq $expected) "$case HTTP $expected"
  if(!$allowed) {
   Check ($r.Data.code -eq '42501' -and $r.Text -notmatch '"(cards|patient_text|presentation|closing|cover_url)"') "$case no partial catalogue"
  } else {
   Check (@($r.Data).Count -gt 0) "$case published catalogue nonempty"
   foreach($module in $r.Data) {
    if((($module.PSObject.Properties.Name|Sort-Object)-join ',') -ne 'accent_color,cards,closing,cover_url,id,number,presentation,stage,title'){throw 'Module contract changed'}
    foreach($card in $module.cards){if((($card.PSObject.Properties.Name|Sort-Object)-join ',') -ne 'exercise,image_url,patient_text,reflection,title'){throw 'Card contract changed'}}
   }
   Check $true "$case exact field allowlist"
   if($null -ne $baseline){Check ($baseline -eq $r.Text) 'patient and psychologist identical catalogue'}
   $baseline=$r.Text
   Write-Host "Published modules: $(@($r.Data).Count)"
  }
 }
 Write-Host "Lote D HTTP checks passed: $script:passed"
} finally {
 $failed=@()
 foreach($id in $ids) {
  try { $r=Request DELETE "/auth/v1/admin/users/$id" $service $null; if($r.Status -ne 200){$failed+=$id} }
  catch { $failed+=$id }
 }
 if($failed.Count){throw "Cleanup failed for $($failed.Count) identities"}
 Write-Host "Cleaned $($ids.Count) synthetic identities"
}
