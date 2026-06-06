#!/usr/bin/env bash
# Valida Supabase remoto usando mobile/env.local.json
# Uso:
#   ./scripts/validate-remote-supabase.sh          # smoke básico
#   ./scripts/validate-remote-supabase.sh --full   # inclui probe create-patient

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT/mobile/env.local.json}"
FULL=false

for arg in "$@"; do
  case "$arg" in
    --full) FULL=true ;;
    -h|--help)
      echo "Uso: $0 [--full]"
      exit 0
      ;;
  esac
done

if [[ ! -f "$ENV_FILE" ]]; then
  echo "ERRO: $ENV_FILE não encontrado."
  exit 1
fi

URL=$(python3 -c "import json; print(json.load(open('$ENV_FILE'))['SUPABASE_URL'])")
KEY=$(python3 -c "import json; print(json.load(open('$ENV_FILE'))['SUPABASE_ANON_KEY'])")

PASS=0
FAIL=0

ok() { echo "  OK  $1"; PASS=$((PASS + 1)); }
bad() { echo "  FAIL $1"; FAIL=$((FAIL + 1)); }

echo "=== Validação Supabase remoto ==="
echo "URL: $URL"
echo "Env: $ENV_FILE"
echo

echo "--- Auth health ---"
HEALTH=$(curl -s -w "\n%{http_code}" "$URL/auth/v1/health" -H "apikey: $KEY")
CODE=$(echo "$HEALTH" | tail -1)
if [[ "$CODE" == "200" ]]; then ok "Auth health ($CODE)"; else bad "Auth health ($CODE)"; fi

echo "--- Login admin ---"
AUTH_RESP=$(curl -s -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d '{"email":"admin@clinicateste-mvp.example","password":"TesteMVP2025!"}')

TOKEN=$(echo "$AUTH_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || true)

if [[ -n "$TOKEN" ]]; then
  ok "Login admin (JWT obtido)"
else
  MSG=$(echo "$AUTH_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('msg') or d.get('error_description') or d)" 2>/dev/null || echo "$AUTH_RESP")
  bad "Login admin: $MSG"
fi

echo "--- Login psicólogo ---"
AUTH_PSY=$(curl -s -X POST "$URL/auth/v1/token?grant_type=password" \
  -H "apikey: $KEY" -H "Content-Type: application/json" \
  -d '{"email":"psicologo@clinicateste-mvp.example","password":"TesteMVP2025!"}')
TOKEN_PSY=$(echo "$AUTH_PSY" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null || true)
if [[ -n "$TOKEN_PSY" ]]; then ok "Login psicólogo"; else bad "Login psicólogo"; fi

if [[ -n "$TOKEN" ]]; then
  echo "--- Profile (RLS) ---"
  PROF=$(curl -s -H "apikey: $KEY" -H "Authorization: Bearer $TOKEN" \
    "$URL/rest/v1/profiles?select=id,role,email&limit=1")
  if echo "$PROF" | python3 -c "import sys,json; d=json.load(sys.stdin); exit(0 if isinstance(d,list) and len(d)>0 else 1)" 2>/dev/null; then
    ok "Profile admin legível"
  else
    bad "Profile admin: $PROF"
  fi

  echo "--- Patients (admin) ---"
  PAT=$(curl -s -H "apikey: $KEY" -H "Authorization: Bearer $TOKEN" \
    "$URL/rest/v1/patients?select=id&limit=5")
  if echo "$PAT" | python3 -c "import sys,json; json.load(sys.stdin); exit(0)" 2>/dev/null; then
    COUNT=$(echo "$PAT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if isinstance(d,list) else 0)")
    ok "Patients listável ($COUNT registros)"
  else
    bad "Patients: $PAT"
  fi
fi

echo "--- Edge Functions (CORS preflight) ---"
for fn in create-patient start-questionnaire submit-questionnaire-answer finish-questionnaire; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X OPTIONS "$URL/functions/v1/$fn" -H "apikey: $KEY")
  if [[ "$CODE" == "204" || "$CODE" == "200" ]]; then
    ok "Edge $fn (OPTIONS $CODE)"
  else
    bad "Edge $fn (OPTIONS $CODE)"
  fi
done

if $FULL && [[ -n "$TOKEN_PSY" ]]; then
  echo "--- create-patient (psychologist, probe) ---"
  UNIQUE="probe.$(date +%s)@clinicateste-mvp.example"
  BODY=$(python3 -c "import json; print(json.dumps({
    'email': '$UNIQUE',
    'password': 'TesteMVP2025!',
    'full_name': 'Probe Validação',
    'responsible_psychologist_id': '11111111-1111-1111-1111-111111111103',
  }))")
  CP_CODE=$(curl -s -o /tmp/cp_resp.json -w "%{http_code}" -X POST "$URL/functions/v1/create-patient" \
    -H "apikey: $KEY" -H "Authorization: Bearer $TOKEN_PSY" \
    -H "Content-Type: application/json" -d "$BODY")
  if [[ "$CP_CODE" == "200" || "$CP_CODE" == "201" ]]; then
    ok "create-patient ($CP_CODE)"
  else
    bad "create-patient ($CP_CODE): $(head -c 200 /tmp/cp_resp.json)"
  fi
fi

echo
echo "=== Resumo: $PASS OK, $FAIL FAIL ==="
if [[ "$FAIL" -gt 0 ]]; then
  echo "Corrija com: docs/supabase-remote-fix-checklist.md"
  exit 1
fi
echo "Backend remoto pronto para testar o app Flutter."
exit 0
