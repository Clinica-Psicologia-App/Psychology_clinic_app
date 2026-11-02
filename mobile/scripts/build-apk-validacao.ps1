# Gera o APK de validação (Luciana e Guacira) sempre do mesmo jeito.
#
# - Usa env.production.json e assinatura release (android\key.properties), para
#   que todo APK entregue seja do mesmo tipo e possa ser instalado por cima.
# - Grava a versão do pubspec e a data do build dentro do app (tela de perfil).
# - Copia o arquivo para build\validacao\ com a versão no nome.
#
# Antes de cada entrega, suba o número em pubspec.yaml (version: X.Y.Z+N). O
# número depois do "+" precisa ser maior que o do APK anterior.
$ErrorActionPreference = 'Stop'

$mobileDir = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $mobileDir 'env.production.json'
$keyProperties = Join-Path $mobileDir 'android\key.properties'

if (-not (Test-Path $envFile)) {
  throw 'Crie env.production.json a partir de env.production.example.json.'
}
if (-not (Test-Path $keyProperties)) {
  throw 'Execute scripts\create-android-keystore.ps1 antes do build release.'
}

$config = Get-Content -Raw $envFile | ConvertFrom-Json
if ($config.SUPABASE_URL -notmatch '^https://[^/]+\.supabase\.co/?$') {
  throw 'SUPABASE_URL deve apontar para um projeto Supabase HTTPS.'
}

$pubspec = Get-Content -Raw (Join-Path $mobileDir 'pubspec.yaml')
if ($pubspec -notmatch '(?m)^version:\s*(\S+)\s*$') {
  throw 'Não encontrei "version:" no pubspec.yaml.'
}
$version = $Matches[1]
$buildDate = Get-Date -Format 'dd/MM/yyyy HH:mm'
$stamp = Get-Date -Format 'yyyyMMdd-HHmm'

Push-Location $mobileDir
try {
  flutter build apk `
    --release `
    --dart-define-from-file=env.production.json `
    --dart-define=SHOW_TEST_ACCOUNTS=false `
    --dart-define="APP_VERSION=$version" `
    --dart-define="APP_BUILD_DATE=$buildDate"
  if ($LASTEXITCODE -ne 0) {
    throw "Build falhou com código $LASTEXITCODE."
  }

  $outDir = Join-Path $mobileDir 'build\validacao'
  New-Item -ItemType Directory -Force $outDir | Out-Null
  $name = "EsquemaCore-$($version.Replace('+','-b'))-$stamp.apk"
  Copy-Item 'build\app\outputs\flutter-apk\app-release.apk' (Join-Path $outDir $name)
  Write-Host "APK de validação: build\validacao\$name"
  Write-Host "Versão no app: $version · build $buildDate"
} finally {
  Pop-Location
}
