# Smoke test das Edge Functions (local)
# Uso: .\supabase\tests\edge-functions-flow.ps1

$ErrorActionPreference = "Stop"
$Base = "http://127.0.0.1:54321"
$AnonKey = (supabase status -o json | ConvertFrom-Json).ANON_KEY

function Get-Token($email, $password) {
  $body = @{ email = $email; password = $password } | ConvertTo-Json
  $r = Invoke-RestMethod -Method Post -Uri "$Base/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $AnonKey; "Content-Type" = "application/json" } -Body $body
  return $r.access_token
}

function Invoke-Function($name, $token, $payload) {
  $json = $payload | ConvertTo-Json -Depth 10
  return Invoke-RestMethod -Method Post -Uri "$Base/functions/v1/$name" `
    -Headers @{
      Authorization = "Bearer $token"
      apikey        = $AnonKey
      "Content-Type" = "application/json"
    } -Body $json
}

Write-Host "=== Edge Functions flow test ===" -ForegroundColor Cyan

$psychToken = Get-Token "psicologo@clinicateste-mvp.example" "TesteMVP2025!"
$patientToken = Get-Token "paciente.login@clinicateste-mvp.example" "TesteMVP2025!"

$patientId = "11111111-1111-1111-1111-111111111201"
$questionnaireId = "11111111-1111-1111-1111-111111111301"
$psychId = "11111111-1111-1111-1111-111111111103"

Write-Host "[1] create-patient (psychologist)..." -ForegroundColor Yellow
$newEmail = "fluxo.paciente.{0}@clinicateste-mvp.example" -f (Get-Random -Maximum 99999)
$created = Invoke-Function "create-patient" $psychToken @{
  email = $newEmail
  password = "TesteMVP2025!"
  full_name = "Paciente Fluxo EF"
  responsible_psychologist_id = $psychId
}
Write-Host "    OK patient_id=$($created.data.patient.id)" -ForegroundColor Green

Write-Host "[2] start-questionnaire (patient seed)..." -ForegroundColor Yellow
$started = Invoke-Function "start-questionnaire" $patientToken @{
  patient_id = $patientId
  questionnaire_id = $questionnaireId
}
$responseId = $started.data.response.id
$questions = $started.data.questions
Write-Host "    OK response_id=$responseId questions=$($questions.Count)" -ForegroundColor Green

Write-Host "[3] submit-questionnaire-answer x$($questions.Count)..." -ForegroundColor Yellow
foreach ($q in $questions) {
  Invoke-Function "submit-questionnaire-answer" $patientToken @{
    response_id = $responseId
    question_id = $q.id
    answer_value = 4
  } | Out-Null
}
Write-Host "    OK all answers submitted" -ForegroundColor Green

Write-Host "[4] finish-questionnaire..." -ForegroundColor Yellow
$finished = Invoke-Function "finish-questionnaire" $patientToken @{
  response_id = $responseId
}
Write-Host "    OK status=$($finished.data.response.status) results=$($finished.data.results.Count)" -ForegroundColor Green

Write-Host "[5] blocked: submit after completed..." -ForegroundColor Yellow
try {
  Invoke-Function "submit-questionnaire-answer" $patientToken @{
    response_id = $responseId
    question_id = $questions[0].id
    answer_value = 1
  } | Out-Null
  Write-Host "    FAIL expected error" -ForegroundColor Red
  exit 1
} catch {
  Write-Host "    OK blocked ($($_.Exception.Message))" -ForegroundColor Green
}

Write-Host "=== All tests passed ===" -ForegroundColor Cyan
