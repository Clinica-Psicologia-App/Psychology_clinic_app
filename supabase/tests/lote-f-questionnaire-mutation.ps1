#requires -Version 7.0
# Requires the isolated project used for F. SQL mutants live in transactions;
# the HTTP mutant restores the exact source bytes in finally and reloads Edge.
$ErrorActionPreference='Stop'
$cfg=supabase status -o json 2>$null | ConvertFrom-Json
if($LASTEXITCODE -ne 0 -or ([uri]$cfg.API_URL).Host -notin @('127.0.0.1','localhost')){throw 'Local Supabase required'}
$configText=Get-Content -Raw 'supabase/config.toml'
$project=[regex]::Match($configText,'(?m)^project_id\s*=\s*"([^"]+)"').Groups[1].Value
if($project -notlike 'lote_f_*'){throw 'Mutation requires an isolated lote_f_ project'}
$container="supabase_db_$project"
$edge="supabase_edge_runtime_$project"
$dbPassword=[uri]::UnescapeDataString(([uri]$cfg.DB_URL).UserInfo.Split(':',2)[1])
function Wait-Edge {
  for($attempt=0;$attempt -lt 40;$attempt++){
    try {
      $ready=Invoke-WebRequest -Method Options -Uri "$($cfg.API_URL)/functions/v1/submit-questionnaire-answer" -SkipHttpErrorCheck
      if($ready.StatusCode -in @(200,204)){return}
    } catch {}
    Start-Sleep -Milliseconds 250
  }
  throw 'Isolated Edge did not become ready'
}
function Run-Sql($sql){
  $out=$sql | docker exec -e "PGPASSWORD=$dbPassword" -i $container psql -U supabase_admin -d postgres -X -A -t -v ON_ERROR_STOP=1 2>&1
  @{Code=$LASTEXITCODE;Text=($out -join "`n");Passes=@($out|Select-String 'PASS:').Count}
}
$suite=Get-Content -Raw (Join-Path $PSScriptRoot 'lote-f-questionnaire-authorization-tests.sql')
$fingerprint=@'
SELECT md5((SELECT string_agg(row_to_json(p)::text,'' ORDER BY tablename,policyname) FROM pg_policies p WHERE schemaname='public') ||
 (SELECT string_agg(pg_get_functiondef(p.oid)||coalesce(p.proacl::text,'')||p.proowner::text,'' ORDER BY p.oid) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prokind='f') ||
 (SELECT string_agg(pg_get_triggerdef(oid),'' ORDER BY oid) FROM pg_trigger WHERE NOT tgisinternal));
'@
$before=Run-Sql $fingerprint
$clean=Run-Sql $suite
if($clean.Code -ne 0){throw $clean.Text}
Write-Host "Protected SQL: $($clean.Passes) checks"
$mutants=@(
  @{Name='N01';Expected='FAIL: N01 identity fa000000-0000-0000-0000-000000000101';Sql=@'
DROP POLICY qsa_staff_all ON public.questionnaire_schema_activations;
CREATE POLICY qsa_staff_all ON public.questionnaire_schema_activations FOR ALL TO authenticated
USING(public.is_staff() AND clinic_id=public.current_clinic_id()) WITH CHECK(public.is_staff() AND clinic_id=public.current_clinic_id());
'@},
  @{Name='F05';Expected='FAIL: F05 private sentinel not exposed';Sql=@'
CREATE POLICY qsa_patient_select ON public.questionnaire_schema_activations FOR SELECT TO authenticated
USING(NOT public.is_staff() AND clinic_id=public.current_clinic_id() AND EXISTS(SELECT 1 FROM public.questionnaire_responses r WHERE r.id=questionnaire_response_id AND public.user_can_access_patient(r.patient_id)));
'@},
  @{Name='F07';Expected='FAIL: F07 sentinel persisted state unchanged';Sql=@'
DROP TRIGGER guard_patient_questionnaire_write ON public.questionnaire_responses;
DROP TRIGGER guard_patient_questionnaire_write ON public.questionnaire_answers;
'@}
)
foreach($mutant in $mutants){
  if($mutant.Name -in @('F05','F07')){
    $fixturePrefix=$suite.Substring(0,$suite.IndexOf('-- FIXTURES_READY'))
    $actor=@'
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111104","role":"authenticated"}',true);
'@
    $proof=if($mutant.Name -eq 'F05'){@'
SELECT pg_temp.check_true((SELECT psi_observation='PRIVATE_PSI_OBSERVATION_LOTE_F' FROM public.questionnaire_schema_activations WHERE schema_code='LOTE_F'),'MUTANT F05 exact private sentinel exposed');
ROLLBACK;
'@}else{@'
UPDATE public.questionnaire_answers SET professional_note='PATIENT_FORGED_LOTE_F' WHERE id='fa000000-0000-0000-0000-000000000802';
RESET ROLE;
SELECT pg_temp.check_true((SELECT professional_note='PATIENT_FORGED_LOTE_F' FROM public.questionnaire_answers WHERE id='fa000000-0000-0000-0000-000000000802'),'MUTANT F07 exact forged sentinel persisted');
ROLLBACK;
'@}
    $verified=Run-Sql ($fixturePrefix+"`n"+$mutant.Sql+"`n"+$actor+"`n"+$proof)
    if($verified.Code -ne 0 -or !$verified.Text.Contains("PASS: MUTANT $($mutant.Name) exact")){throw "Mutant did not reproduce the data breach: $($verified.Text)"}
    Write-Host "PASS mutation $($mutant.Name): exact sentinel read back from vulnerable state"
  }
  $injected=$suite.Replace("BEGIN;","BEGIN;`n$($mutant.Sql)")
  $result=Run-Sql $injected
  if($result.Code -ne 3 -or !$result.Text.Contains($mutant.Expected)){throw "Mutation $($mutant.Name) not detected as intended: $($result.Text)"}
  $after=Run-Sql $fingerprint
  if($after.Code -ne 0 -or $after.Text -ne $before.Text){throw 'SQL fingerprint changed after rollback'}
  Write-Host "PASS mutation $($mutant.Name): killed; full catalog fingerprint restored"
}
# Extra F07 variant restores the pre-review timestamp behavior.
$contextMutant=@'
DO $mutation$
DECLARE definition text; old_block text := $block$    -- Patient JWT is also used by answer synchronization and official finish.
    -- Never trust its timestamp: generate on transition, preserve on repetition.
    -- This runs before the legacy validator, which otherwise retains input dates.
    IF TG_OP='UPDATE' THEN
      IF NEW.status='completed' THEN
        NEW.completed_at:=CASE WHEN OLD.status='completed' THEN OLD.completed_at ELSE now() END;
      ELSE
        NEW.completed_at:=NULL;
      END IF;
    END IF;$block$;
BEGIN
 definition:=pg_get_functiondef('public.guard_patient_questionnaire_write()'::regprocedure);
 IF position(old_block in definition)=0 THEN RAISE EXCEPTION 'Timestamp mutation anchor missing'; END IF;
 EXECUTE replace(definition,old_block,'');
END $mutation$;
'@
$contextResult=Run-Sql ($suite.Replace("BEGIN;","BEGIN;`n$contextMutant"))
if($contextResult.Code -ne 3 -or !$contextResult.Text.Contains('FAIL: F07 context timestamp persisted state unchanged')){throw "Timestamp regression not detected: $($contextResult.Text)"}
$after=Run-Sql $fingerprint
if($after.Text -ne $before.Text){throw 'Timestamp mutation rollback failed'}
Write-Host 'PASS mutation F07 completed_at: historical guard detected by changed persisted state; rollback verified'
$handler=Join-Path $PSScriptRoot '../functions/finish-questionnaire/index.ts'
$bytes=[IO.File]::ReadAllBytes($handler)
$source=[Text.Encoding]::UTF8.GetString($bytes)
$pattern=[regex]::new('response: completedResponse,')
$mutated=$pattern.Replace($source,"response: completedResponse,`n        results: resultsPayload,",1)
if($mutated -eq $source){throw 'Historical payload injection point missing'}
$killed=$false
try {
  [IO.File]::WriteAllText($handler,$mutated)
  $null=docker restart $edge
  if($LASTEXITCODE -ne 0){throw 'Cannot reload isolated Edge'}
  Wait-Edge
  try { $null=& (Join-Path $PSScriptRoot 'lote-f-questionnaire-http.ps1') }
  catch { if($_.Exception.Message -like '*FAIL: finish excludes all clinical payloads*'){$killed=$true}else{throw} }
} finally {
  [IO.File]::WriteAllBytes($handler,$bytes)
  $null=docker restart $edge
  if($LASTEXITCODE -ne 0){throw 'Cannot restore isolated Edge runtime'}
  Wait-Edge
}
if(!$killed){throw 'F08 historical HTTP payload survived'}
if([Convert]::ToBase64String([IO.File]::ReadAllBytes($handler)) -ne [Convert]::ToBase64String($bytes)){throw 'Edge source restoration failed'}
Write-Host 'PASS mutation F08: real HTTP killed historical result payload; exact bytes restored'
$restored=Run-Sql $suite
if($restored.Code -ne 0 -or $restored.Passes -ne $clean.Passes){throw $restored.Text}
& (Join-Path $PSScriptRoot 'lote-f-questionnaire-http.ps1')
Write-Host 'PASS all four mutations killed; protected SQL and HTTP suites restored'
