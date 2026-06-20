param(
  [string]$Alias = 'upload',
  [string]$DistinguishedName = 'CN=EsquemaCore, OU=Mobile, O=EsquemaCore, L=Sao Paulo, ST=SP, C=BR'
)

$ErrorActionPreference = 'Stop'

$mobileDir = Split-Path -Parent $PSScriptRoot
$keystoreDir = Join-Path $mobileDir 'android\keystore'
$keystorePath = Join-Path $keystoreDir 'esquemacore-upload.jks'
$propertiesPath = Join-Path $mobileDir 'android\key.properties'

if ((Test-Path $keystorePath) -or (Test-Path $propertiesPath)) {
  throw 'A assinatura Android já está configurada. Remova os arquivos manualmente somente se deseja substituir a chave.'
}

$javaHomeKeytool = if ($env:JAVA_HOME) {
  Join-Path $env:JAVA_HOME 'bin\keytool.exe'
} else {
  $null
}

$keytoolCandidates = @(
  @(
    $javaHomeKeytool,
    'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe',
    'C:\Program Files\Android\Android Studio\jre\bin\keytool.exe'
  ) | Where-Object { $_ -and (Test-Path $_) }
)

if ($keytoolCandidates.Count -eq 0) {
  throw 'keytool não encontrado. Instale o Android Studio/JDK ou configure JAVA_HOME.'
}
$keytool = $keytoolCandidates[0]

$passwordBytes = New-Object byte[] 24
$random = [Security.Cryptography.RandomNumberGenerator]::Create()
$random.GetBytes($passwordBytes)
$random.Dispose()
$password = [Convert]::ToBase64String($passwordBytes).TrimEnd('=')

New-Item -ItemType Directory -Path $keystoreDir -Force | Out-Null

& $keytool `
  -genkeypair `
  -v `
  -keystore $keystorePath `
  -storepass $password `
  -keypass $password `
  -alias $Alias `
  -keyalg RSA `
  -keysize 4096 `
  -validity 10000 `
  -dname $DistinguishedName

if ($LASTEXITCODE -ne 0) {
  throw "keytool falhou com código $LASTEXITCODE."
}

@(
  "storePassword=$password"
  "keyPassword=$password"
  "keyAlias=$Alias"
  'storeFile=../keystore/esquemacore-upload.jks'
) | Set-Content -Path $propertiesPath -Encoding ASCII

Write-Host 'Keystore de upload criado com sucesso.'
Write-Host 'Faça backup seguro destes dois arquivos:'
Write-Host "  $keystorePath"
Write-Host "  $propertiesPath"
