#requires -Version 7.0
# Local PostgreSQL only. Historical bodies are injected in memory after BEGIN.
# Each psql connection rolls back fixtures and mutations; no SQL file is changed.
$ErrorActionPreference = 'Stop'
$container = 'supabase_db_App_Clinica_Psicologia'
$tests = Get-Content -Raw (Join-Path $PSScriptRoot 'lote-b-clinical-authorization-tests.sql')
$migrations = Join-Path $PSScriptRoot '../migrations'
function Run-Sql([string]$sql) {
  $output = $sql | docker exec -i $container psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1 2>&1
  $code = $LASTEXITCODE
  return @{ Code=$code; Output=($output -join "`n"); Passes=@($output | Select-String 'PASS:').Count }
}
$clean = Run-Sql $tests
if ($clean.Code -ne 0) { throw $clean.Output }
Write-Host "Protected suite: $($clean.Passes) checks passed"
$cases = @(
 @{ Family='lifecycle'; Name='set_patient_active_status'; File='20250620170035_platform_admin_patient_access.sql'; Expected='N01 unlinked target status=true / missing profile allowed forbidden caller' },
 @{ Family='psychologist'; Name='get_patients_data_completion'; File='20260901120000_patients_data_completion_rpc.sql'; Expected='get_patients_data_completion / inactive psychologist allowed forbidden caller' },
 @{ Family='library'; Name='get_my_library'; File='20260805120000_library_indications.sql'; Expected='library / inactive patient allowed forbidden caller' },
 @{ Family='patient helper/view'; Name='current_patient_id'; File='20250525120009_auth_and_rls.sql'; Expected='helper NULL / inactive patient' }
)
foreach ($case in $cases) {
  $historical = Get-Content -Raw (Join-Path $migrations $case.File)
  $pattern = '(?is)CREATE\s+OR\s+REPLACE\s+FUNCTION\s+public\.' + [regex]::Escape($case.Name) + '\s*\(.*?\bAS\s+(?<tag>\$[\w]*\$).*?\k<tag>\s*;'
  $definition = [regex]::Match($historical,$pattern).Value
  if (!$definition) { throw "Historical definition missing: $($case.Name)" }
  $mutant = $tests.Replace('-- MUTATION_INJECTION_POINT',$definition)
  $result = Run-Sql $mutant
  if ($result.Code -eq 0 -or !$result.Output.Contains('FAIL:') -or !$result.Output.Contains($case.Expected)) {
    throw "Mutation failed for unexpected reason ($($case.Family)):`n$($result.Output)"
  }
  Write-Host "PASS mutation $($case.Family): exit $($result.Code), expected bypass: $($case.Expected)"
  # New connection: verifies protected behavior + original effective grants again.
  $restored = Run-Sql $tests
  if ($restored.Code -ne 0 -or $restored.Passes -ne $clean.Passes) { throw $restored.Output }
  Write-Host "PASS restored $($case.Family): $($restored.Passes) checks"
}
# Fifth mutation: remove exactly the three response/patient clinic predicates.
# Guards and every other business condition stay intact.
$current = Get-Content -Raw (Join-Path $migrations '20260914130000_harden_clinical_authorization.sql')
$definitions = @()
foreach ($name in @('get_patients_with_pending_results_release','get_psychologist_alerts')) {
  $pattern = '(?is)CREATE\s+OR\s+REPLACE\s+FUNCTION\s+public\.' + [regex]::Escape($name) + '\s*\(.*?\bAS\s+(?<tag>\$[\w]*\$).*?\k<tag>\s*;'
  $definition = [regex]::Match($current,$pattern).Value
  if (!$definition) { throw "Protected definition missing: $name" }
  $definitions += $definition
}
$protected = $definitions -join "`n"
$predicate = ' AND qr.clinic_id = p.clinic_id'
if ([regex]::Matches($protected,[regex]::Escape($predicate)).Count -ne 3) {
  throw 'Expected exactly three cross-clinic protections'
}
$mutation = $protected.Replace($predicate,'')
$result = Run-Sql $tests.Replace('-- MUTATION_INJECTION_POINT',$mutation)
$expected = 'FAIL: cross-clinic B pending ignores A / A age=40'
if ($result.Code -eq 0 -or !$result.Output.Contains($expected)) {
  throw "Cross-clinic mutation failed for unexpected reason:`n$($result.Output)"
}
Write-Host "PASS mutation cross-clinic: exit $($result.Code), $expected"
$restored = Run-Sql $tests
if ($restored.Code -ne 0 -or $restored.Passes -ne $clean.Passes) { throw $restored.Output }
Write-Host "PASS restored cross-clinic: $($restored.Passes) checks"
Write-Host 'All five mutation families detected; protected suite restored.'
