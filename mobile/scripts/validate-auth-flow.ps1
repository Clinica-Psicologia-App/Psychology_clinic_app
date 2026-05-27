# Valida o mesmo fluxo que o app Flutter (login + profile.role)
# Uso: .\mobile\scripts\validate-auth-flow.ps1

$ErrorActionPreference = "Stop"
$Base = "http://127.0.0.1:54321"
$s = supabase status -o json | ConvertFrom-Json

$accounts = @(
  @{ Role = "admin"; Email = "admin@clinicateste-mvp.example"; Expected = "admin" },
  @{ Role = "psychologist"; Email = "psicologo@clinicateste-mvp.example"; Expected = "psychologist" },
  @{ Role = "patient"; Email = "paciente.login@clinicateste-mvp.example"; Expected = "patient" }
)

Write-Host "=== Auth flow (Flutter parity) ===" -ForegroundColor Cyan

foreach ($a in $accounts) {
  $body = @{ email = $a.Email; password = "TesteMVP2025!" } | ConvertTo-Json
  $tok = Invoke-RestMethod -Method Post -Uri "$Base/auth/v1/token?grant_type=password" `
    -Headers @{ apikey = $s.ANON_KEY } -ContentType "application/json" -Body $body

  $prof = Invoke-RestMethod -Uri "$Base/rest/v1/profiles?id=eq.$($tok.user.id)&select=role,full_name" `
    -Headers @{ apikey = $s.ANON_KEY; Authorization = "Bearer $($tok.access_token)" }

  $role = $prof[0].role
  if ($role -ne $a.Expected) { throw "Role mismatch for $($a.Email): got $role" }
  Write-Host "[OK] $($a.Role) -> /$role ($($prof[0].full_name))" -ForegroundColor Green
}

Write-Host "=== All roles validated ===" -ForegroundColor Cyan
