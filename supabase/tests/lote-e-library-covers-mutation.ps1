#requires -Version 7.0
# Only the local container; injection stays in memory and rolls back on disconnect.
$ErrorActionPreference = 'Stop'
$container = 'supabase_db_App_Clinica_Psicologia'
$tests = Get-Content -Raw (Join-Path $PSScriptRoot 'lote-e-library-covers-tests.sql')
function Run-Sql([string]$sql) {
  $output = $sql | docker exec -i $container psql -U supabase_admin -d postgres -X -v ON_ERROR_STOP=1 2>&1
  return @{ Code=$LASTEXITCODE; Output=($output -join "`n"); Passes=@($output | Select-String 'PASS:').Count }
}
$clean = Run-Sql $tests
if ($clean.Code -ne 0) { throw $clean.Output }
Write-Host "Protected: $($clean.Passes) checks"
$fingerprintSql = "SELECT md5(pg_get_functiondef(oid)||proacl::text||proowner::text||(SELECT string_agg(row_to_json(q)::text,'' ORDER BY policyname) FROM pg_policies q WHERE schemaname='storage' AND tablename='objects')) FROM pg_proc WHERE oid='public.is_library_cover_admin()'::regprocedure;"
$before = Run-Sql $fingerprintSql
if ($before.Code -ne 0) { throw $before.Output }
$historical = Get-Content -Raw (Join-Path $PSScriptRoot '../migrations/20260810120000_fix_library_cover_admin_metadata.sql')
$pattern = '(?is)CREATE\s+OR\s+REPLACE\s+FUNCTION\s+public\.is_library_cover_admin\s*\(.*?\bAS\s+(?<tag>\$[\w]*\$).*?\k<tag>\s*;'
$definition = [regex]::Match($historical,$pattern).Value
if (!$definition) { throw 'Historical function missing' }
$mutant = Run-Sql $tests.Replace('-- MUTATION_INJECTION_POINT',$definition)
$expected = 'FAIL: inactive claim INSERT denied'
if ($mutant.Code -ne 3 -or !$mutant.Output.Contains($expected)) { throw $mutant.Output }
Write-Host "PASS historical mutation: $expected (exit $($mutant.Code))"
$after = Run-Sql $fingerprintSql
if ($after.Code -ne 0 -or $after.Output -ne $before.Output) { throw 'Definition/owner/grants not restored' }
$restored = Run-Sql $tests
if ($restored.Code -ne 0 -or $restored.Passes -ne $clean.Passes) { throw $restored.Output }
Write-Host "PASS complete rollback and protected suite: $($restored.Passes) checks"
