#requires -Version 7.0
# Run from the isolated Supabase project directory. Never targets a remote URL.
$ErrorActionPreference='Stop'
$cfg=supabase status -o json 2>$null | ConvertFrom-Json
if($LASTEXITCODE -ne 0){throw 'Local Supabase unavailable'}
$base=$cfg.API_URL.TrimEnd('/')
if(([uri]$base).Host -notin @('localhost','127.0.0.1','::1')){throw 'Local only'}
$anon=$cfg.ANON_KEY; $service=$cfg.SERVICE_ROLE_KEY
$script:checks=0
function Check($ok,$label){if(!$ok){throw "FAIL: $label"};$script:checks++;Write-Host "PASS: $label"}
function Invoke-ProbeRequest($method,$path,$token,$body=$null){
  $key=if($token -eq $service){$service}else{$anon}
  $args=@{Method=$method;Uri="$base$path";SkipHttpErrorCheck=$true;Headers=@{apikey=$key;Authorization="Bearer $token";Prefer='return=representation'}}
  if($null -ne $body){$args.ContentType='application/json';$args.Body=ConvertTo-Json -InputObject $body -Depth 30 -Compress}
  $r=Invoke-WebRequest @args
  $data=if($r.Content){ConvertFrom-Json -InputObject $r.Content -Depth 50 -NoEnumerate}else{$null}
  @{Status=[int]$r.StatusCode;Data=$data;Text=$r.Content}
}
function Assert-Unchanged($path,$token,$body,$label,[bool]$normalized=$false){
  $before=Invoke-ProbeRequest GET "$path&select=*" $service
  Check ($before.Status -eq 200 -and @($before.Data).Count -eq 1) "$label target exists"
  $attempt=Invoke-ProbeRequest PATCH "$path&select=id" $token $body
  $denied=$attempt.Status -eq 403 -and $attempt.Data.code -eq '42501'
  $zero=$attempt.Status -eq 200 -and $attempt.Text -eq '[]'
  $ignored=$normalized -and $attempt.Status -eq 200 -and @($attempt.Data).Count -eq 1 -and $attempt.Data[0].id -eq $before.Data[0].id
  Check ($denied -or $zero -or $ignored) "$label coherent authorization/normalization HTTP=$($attempt.Status)"
  $after=Invoke-ProbeRequest GET "$path&select=*" $service
  Check ($after.Status -eq 200 -and @($after.Data).Count -eq 1) "$label target still exists"
  $beforeRow=$before.Data[0] | Select-Object * -ExcludeProperty updated_at
  $afterRow=$after.Data[0] | Select-Object * -ExcludeProperty updated_at
  Check (($beforeRow|ConvertTo-Json -Depth 40 -Compress) -ceq ($afterRow|ConvertTo-Json -Depth 40 -Compress)) "$label persisted values unchanged"
  if($body.ContainsKey('completed_at')){Write-Host "EVIDENCE $label before=$(ConvertTo-Json -InputObject $before.Data[0].completed_at -Compress) attempted=$(ConvertTo-Json -InputObject $body.completed_at -Compress) after=$(ConvertTo-Json -InputObject $after.Data[0].completed_at -Compress) HTTP=$($attempt.Status)"}
}
# Three paired controls use the SAME restored fixture and SAME request body.
function Test-ValidIdentityWrites($token,$source){
  $prefix='lote-f-identity-'+[guid]::NewGuid().ToString('N')
  $userB='fbf10000'+[guid]::NewGuid().ToString().Substring(8)
  $patientB='fbf10000'+[guid]::NewGuid().ToString().Substring(8)
  $responseIds=[Collections.Generic.List[string]]::new()
  $entityIds=[Collections.Generic.List[string]]::new()
  $entityIds.Add($userB);$entityIds.Add($patientB)
  try {
    $owner=Invoke-ProbeRequest GET "/rest/v1/patients?id=eq.$patient&select=id,clinic_id,profile_id,responsible_psychologist_id" $service
    $who=Invoke-ProbeRequest GET '/auth/v1/user' $token
    Check ($owner.Status -eq 200 -and @($owner.Data).Count -eq 1 -and $who.Status -eq 200 -and $owner.Data[0].profile_id -eq $who.Data.id -and $owner.Data[0].clinic_id -eq $source.clinic_id) 'identity fixture Patient A exists, matches JWT and clinic'
    $auth=Invoke-ProbeRequest POST '/auth/v1/admin/users' $service @{id=$userB;email="$prefix@example.test";password=('TestAa1!'+[guid]::NewGuid().ToString('N'));email_confirm=$true}
    Check ($auth.Status -eq 200 -and $auth.Data.id -eq $userB) 'identity fixture B Auth exists'
    $profile=Invoke-ProbeRequest POST '/rest/v1/profiles' $service @{id=$userB;clinic_id=$source.clinic_id;full_name=$prefix;email="$prefix@example.test";role='patient';is_active=$true}
    Check ($profile.Status -eq 201 -and $profile.Data[0].id -eq $userB -and $profile.Data[0].clinic_id -eq $source.clinic_id) 'identity fixture B active profile in same clinic'
    $createdB=Invoke-ProbeRequest POST '/rest/v1/patients' $service @{id=$patientB;clinic_id=$source.clinic_id;profile_id=$userB;full_name=$prefix;responsible_psychologist_id=$owner.Data[0].responsible_psychologist_id}
    $b=Invoke-ProbeRequest GET "/rest/v1/patients?id=eq.$patientB&select=id,clinic_id,profile_id" $service
    Check ($createdB.Status -eq 201 -and $b.Status -eq 200 -and @($b.Data).Count -eq 1 -and $b.Data[0].profile_id -eq $userB -and $b.Data[0].clinic_id -eq $owner.Data[0].clinic_id) 'identity fixture Patient B exists with coherent profile and clinic'
    $q1=Invoke-ProbeRequest GET "/rest/v1/questionnaires?id=eq.$($source.questionnaire_id)&select=id" $service
    $q2=Invoke-ProbeRequest GET '/rest/v1/questionnaires?code=eq.PARENTAL_STYLES_V1&select=id' $service
    Check ($q1.Status -eq 200 -and @($q1.Data).Count -eq 1 -and $q2.Status -eq 200 -and @($q2.Data).Count -eq 1 -and $q1.Data[0].id -ne $q2.Data[0].id) 'identity fixtures Q1 and distinct Q2 both exist'
    $v1=Invoke-ProbeRequest GET "/rest/v1/questionnaire_versions?id=eq.$($source.questionnaire_version_id)&select=id,questionnaire_id" $service
    $v2=Invoke-ProbeRequest GET "/rest/v1/questionnaire_versions?questionnaire_id=eq.$($q2.Data[0].id)&status=eq.active&select=id,questionnaire_id&limit=1" $service
    Check ($v1.Status -eq 200 -and @($v1.Data).Count -eq 1 -and $v1.Data[0].questionnaire_id -eq $q1.Data[0].id -and $v2.Status -eq 200 -and @($v2.Data).Count -eq 1 -and $v2.Data[0].questionnaire_id -eq $q2.Data[0].id) 'identity Q1/Q2 version references exist and agree'
    foreach($field in @('patient_id','questionnaire_id','id')){
      $id1='fbf10000'+[guid]::NewGuid().ToString().Substring(8)
      $id2='fbf10000'+[guid]::NewGuid().ToString().Substring(8)
      $responseIds.Add($id1);$responseIds.Add($id2);$entityIds.Add($id1);$entityIds.Add($id2)
      $fixture=@{id=$id1;patient_id=$patient;clinic_id=$source.clinic_id;questionnaire_id=$q1.Data[0].id;questionnaire_version_id=$v1.Data[0].id;status='draft'}
      $created=Invoke-ProbeRequest POST '/rest/v1/questionnaire_responses' $service $fixture
      $original=Invoke-ProbeRequest GET "/rest/v1/questionnaire_responses?id=eq.$id1&select=*" $service
      Check ($created.Status -eq 201 -and $original.Status -eq 200 -and @($original.Data).Count -eq 1 -and $original.Data[0].patient_id -eq $patient -and $original.Data[0].questionnaire_id -eq $q1.Data[0].id -and $original.Data[0].clinic_id -eq $source.clinic_id) "identity $field original response exists and belongs to A/Q1"
      $unused=Invoke-ProbeRequest GET "/rest/v1/questionnaire_responses?id=eq.$id2&select=id" $service
      Check ($unused.Status -eq 200 -and @($unused.Data).Count -eq 0) "identity $field ID2 is unused"
      foreach($table in @('questionnaire_answers','questionnaire_results','questionnaire_response_contexts','patient_questionnaire_assignments','questionnaire_schema_activations')){
        $fk=if($table -eq 'questionnaire_schema_activations'){'questionnaire_response_id'}else{'response_id'}
        $deps=Invoke-ProbeRequest GET "/rest/v1/$($table)?$fk=eq.$id1&select=id" $service
        Check ($deps.Status -eq 200 -and @($deps.Data).Count -eq 0) "identity $field no dependencies in $table"
      }
      $body=switch($field){
        'patient_id' {@{patient_id=$patientB}}
        'questionnaire_id' {@{questionnaire_id=$q2.Data[0].id;questionnaire_version_id=$v2.Data[0].id}}
        'id' {@{id=$id2}}
      }
      $write=Invoke-ProbeRequest PATCH "/rest/v1/questionnaire_responses?id=eq.$id1&select=id" $service $body
      Check ($write.Status -eq 200 -and @($write.Data).Count -eq 1) "identity $field service_role ALLOW"
      $controlId=if($field -eq 'id'){$id2}else{$id1}
      $changed=Invoke-ProbeRequest GET "/rest/v1/questionnaire_responses?id=eq.$controlId&select=*" $service
      Check ($changed.Status -eq 200 -and @($changed.Data).Count -eq 1 -and $changed.Data[0].$field -eq $body[$field]) "identity $field privileged value actually persisted"
      if($field -eq 'questionnaire_id'){Check ($changed.Data[0].questionnaire_version_id -eq $v2.Data[0].id) 'identity questionnaire version changed coherently'}
      if($field -eq 'id'){
        $gone=Invoke-ProbeRequest GET "/rest/v1/questionnaire_responses?id=eq.$id1&select=id" $service
        Check ($gone.Status -eq 200 -and @($gone.Data).Count -eq 0) 'identity PK control removed ID1 and created ID2'
      }
      $restore=Invoke-ProbeRequest PATCH "/rest/v1/questionnaire_responses?id=eq.$controlId&select=id" $service @{id=$id1;patient_id=$patient;questionnaire_id=$q1.Data[0].id;questionnaire_version_id=$v1.Data[0].id}
      $before=Invoke-ProbeRequest GET "/rest/v1/questionnaire_responses?id=eq.$id1&select=*" $service
      Check ($restore.Status -eq 200 -and $before.Status -eq 200 -and @($before.Data).Count -eq 1 -and (($before.Data[0]|Select-Object * -ExcludeProperty updated_at|ConvertTo-Json -Depth 30 -Compress) -ceq ($original.Data[0]|Select-Object * -ExcludeProperty updated_at|ConvertTo-Json -Depth 30 -Compress))) "identity $field control restored exactly before patient attempt"
      $denied=Invoke-ProbeRequest PATCH "/rest/v1/questionnaire_responses?id=eq.$id1&select=id" $token $body
      Check ($denied.Status -eq 403 -and $denied.Data.code -eq '42501') "identity $field patient DENY 403/42501 for identical body"
      $after=Invoke-ProbeRequest GET "/rest/v1/questionnaire_responses?id=eq.$id1&select=*" $service
      Check ($after.Status -eq 200 -and @($after.Data).Count -eq 1 -and $after.Text -ceq $before.Text) "identity $field persisted patient state unchanged"
      $absent=Invoke-ProbeRequest GET "/rest/v1/questionnaire_responses?id=eq.$id2&select=id" $service
      Check ($absent.Status -eq 200 -and @($absent.Data).Count -eq 0) "identity $field ID2 absent after patient attempt"
      Write-Host "IDENTITY_PROOF field=$field service=200 persisted=$($changed.Data[0].$field) restored=$($before.Data[0].$field) patient=403/42501 after=$($after.Data[0].$field)"
    }
  } finally {
    $errors=[Collections.Generic.List[string]]::new()
    foreach($id in $responseIds){$r=Invoke-ProbeRequest DELETE "/rest/v1/questionnaire_responses?id=eq.$id" $service;if($r.Status -ne 200){$errors.Add("response $id")}}
    $r=Invoke-ProbeRequest DELETE "/rest/v1/patients?id=eq.$patientB" $service;if($r.Status -ne 200){$errors.Add('Patient B')}
    $r=Invoke-ProbeRequest DELETE "/auth/v1/admin/users/$userB" $service;if($r.Status -notin @(200,404)){$errors.Add('Auth B')}
    $ids=$entityIds -join ','
    $r=Invoke-ProbeRequest DELETE "/rest/v1/audit_events?entity_id=in.($ids)" $service;if($r.Status -ne 200){$errors.Add('fixture audit events')}
    foreach($table in @('questionnaire_responses','patients','profiles')){
      $remaining=Invoke-ProbeRequest GET "/rest/v1/$($table)?id=in.($ids)&select=id" $service
      if($remaining.Status -ne 200 -or @($remaining.Data).Count -ne 0){$errors.Add("remaining $table")}
    }
    $remaining=Invoke-ProbeRequest GET "/rest/v1/audit_events?entity_id=in.($ids)&select=id" $service
    if($remaining.Status -ne 200 -or @($remaining.Data).Count -ne 0){$errors.Add('remaining fixture audit events')}
    $remaining=Invoke-ProbeRequest GET "/auth/v1/admin/users/$userB" $service
    if($remaining.Status -ne 404){$errors.Add('remaining Auth B')}
    Check ($errors.Count -eq 0) "identity fixtures cleaned: zero Auth/profile/patient/response/audit rows ($($errors -join ', '))"
  }
}
function Login($email){
  $r=Invoke-ProbeRequest POST '/auth/v1/token?grant_type=password' $anon @{email=$email;password='TesteMVP2025!'}
  if($r.Status -ne 200){throw 'Fixture login failed'}
  $r.Data.access_token
}
$patient='11111111-1111-1111-1111-111111111201'
$response=[guid]::NewGuid().ToString()
$parentalResponse=$null; $parentalAssignment=$null; $createdAssignment=$false; $previousAssignmentResponse=$null
$old=Invoke-ProbeRequest GET "/rest/v1/patients?id=eq.$patient&select=results_released_at,results_released_by" $service
if($old.Status -ne 200 -or @($old.Data).Count -ne 1){throw 'Seed patient missing'}
$oldRelease=@{results_released_at=$old.Data[0].results_released_at;results_released_by=$old.Data[0].results_released_by}
try {
  $token=Login 'paciente.login@clinicateste-mvp.example'
  $psych=Login 'psicologo@clinicateste-mvp.example'
  $admin=Login 'admin@clinicateste-mvp.example'
  $reset=Invoke-ProbeRequest PATCH "/rest/v1/patients?id=eq.$patient" $service @{results_released_at=$null;results_released_by=$null}
  Check ($reset.Status -eq 200) 'fixture unreleased'
  $source=Invoke-ProbeRequest GET '/rest/v1/questionnaire_responses?id=eq.11111111-1111-1111-1111-111111111701&select=clinic_id,patient_id,questionnaire_id,questionnaire_version_id' $service
  Check ($source.Status -eq 200 -and @($source.Data).Count -eq 1 -and $source.Data[0].patient_id -eq $patient) 'seed response exists and belongs to patient'
  Test-ValidIdentityWrites $token $source.Data[0]
  $fixture=@{id=$response;clinic_id=$source.Data[0].clinic_id;patient_id=$patient;questionnaire_id=$source.Data[0].questionnaire_id;questionnaire_version_id=$source.Data[0].questionnaire_version_id;status='draft'}
  $created=Invoke-ProbeRequest POST '/rest/v1/questionnaire_responses' $service $fixture
  Check ($created.Status -eq 201 -and $created.Data[0].id -eq $response -and $created.Data[0].patient_id -eq $patient) 'draft fixture created and owned'
  $answers=Invoke-ProbeRequest GET '/rest/v1/questionnaire_answers?response_id=eq.11111111-1111-1111-1111-111111111701&select=question_id,answer_value' $service
  Check ($answers.Status -eq 200 -and @($answers.Data).Count -gt 0) 'seed answers exist'
  foreach($answer in $answers.Data){
    $saved=Invoke-ProbeRequest POST '/functions/v1/submit-questionnaire-answer' $token @{response_id=$response;question_id=$answer.question_id;answer_value=$answer.answer_value}
    Check ($saved.Status -eq 200 -and $saved.Data.ok) 'official save answer'
  }
  foreach($forgery in @(
    @{review_notes='PATIENT_FORGED_LOTE_F'}, @{reviewed_at='2099-01-01T00:00:00Z'},
    @{completed_at='2099-01-01T00:00:00Z'})){
    Assert-Unchanged "/rest/v1/questionnaire_responses?id=eq.$response" $token $forgery "draft response $(@($forgery.Keys)[0])"
  }
  $answerTarget=Invoke-ProbeRequest GET "/rest/v1/questionnaire_answers?response_id=eq.$response&select=id,response_id&limit=1" $service
  Check ($answerTarget.Status -eq 200 -and @($answerTarget.Data).Count -eq 1 -and $answerTarget.Data[0].response_id -eq $response) 'own draft answer exists'
  $answerId=$answerTarget.Data[0].id
  foreach($forgery in @(@{professional_note='PATIENT_FORGED_LOTE_F'},@{professional_value=999},@{response_id='11111111-1111-1111-1111-111111111701'})){
    Assert-Unchanged "/rest/v1/questionnaire_answers?id=eq.$answerId" $token $forgery "draft answer $(@($forgery.Keys)[0])"
  }
  $done=Invoke-ProbeRequest POST '/functions/v1/finish-questionnaire' $token @{response_id=$response}
  Check ($done.Status -eq 200 -and $done.Data.ok) 'finish HTTP operational success'
  # Exact shape at every level: aliases, nested clinical objects, and added fields fail.
  Check ((@($done.Data.PSObject.Properties.Name|Sort-Object) -join ',') -eq 'data,ok') 'finish envelope allowlist'
  Check ((@($done.Data.data.PSObject.Properties.Name) -join ',') -eq 'response') 'finish excludes all clinical payloads'
  Check ((@($done.Data.data.response.PSObject.Properties.Name|Sort-Object) -join ',') -eq 'completed_at,id,patient_id,questionnaire_id,status') 'finish operational response allowlist'
  Check ($done.Data.data.response.id -eq $response -and $done.Data.data.response.status -eq 'completed') 'finish response identity and status'
  Check ($done.Text -notmatch '(?i)score|snapshot|results|interpretation|activation|professional|review_notes') 'finish recursive clinical-key exclusion'
  Assert-Unchanged "/rest/v1/questionnaire_responses?id=eq.$response" $token @{status='draft';completed_at=$null} 'completed response cannot reopen'
  Assert-Unchanged "/rest/v1/questionnaire_answers?id=eq.$answerId" $token @{answer_value=1} 'completed answer immutable'
  $storedResults=Invoke-ProbeRequest GET "/rest/v1/questionnaire_results?response_id=eq.$response&select=id,response_id" $service
  Check ($storedResults.Status -eq 200 -and @($storedResults.Data).Count -eq 2) 'computed result fixtures exist before negative reads'
  $activation=Invoke-ProbeRequest POST '/rest/v1/questionnaire_schema_activations' $psych @{questionnaire_response_id=$response;schema_code='LOTE_F';schema_name='Shared';psi_observation='PRIVATE_PSI_OBSERVATION_LOTE_F'}
  Check ($activation.Status -eq 201) 'responsible psychologist activation write'
  $privateFixture=Invoke-ProbeRequest GET "/rest/v1/questionnaire_schema_activations?questionnaire_response_id=eq.$response&select=psi_observation,questionnaire_response_id" $service
  Check ($privateFixture.Status -eq 200 -and @($privateFixture.Data).Count -eq 1 -and $privateFixture.Data[0].psi_observation -ceq 'PRIVATE_PSI_OBSERVATION_LOTE_F' -and $privateFixture.Data[0].questionnaire_response_id -eq $response) 'private sentinel exists on own response before reads'
  foreach($released in @($false,$true)){
    $review=Invoke-ProbeRequest PATCH "/rest/v1/questionnaire_responses?id=eq.$response&select=id" $psych @{reviewed_at=[DateTime]::UtcNow.ToString('o');review_notes='PRIVATE_REVIEW'}
    Check ($review.Status -eq 200) 'responsible psychologist review write'
    if($released){
      $release=Invoke-ProbeRequest POST '/rest/v1/rpc/set_patient_results_released' $psych @{p_patient_id=$patient;p_released=$true}
      Check ($release.Status -eq 200) 'official release RPC'
    }
    foreach($probe in @(
      'questionnaire_schema_activations?select=*',
      'questionnaire_schema_activations?select=psi_observation',
      'questionnaire_responses?select=review_notes',
      'questionnaire_responses?select=*',
      'questionnaire_answers?select=professional_note,professional_value',
      'questionnaire_answers?select=*',
      'questionnaire_results?select=snapshot,total_score,professional_note',
      'questionnaire_results?select=*',
      'questionnaire_schema_activations?select=id,psi_observation&psi_observation=not.is.null&order=psi_observation',
      'questionnaire_answers?select=id&order=professional_value',
      'questionnaire_responses?select=id&review_notes=not.is.null&order=review_notes')){
      $raw=Invoke-ProbeRequest GET "/rest/v1/$probe" $token
      $columnProtected=$probe -match '^questionnaire_(answers|responses)\?'
      $expected=if($columnProtected){$raw.Status -eq 403 -and $raw.Data.code -eq '42501'}else{$raw.Status -eq 200 -and $raw.Text -eq '[]'}
      Check $expected "REST authorization confirmed released=$released $probe"
      Check ($raw.Text -notmatch 'PRIVATE_PSI_OBSERVATION_LOTE_F') "REST sentinel absent released=$released $probe"
    }
    $detail=Invoke-ProbeRequest POST '/rest/v1/rpc/get_questionnaire_response_detail' $token @{p_response_id=$response}
    Check ($detail.Status -eq 200 -and $detail.Data.id -eq $response) 'patient operational detail'
    Check ($detail.Text -notmatch 'PRIVATE|professional_|psi_observation|review_notes|"snapshot"') 'patient safe projection private fields absent'
    Check (@($detail.Data.questionnaire_results).Count -eq $(if($released){2}else{0})) "result gate released=$released"
    $shared=Invoke-ProbeRequest POST '/rest/v1/rpc/get_patient_schema_activations' $token @{p_response_id=$response}
    Check ($shared.Status -eq 200 -and @($shared.Data).Count -eq $(if($released){1}else{0})) "activation gate released=$released"
    if($released){Check ((@($shared.Data[0].PSObject.Properties.Name|Sort-Object)-join ',') -eq 'created_at,id,questionnaire_response_id,schema_code,schema_name') 'activation exact allowlist'}
  }
  foreach($deniedToken in @($anon,$admin)){
    $r=Invoke-ProbeRequest POST '/rest/v1/rpc/get_questionnaire_response_detail' $deniedToken @{p_response_id=$response}
    $expected=if($deniedToken -eq $anon){$r.Status -eq 401 -and $r.Data.code -eq '42501'}else{$r.Status -eq 200 -and $null -eq $r.Data}
    Check $expected 'anonymous/admin clinical detail denied coherently'
  }
  $staff=Invoke-ProbeRequest POST '/rest/v1/rpc/get_questionnaire_response_detail' $psych @{p_response_id=$response}
  Check ($staff.Status -eq 200 -and $staff.Data.review_notes -eq 'PRIVATE_REVIEW' -and $staff.Text -match '"snapshot"') 'responsible professional projection preserved'
  # Exercise the second completion branch and the official patient start path.
  $q=Invoke-ProbeRequest GET '/rest/v1/questionnaires?code=eq.PARENTAL_STYLES_V1&select=id' $service
  Check ($q.Status -eq 200 -and @($q.Data).Count -eq 1) 'parental questionnaire exists'
  $qid=$q.Data[0].id
  $assigned=Invoke-ProbeRequest GET "/rest/v1/patient_questionnaire_assignments?patient_id=eq.$patient&questionnaire_id=eq.$qid&cancelled_at=is.null&select=id,response_id" $service
  if(@($assigned.Data).Count -eq 0){
    $a=Invoke-ProbeRequest POST '/rest/v1/patient_questionnaire_assignments' $psych @{patient_id=$patient;questionnaire_id=$qid;clinic_id=$source.Data[0].clinic_id;assigned_by_profile_id='11111111-1111-1111-1111-111111111103'}
    Check ($a.Status -eq 201) 'responsible assignment created'
    $parentalAssignment=$a.Data[0].id; $createdAssignment=$true
  } else {$parentalAssignment=$assigned.Data[0].id;$previousAssignmentResponse=$assigned.Data[0].response_id}
  $reset=Invoke-ProbeRequest PATCH "/rest/v1/patients?id=eq.$patient" $service @{results_released_at=$null;results_released_by=$null}
  $start=Invoke-ProbeRequest POST '/functions/v1/start-questionnaire' $token @{patient_id=$patient;questionnaire_id=$qid;assignment_id=$parentalAssignment;contexts=@(@{key='mother';label='Mãe'})}
  $parentalResponse=$start.Data.data.response.id
  Check ($start.Status -eq 200 -and $parentalResponse) 'official patient start with assignment and parental context'
  $context=$start.Data.data.contexts[0].id
  $contextFixture=Invoke-ProbeRequest GET "/rest/v1/questionnaire_response_contexts?id=eq.$context&select=*" $service
  Check ($contextFixture.Status -eq 200 -and @($contextFixture.Data).Count -eq 1 -and $contextFixture.Data[0].response_id -eq $parentalResponse -and $contextFixture.Data[0].patient_id -eq $patient -and $contextFixture.Data[0].questionnaire_id -eq $qid) 'parental context exists with correct ownership and instrument'
  Assert-Unchanged "/rest/v1/questionnaire_response_contexts?id=eq.$context" $token @{completed_at='2099-01-01T00:00:00Z'} 'draft context cannot set timestamp' $true
  foreach($question in $start.Data.data.questions){
    $saved=Invoke-ProbeRequest POST '/functions/v1/submit-questionnaire-answer' $token @{response_id=$parentalResponse;question_id=$question.id;response_context_id=$context;answer_value=($question.scale_min+1)}
    Check ($saved.Status -eq 200) 'official parental answer and context completion'
  }
  Assert-Unchanged "/rest/v1/questionnaire_response_contexts?id=eq.$context" $token @{status='draft';completed_at=$null} 'completed context cannot cycle status before finish'
  Assert-Unchanged "/rest/v1/questionnaire_response_contexts?id=eq.$context" $token @{completed_at='2099-01-01T00:00:00Z'} 'completed context timestamp before finish' $true
  # Legitimate draft-parent progress can still become incomplete and complete again.
  $firstAnswer=Invoke-ProbeRequest GET "/rest/v1/questionnaire_answers?response_context_id=eq.$context&select=id,question_id,answer_value&limit=1" $service
  Check ($firstAnswer.Status -eq 200 -and @($firstAnswer.Data).Count -eq 1) 'parental answer exists for progress edit'
  $cleared=Invoke-ProbeRequest PATCH "/rest/v1/questionnaire_answers?id=eq.$($firstAnswer.Data[0].id)&select=id" $token @{answer_value=$null}
  $progress=Invoke-ProbeRequest GET "/rest/v1/questionnaire_response_contexts?id=eq.$context&select=status,completed_at" $service
  Check ($cleared.Status -eq 200 -and $progress.Status -eq 200 -and $progress.Data[0].status -eq 'draft' -and $null -eq $progress.Data[0].completed_at) 'legitimate incomplete answer progress clears workflow timestamp'
  $saved=Invoke-ProbeRequest POST '/functions/v1/submit-questionnaire-answer' $token @{response_id=$parentalResponse;question_id=$firstAnswer.Data[0].question_id;response_context_id=$context;answer_value=$firstAnswer.Data[0].answer_value}
  Check ($saved.Status -eq 200 -and $saved.Data.ok) 'official resave restores completed progress'
  $synced=Invoke-ProbeRequest GET "/rest/v1/questionnaire_response_contexts?id=eq.$context&select=status,completed_at" $service
  Check ($synced.Status -eq 200 -and @($synced.Data).Count -eq 1 -and $synced.Data[0].status -eq 'completed' -and $synced.Data[0].completed_at) 'answer synchronization establishes completion timestamp'
  $done=Invoke-ProbeRequest POST '/functions/v1/finish-questionnaire' $token @{response_id=$parentalResponse}
  Check ($done.Status -eq 200 -and $done.Data.ok) 'parental finish HTTP operational success'
  Check ((@($done.Data.PSObject.Properties.Name|Sort-Object)-join ',') -eq 'data,ok') 'parental envelope allowlist'
  Check ((@($done.Data.data.response.PSObject.Properties.Name|Sort-Object)-join ',') -eq 'completed_at,id,patient_id,questionnaire_id,status') 'parental exact operational response allowlist'
  Check ($done.Data.data.response.id -eq $parentalResponse -and $done.Data.data.response.patient_id -eq $patient -and $done.Data.data.response.questionnaire_id -eq $qid -and $done.Data.data.response.status -eq 'completed') 'parental response identity and completed status'
  Check ((@($done.Data.data.PSObject.Properties.Name)-join ',') -eq 'response' -and $done.Text -notmatch '(?i)score|snapshot|results|interpretation|activation|professional') 'parental finish excludes clinical payload recursively'
  $completed=Invoke-ProbeRequest GET "/rest/v1/questionnaire_response_contexts?id=eq.$context&select=status,completed_at" $service
  Check ($completed.Status -eq 200 -and @($completed.Data).Count -eq 1 -and $completed.Data[0].status -eq 'completed' -and $completed.Data[0].completed_at) 'official completion stored timestamp exists'
  Check (($completed.Data[0].completed_at|ConvertTo-Json -Compress) -ceq ($synced.Data[0].completed_at|ConvertTo-Json -Compress)) 'official finish preserves synchronized context timestamp'
  foreach($forgery in @(@{completed_at='2099-01-01T00:00:00Z'},@{completed_at='2001-02-03T04:05:06Z'},@{completed_at=$null},@{status='completed';completed_at='2099-01-01T00:00:00Z'})){
    Assert-Unchanged "/rest/v1/questionnaire_response_contexts?id=eq.$context" $token $forgery 'completed context timestamp forgery' $true
  }
  Assert-Unchanged "/rest/v1/questionnaire_response_contexts?id=eq.$context" $token @{status='draft';completed_at=$null} 'parental finalized context cannot reopen'
  Write-Host "Lote F HTTP: $script:checks checks passed"
} finally {
  if($parentalResponse){$cleanup=Invoke-ProbeRequest DELETE "/rest/v1/questionnaire_responses?id=eq.$parentalResponse" $service;if($cleanup.Status -ge 400){throw 'Parental fixture cleanup failed'}}
  if($parentalAssignment){
    $cleanup=if($createdAssignment){Invoke-ProbeRequest DELETE "/rest/v1/patient_questionnaire_assignments?id=eq.$parentalAssignment" $service}else{Invoke-ProbeRequest PATCH "/rest/v1/patient_questionnaire_assignments?id=eq.$parentalAssignment" $service @{response_id=$previousAssignmentResponse}}
    if($cleanup.Status -ge 400){throw 'Assignment fixture cleanup failed'}
  }
  $deleted=Invoke-ProbeRequest DELETE "/rest/v1/questionnaire_responses?id=eq.$response" $service
  $restored=Invoke-ProbeRequest PATCH "/rest/v1/patients?id=eq.$patient" $service $oldRelease
  if($deleted.Status -ge 400 -or $restored.Status -ge 400){throw 'Fixture cleanup failed'}
}
