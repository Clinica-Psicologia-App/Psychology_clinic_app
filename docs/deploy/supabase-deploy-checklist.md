# Checklist de deploy — Supabase (MVP)

Use antes de homologação remota, staging ou demo com cliente **fora da máquina local**.

**Homologação completa:** [final-mvp-homologation.md](../demo/final-mvp-homologation.md)

---

## Pré-requisitos

- [ ] Conta Supabase com projeto criado (dev/staging)
- [ ] [Supabase CLI](https://supabase.com/docs/guides/cli) instalada e autenticada: `supabase login`
- [ ] Repositório clonado na versão/tag acordada para homologação
- [ ] Acesso ao Dashboard do projeto (owner ou admin)

---

## 1. Vincular projeto

```bash
cd /caminho/para/Aplicativo-Clinica-Psicologia
supabase link --project-ref <PROJECT_REF>
```

- [ ] `supabase projects list` mostra o projeto correto
- [ ] `.git/config` ou pasta `.supabase` aponta para o ref esperado

---

## 2. Banco de dados (`db push`)

```bash
supabase db push
```

- [ ] Migrations 001–021 aplicadas sem erro
- [ ] Table Editor: tabelas `therapy_goals`, `patient_problems`, `patient_check_ins`, `patient_timeline_events`, `genogram_*` presentes
- [ ] RLS habilitado nas tabelas sensíveis (ícone cadeado)

### Seed demo (homologação)

```bash
supabase db query --linked -f supabase/seed.sql
```

- [ ] 3 profiles + 1 paciente Maria Silva
- [ ] Questionário `MVP_DEMO` + resposta concluída
- [ ] YSQ/YAMI via migrations 014–015 (não duplicar manualmente)

**Produção real:** substituir ou complementar seed por dados controlados; **não** usar senha demo em produção.

---

## 3. Edge Functions (`functions deploy`)

Deploy **individual** (recomendado para controle) ou todas:

```bash
supabase functions deploy create-patient
supabase functions deploy start-questionnaire
supabase functions deploy submit-questionnaire-answer
supabase functions deploy finish-questionnaire
supabase functions deploy generate-clinical-report
```

Ou, se o projeto suportar deploy em lote:

```bash
supabase functions deploy
```

- [ ] Dashboard → **Edge Functions** lista as 5 funções
- [ ] Logs acessíveis (Functions → Logs)

### Variáveis de ambiente (automáticas no Supabase)

As funções usam (injetadas pelo runtime):

| Variável | Onde fica |
|----------|-----------|
| `SUPABASE_URL` | Plataforma |
| `SUPABASE_ANON_KEY` | Plataforma |
| `SUPABASE_SERVICE_ROLE_KEY` | Plataforma (**nunca no Flutter**) |

- [ ] **Não** commitar `service_role` no repositório
- [ ] **Não** colocar `service_role` em `env.local.json` do mobile

---

## 4. Validação de ambiente

### 4.1 Auth

- [ ] Dashboard → Authentication → Providers → Email habilitado
- [ ] Login com `admin@clinicateste-mvp.example` / `TesteMVP2025!` (após seed)

### 4.2 API URL e chaves

Dashboard → **Project Settings → API**:

| Campo | Uso |
|-------|-----|
| Project URL | `SUPABASE_URL` no Flutter |
| `anon` `public` | `SUPABASE_ANON_KEY` no Flutter |

- [ ] Copiar URL e anon key para `mobile/env.local.json` ou `env.production.json`
- [ ] **Nunca** usar `service_role` no app

Exemplo Flutter (gitignored):

```json
{
  "SUPABASE_URL": "https://<PROJECT_REF>.supabase.co",
  "SUPABASE_ANON_KEY": "<anon_public_key>"
}
```

### 4.3 Smoke REST (opcional)

```bash
# Health — substituir URL e anon key
curl -s -o /dev/null -w "%{http_code}" \
  "https://<PROJECT_REF>.supabase.co/rest/v1/clinics?select=id&limit=1" \
  -H "apikey: <ANON_KEY>" \
  -H "Authorization: Bearer <JWT_PACIENTE>"
```

Esperado: `200` com JWT válido; `401`/`403` sem token.

---

## 5. Teste das Edge Functions

### 5.1 Questionário (fluxo mínimo)

Com `supabase functions serve` local **ou** remoto + JWT staff/paciente:

- [ ] `start-questionnaire` → retorna perguntas
- [ ] `submit-questionnaire-answer` → persiste resposta
- [ ] `finish-questionnaire` → snapshot em `questionnaire_results`

Script opcional: `supabase/tests/edge-functions-flow.ps1`

### 5.2 Cadastro paciente (staff)

- [ ] `create-patient` com JWT psicólogo/admin → paciente + auth user

### 5.3 Geração de PDF (**obrigatório na homologação final**)

1. Login app como **psicólogo** ou **admin**
2. Paciente Maria Silva → **Gerar relatório**
3. Gerar PDF com seções default

- [ ] PDF abre ou salva sem erro HTTP 4xx/5xx
- [ ] Conteúdo: capa + aviso clínico + rodapé `CLINICAL_REPORT_V1`

Alternativa curl (staff JWT):

```bash
curl -X POST "https://<PROJECT_REF>.supabase.co/functions/v1/generate-clinical-report" \
  -H "Authorization: Bearer <STAFF_JWT>" \
  -H "apikey: <ANON_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"11111111-1111-1111-1111-111111111201"}' \
  --output relatorio-teste.pdf
```

- [ ] Arquivo `relatorio-teste.pdf` válido (header `%PDF`)

---

## 6. Segurança pós-deploy

- [ ] RLS ativo em todas as tabelas de dados clínicos
- [ ] Políticas `user_can_access_patient` testadas (ver [post-roadmap-stabilization.md](../qa/post-roadmap-stabilization.md))
- [ ] CORS / JWT: funções exigem `Authorization: Bearer`
- [ ] Backups / PITR conforme política do cliente (Dashboard → Database)

---

## 7. Rollback / problemas

| Sintoma | Ação |
|---------|------|
| Migration falha no push | Corrigir SQL local; **não** editar migration já aplicada em prod — nova migration |
| Login 500 | Verificar seed auth; migration `011` (tokens NULL) |
| Function 401 | JWT expirado ou anon key errada no app |
| PDF 403 | Staff sem acesso ao `patient_id` |
| Lista vazia no app | `clinic_id` do profile ≠ dados; reaplicar seed |

---

## 8. Critério de aceite deploy Supabase

- [ ] `db push` OK
- [ ] Seed homologação aplicada
- [ ] 5 functions deployadas e testadas
- [ ] Flutter apontando URL + **anon** corretos
- [ ] PDF gerado com sucesso
- [ ] `service_role` **somente** no backend Supabase

---

Ver também: [api.md](../api.md) · [supabase-remote-fix-checklist.md](../supabase-remote-fix-checklist.md)
