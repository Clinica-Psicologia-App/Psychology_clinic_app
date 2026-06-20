$ErrorActionPreference = 'Stop'

$mobileDir = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $mobileDir 'env.production.json'
$keyProperties = Join-Path $mobileDir 'android\key.properties'

if (-not (Test-Path $envFile)) {
  throw 'Crie env.production.json a partir de env.production.example.json e informe a chave publicável real.'
}
if (-not (Test-Path $keyProperties)) {
  throw 'Execute scripts\create-android-keystore.ps1 antes do build release.'
}

$config = Get-Content -Raw $envFile | ConvertFrom-Json
if ($config.SUPABASE_URL -notmatch '^https://[^/]+\.supabase\.co/?$') {
  throw 'SUPABASE_URL de produção deve apontar para um projeto Supabase HTTPS.'
}
if (
  [string]::IsNullOrWhiteSpace($config.SUPABASE_ANON_KEY) -or
  $config.SUPABASE_ANON_KEY -like '*SUBSTITUA*' -or
  $config.SUPABASE_ANON_KEY -like '*placeholder*'
) {
  throw 'SUPABASE_ANON_KEY de produção não foi configurada.'
}

if (-not $env:ANDROID_HOME) {
  $localProperties = Join-Path $mobileDir 'android\local.properties'
  $sdkLine = Get-Content $localProperties | Where-Object { $_ -like 'sdk.dir=*' }
  if ($sdkLine) {
    $env:ANDROID_HOME = ($sdkLine -replace '^sdk.dir=', '') -replace '\\\\', '\'
    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
  }
}

Push-Location $mobileDir
try {
  flutter build appbundle `
    --release `
    --dart-define-from-file=env.production.json `
    --dart-define=SHOW_TEST_ACCOUNTS=false
  if ($LASTEXITCODE -ne 0) {
    throw "Build release falhou com código $LASTEXITCODE."
  }
} finally {
  Pop-Location
}
