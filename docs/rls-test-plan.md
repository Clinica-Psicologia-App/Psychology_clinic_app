# Plano de testes manuais — Auth + RLS

Validação da migration `20250525120009_auth_and_rls.sql` com dados da `supabase/seed.sql`.

**Pré-requisitos**

```bash
supabase db reset   # migrations + seed
```

**Como simular um usuário no SQL** (Supabase local ou SQL Editor com role `postgres`):

```sql
BEGIN;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub', '<UUID_DO_USUARIO>', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);

-- sua query aqui

ROLLBACK;  -- não persistir testes
```

`auth.uid()` passa a retornar o UUID configurado.

**Interpretação**

| Resultado | SELECT | INSERT / UPDATE |
|-----------|--------|-----------------|
| Permitido | ≥ 1 linha (ou linha esperada) | 1 linha afetada / sucesso |
| Bloqueado | 0 linhas | Erro RLS **ou** `UPDATE`/`DELETE` com **0 linhas** (sem exceção) |

**Arquivo auxiliar:** `supabase/tests/rls-smoke-tests.sql` (smoke automatizado em transação).

```powershell
# Windows (pipe para psql no container)
Get-Content supabase/tests/rls-smoke-tests.sql -Raw | docker exec -i supabase_db_App_Clinica_Psicologia psql -U postgres -d postgres
```

> `supabase db query -f` não aceita múltiplos comandos; use `psql` como acima.

---

## 1. Usuários de teste

| Perfil | E-mail | Senha | `auth.users.id` / `profiles.id` |
|--------|--------|-------|----------------------------------|
| **admin** | `admin@clinicateste-mvp.example` | `TesteMVP2025!` | `11111111-1111-1111-1111-111111111102` |
| **psicólogo** | `psicologo@clinicateste-mvp.example` | `TesteMVP2025!` | `11111111-1111-1111-1111-111111111103` |
| **paciente** | `paciente.login@clinicateste-mvp.example` | `TesteMVP2025!` | `11111111-1111-1111-1111-111111111104` |

**Referências de dados (seed)**

| Recurso | UUID |
|---------|------|
| Clínica | `11111111-1111-1111-1111-111111111101` |
| Paciente (`patients`) | `11111111-1111-1111-1111-111111111201` |
| Questionário | `11111111-1111-1111-1111-111111111301` |
| Response | `11111111-1111-1111-1111-111111111701` |
| Answer (Q01) | `11111111-1111-1111-1111-111111111801` |

**Usuário sem profile (controle negativo):** `99999999-9999-9999-9999-999999999901` (não existe na seed).

---

## 2. Testes por tabela e perfil

Legenda de colunas: **Usuário** | **SQL** | **Esperado** | **Risco coberto**

---

### `clinics`

#### T-CLINICS-01 — SELECT própria clínica

| Campo | Valor |
|-------|--------|
| Usuário | admin (`…1102`) |
| SQL | `SELECT id, name FROM public.clinics;` |
| Esperado | **1 linha** (`…1101`, Clínica Teste MVP) |
| Risco | Admin não vê tenant |

#### T-CLINICS-02 — SELECT bloqueado sem profile

| Campo | Valor |
|-------|--------|
| Usuário | UUID inexistente (`…9901`) |
| SQL | `SELECT * FROM public.clinics;` |
| Esperado | **0 linhas** |
| Risco | Acesso anônimo / usuário sem profile |

#### T-CLINICS-03 — UPDATE nome (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `UPDATE public.clinics SET name = name WHERE id = '11111111-1111-1111-1111-111111111101';` |
| Esperado | **1 linha atualizada** |
| Risco | Admin não gerencia clínica |

#### T-CLINICS-04 — UPDATE bloqueado (psicólogo)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo (`…1103`) |
| SQL | `UPDATE public.clinics SET name = 'Hack' WHERE id = '11111111-1111-1111-1111-111111111101';` |
| Esperado | **0 linhas** ou erro RLS |
| Risco | Escalação de privilégio staff→admin |

#### T-CLINICS-05 — SELECT (paciente vê própria clínica)

| Campo | Valor |
|-------|--------|
| Usuário | paciente (`…1104`) |
| SQL | `SELECT id FROM public.clinics;` |
| Esperado | **1 linha** |
| Risco | Paciente sem contexto de tenant |

---

### `profiles`

#### T-PROFILES-01 — SELECT colegas da clínica (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `SELECT id, role FROM public.profiles ORDER BY role;` |
| Esperado | **3 linhas** (admin, psychologist, patient) |
| Risco | Admin não lista equipe |

#### T-PROFILES-02 — SELECT (paciente vê perfis da clínica)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT count(*) FROM public.profiles;` |
| Esperado | **3** (policy: mesma `clinic_id`) |
| Risco | Paciente isolado demais para UX mínima |

#### T-PROFILES-03 — UPDATE próprio perfil (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `UPDATE public.profiles SET phone = '+5511999990099' WHERE id = auth.uid();` |
| Esperado | **1 linha** |
| Risco | Paciente não atualiza cadastro |

#### T-PROFILES-04 — UPDATE outro perfil (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `UPDATE public.profiles SET full_name = 'X' WHERE id = '11111111-1111-1111-1111-111111111103';` |
| Esperado | **0 linhas** / erro RLS |
| Risco | Paciente altera psicólogo |

#### T-PROFILES-05 — UPDATE perfil alheio (psicólogo → admin)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo |
| SQL | `UPDATE public.profiles SET full_name = 'X' WHERE id = '11111111-1111-1111-1111-111111111102';` |
| Esperado | **0 linhas** / erro RLS |
| Risco | Staff altera admin |

---

### `patients`

#### T-PATIENTS-01 — SELECT todos da clínica (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `SELECT id, full_name FROM public.patients;` |
| Esperado | **≥ 1** (seed: Paciente Fictício) |
| Risco | Admin sem visão de pacientes |

#### T-PATIENTS-02 — SELECT paciente sob responsabilidade (psicólogo)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo |
| SQL | `SELECT id FROM public.patients WHERE id = '11111111-1111-1111-1111-111111111201';` |
| Esperado | **1 linha** (`responsible_psychologist_id = psicólogo`) |
| Risco | Psicólogo não vê seus pacientes |

#### T-PATIENTS-03 — SELECT próprio prontuário (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT id, full_name FROM public.patients;` |
| Esperado | **1 linha** (`profile_id = auth.uid()`) |
| Risco | Paciente não acessa próprio registro |

#### T-PATIENTS-04 — INSERT paciente (psicólogo, responsável = self)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo |
| SQL | Ver bloco em `rls-smoke-tests.sql` (`INSERT` paciente fictício) |
| Esperado | **Sucesso** (depois `ROLLBACK`) |
| Risco | Psicólogo não cadastra paciente |

#### T-PATIENTS-05 — INSERT com `responsible_psychologist_id` de outro (psicólogo)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo |
| SQL | `INSERT INTO public.patients (id, clinic_id, responsible_psychologist_id, full_name) VALUES (gen_random_uuid(), '11111111-1111-1111-1111-111111111101', '11111111-1111-1111-1111-111111111102', 'Intruso');` |
| Esperado | **Erro RLS** (WITH CHECK exige `responsible_psychologist_id = auth.uid()`) |
| Risco | Psicólogo vincula paciente a outro profissional |

#### T-PATIENTS-06 — INSERT paciente (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `INSERT INTO public.patients (id, clinic_id, full_name) VALUES (gen_random_uuid(), '11111111-1111-1111-1111-111111111101', 'Novo');` |
| Esperado | **Erro RLS** |
| Risco | Paciente auto-cadastra prontuário |

#### T-PATIENTS-07 — Cross-tenant (tentativa)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `INSERT INTO public.patients (id, clinic_id, full_name) VALUES (gen_random_uuid(), '22222222-2222-2222-2222-222222222201', 'Outra clínica');` |
| Esperado | **Erro RLS** (`clinic_id` ≠ `current_clinic_id()`) |
| Risco | Cross-tenant write |

---

### `questionnaires`

#### T-QUEST-01 — SELECT catálogo (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `SELECT id, code FROM public.questionnaires WHERE code = 'MVP_DEMO';` |
| Esperado | **1 linha** |
| Risco | Staff sem instrumentos |

#### T-QUEST-02 — SELECT catálogo (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT count(*) FROM public.questionnaires;` |
| Esperado | **≥ 1** |
| Risco | Paciente não aplica questionário |

#### T-QUEST-03 — INSERT catálogo (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `INSERT INTO public.questionnaires (id, code, name) VALUES (gen_random_uuid(), 'HACK', 'Hack');` |
| Esperado | **Erro RLS** (sem policy INSERT) |
| Risco | Cliente altera catálogo global |

#### T-QUEST-04 — SELECT sem profile

| Campo | Valor |
|-------|--------|
| Usuário | `…9901` |
| SQL | `SELECT * FROM public.questionnaires;` |
| Esperado | **0 linhas** |
| Risco | Leitura sem autenticação |

---

### `questionnaire_responses`

#### T-RESP-01 — SELECT response da seed (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `SELECT id, status FROM public.questionnaire_responses WHERE id = '11111111-1111-1111-1111-111111111701';` |
| Esperado | **1 linha** (`completed`) |
| Risco | Admin não audita respostas |

#### T-RESP-02 — SELECT (paciente própria response)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT id FROM public.questionnaire_responses;` |
| Esperado | **≥ 1** (seed) |
| Risco | Paciente não vê histórico |

#### T-RESP-03 — SELECT (psicólogo)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo |
| SQL | `SELECT count(*) FROM public.questionnaire_responses;` |
| Esperado | **≥ 1** |
| Risco | Psicólogo sem acesso clínico |

#### T-RESP-04 — INSERT response (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | Ver `rls-smoke-tests.sql` — INSERT `draft` |
| Esperado | **Sucesso** |
| Risco | Paciente não inicia questionário |

#### T-RESP-05 — INSERT para outro `patient_id` (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `INSERT INTO public.questionnaire_responses (id, clinic_id, patient_id, questionnaire_id, status) VALUES (gen_random_uuid(), '11111111-1111-1111-1111-111111111101', '00000000-0000-0000-0000-000000000099', '11111111-1111-1111-1111-111111111301', 'draft');` |
| Esperado | **Erro RLS** |
| Risco | Paciente responde por outro |

---

### `questionnaire_answers`

#### T-ANS-01 — SELECT answers via response (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT count(*) FROM public.questionnaire_answers WHERE response_id = '11111111-1111-1111-1111-111111111701';` |
| Esperado | **5** |
| Risco | Vazamento de respostas individuais |

#### T-ANS-02 — UPDATE answer (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `UPDATE public.questionnaire_answers SET answer_value = 1 WHERE id = '11111111-1111-1111-1111-111111111801';` |
| Esperado | **1 linha** |
| Risco | Paciente não corrige resposta |

#### T-ANS-03 — INSERT answer em response alheia

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `INSERT INTO public.questionnaire_answers (id, response_id, question_id, answer_value) VALUES (gen_random_uuid(), '00000000-0000-0000-0000-000000000099', '11111111-1111-1111-1111-111111111501', 1);` |
| Esperado | **Erro RLS** |
| Risco | Injeção de resposta em sessão alheia |

---

### `questionnaire_results`

#### T-RESULTS-01 — SELECT (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `SELECT count(*) FROM public.questionnaire_results WHERE response_id = '11111111-1111-1111-1111-111111111701';` |
| Esperado | **0 ou mais** (seed não popula results; 0 é OK) |
| Risco | Admin não vê apuração |

#### T-RESULTS-02 — INSERT resultado (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | Ver `rls-smoke-tests.sql` |
| Esperado | **Erro RLS** (apenas staff) |
| Risco | Paciente forja score clínico |

#### T-RESULTS-03 — INSERT resultado (psicólogo)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo |
| SQL | Ver `rls-smoke-tests.sql` |
| Esperado | **Sucesso** (se response acessível) |
| Risco | Motor futuro bloqueado para staff |

---

### `daily_monitors`

> A seed **não** inclui monitors. Use o bloco **SETUP** em `rls-smoke-tests.sql` ou insira manualmente como `postgres` antes do teste.

#### T-MON-01 — SELECT (paciente, após SETUP)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT id, mood_notes FROM public.daily_monitors WHERE patient_id = public.current_patient_id();` |
| Esperado | **≥ 0** (≥1 após SETUP) |
| Risco | Paciente não lê diário |

#### T-MON-02 — INSERT (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `INSERT INTO public.daily_monitors (id, clinic_id, patient_id, mood_notes) VALUES (gen_random_uuid(), '11111111-1111-1111-1111-111111111101', '11111111-1111-1111-1111-111111111201', 'Teste');` |
| Esperado | **Sucesso** |
| Risco | Paciente não registra humor |

#### T-MON-03 — INSERT com outro `patient_id` (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `INSERT INTO public.daily_monitors (id, clinic_id, patient_id, mood_notes) VALUES (gen_random_uuid(), '11111111-1111-1111-1111-111111111101', '00000000-0000-0000-0000-000000000099', 'Hack');` |
| Esperado | **Erro RLS** |
| Risco | Paciente escreve no diário de outro |

---

### `therapy_resources`

> Requer **SETUP** (recurso + `patient_resource_access`) em `rls-smoke-tests.sql`.

#### T-RES-01 — SELECT (admin)

| Campo | Valor |
|-------|--------|
| Usuário | admin |
| SQL | `SELECT id, title FROM public.therapy_resources WHERE clinic_id = '11111111-1111-1111-1111-111111111101';` |
| Esperado | **≥ 1** após SETUP |
| Risco | Admin não gerencia biblioteca |

#### T-RES-02 — SELECT recurso liberado (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT id, title FROM public.therapy_resources;` |
| Esperado | **≥ 1** apenas recursos com `patient_resource_access` ativo |
| Risco | Paciente vê biblioteca inteira da clínica |

#### T-RES-03 — SELECT recurso não liberado (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `SELECT * FROM public.therapy_resources WHERE id = '<UUID_RECURSO_NAO_LIBERADO>';` |
| Esperado | **0 linhas** |
| Risco | Vazamento de materiais não liberados |

#### T-RES-04 — INSERT recurso (psicólogo)

| Campo | Valor |
|-------|--------|
| Usuário | psicólogo |
| SQL | `INSERT INTO public.therapy_resources (id, clinic_id, title, type) VALUES (gen_random_uuid(), '11111111-1111-1111-1111-111111111101', 'Novo', 'article');` |
| Esperado | **Sucesso** |
| Risco | Staff não publica material |

#### T-RES-05 — INSERT recurso (paciente)

| Campo | Valor |
|-------|--------|
| Usuário | paciente |
| SQL | `INSERT INTO public.therapy_resources (id, clinic_id, title, type) VALUES (gen_random_uuid(), '11111111-1111-1111-1111-111111111101', 'Hack', 'article');` |
| Esperado | **Erro RLS** |
| Risco | Paciente publica conteúdo |

---

## 3. Matriz resumida (smoke)

| Tabela | admin SELECT | psicólogo SELECT | paciente SELECT | paciente INSERT indevido |
|--------|--------------|------------------|-----------------|---------------------------|
| clinics | ✅ | ❌ update only | ✅ | N/A |
| profiles | ✅ 3 | ✅ 3 | ✅ 3 | ❌ update outros |
| patients | ✅ | ✅ seu paciente | ✅ 1 | ❌ |
| questionnaires | ✅ | ✅ | ✅ | ❌ insert |
| questionnaire_responses | ✅ | ✅ | ✅ | ❌ outro patient |
| questionnaire_answers | ✅ | ✅ | ✅ | ❌ |
| questionnaire_results | ✅ | ✅ insert | ✅ read / ❌ insert | ❌ insert |
| daily_monitors | ✅ | ✅ | ✅ próprio | ❌ outro patient |
| therapy_resources | ✅ | ✅ | ✅ só liberado | ❌ insert |

---

## 4. Teste via REST (opcional)

1. Login: `POST /auth/v1/token?grant_type=password` com e-mail/senha do usuário.
2. Usar `apikey` + `Authorization: Bearer <access_token>`.
3. `GET /rest/v1/patients?select=id` — comparar contagem com a matriz acima.

Local: `http://127.0.0.1:54321` — chaves em `supabase status`.

---

## 5. Registro de execução

| Data | Ambiente | Executor | Resultado |
|------|----------|----------|-----------|
| | local / remoto | | |

Preencher após rodar `rls-smoke-tests.sql` e amostra dos casos T-* acima.
