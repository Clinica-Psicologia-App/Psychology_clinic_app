# Checklist — corrigir Supabase remoto + validar app

Projeto remoto: **`wxotrgmhevztoquqqmno`**  
URL: `https://wxotrgmhevztoquqqmno.supabase.co`

Sintoma atual: login retorna **500** — `Database error querying schema`.  
Objetivo: schema alinhado, seed com `auth.users`, Edge Functions no ar, login OK no Flutter.

---

## Pré-requisitos

- [ ] Acesso ao [Supabase Dashboard](https://supabase.com/dashboard/project/wxotrgmhevztoquqqmno) (owner ou admin)
- [ ] Supabase CLI instalado (`brew install supabase/tap/supabase`)
- [ ] `mobile/env.local.json` com `SUPABASE_URL` e `SUPABASE_ANON_KEY` do mesmo projeto

```bash
supabase --version   # esperado: 2.x
```

---

## Fase 1 — Diagnóstico (5 min)

### 1.1 Logs no Dashboard

- [ ] **Logs → Auth** — buscar `error_id` do login (ex.: `019e7e3a-bf74-7635-a8d0-1df731706227`)
- [ ] **Logs → Postgres** — erros de trigger, FK ou migration na mesma hora
- [ ] **Database → Migrations** — conferir se migrations `20250525120001` … `20010` estão aplicadas

### 1.2 Smoke test local (sem CLI link)

Na raiz do repo:

```bash
./scripts/validate-remote-supabase.sh
```

Marque o que falhou:

| Teste | Esperado | Se falhar |
|-------|----------|-----------|
| Auth health | HTTP 200 | Projeto pausado ou URL errada |
| Login admin | `access_token` | Ir para Fase 2 |
| Profile (JWT) | 1 linha com `role` | RLS ou profile ausente |
| Patients (admin) | ≥ 0 linhas | RLS ou seed |
| Edge OPTIONS | 204 | Deploy das functions (Fase 3) |

---

## Fase 2 — Schema e dados (CLI)

### 2.1 Login e link

```bash
cd /Users/starkbfs/dev/Aplicativo-Clinica-Psicologia
supabase login
supabase link --project-ref wxotrgmhevztoquqqmno
```

- [ ] `supabase projects list` mostra o projeto
- [ ] Pasta `.supabase` criada (não commitar secrets)

### 2.2 (Opcional) Limpar profiles órfãos

Só se `db push` falhar por FK `profiles.id → auth.users.id` ou se existirem profiles de seed antiga **sem** usuário Auth.

No **SQL Editor** do Dashboard (ou `supabase db query --linked`):

```sql
-- Perfis sem usuário Auth (seed antiga)
SELECT p.id, p.email, p.role
FROM public.profiles p
LEFT JOIN auth.users u ON u.id = p.id
WHERE u.id IS NULL;

-- CUIDADO: apaga só órfãos de teste. Revise a lista antes.
-- DELETE FROM public.patients WHERE profile_id IN (...);
-- DELETE FROM public.profiles WHERE id IN (...);
```

- [ ] Lista de órfãos revisada
- [ ] Backup ou projeto **dev** confirmado (não rodar DELETE em produção real sem revisão)

### 2.3 Aplicar migrations

```bash
supabase db push
```

- [ ] Sem erro (todas as migrations 001–010)
- [ ] Migration `20250525120009_auth_and_rls.sql` aplicada (Auth + RLS)
- [ ] Migration `20250525120010_questionnaire_results_snapshot.sql` aplicada

Se `db push` pedir confirmação de drift, leia o diff no terminal antes de aceitar.

### 2.4 Reaplicar seed mínima

```bash
supabase db query --linked -f supabase/seed.sql
```

- [ ] Comando concluiu sem erro
- [ ] Três usuários em Auth: `admin@`, `psicologo@`, `paciente.login@` @ `clinicateste-mvp.example`
- [ ] Senha: `TesteMVP2025!`

Conferência rápida:

```bash
supabase db query --linked --sql "SELECT id, email, role FROM public.profiles ORDER BY role;"
```

### 2.5 Auth no Dashboard

- [ ] **Authentication → Providers → Email** habilitado
- [ ] **Confirm email** desligado para dev (ou usuários seed com `email_confirmed_at` — já na seed)
- [ ] Nenhuma restrição de domínio bloqueando `@clinicateste-mvp.example`

---

## Fase 3 — Edge Functions

```bash
cd /Users/starkbfs/dev/Aplicativo-Clinica-Psicologia
supabase functions deploy create-patient
supabase functions deploy start-questionnaire
supabase functions deploy submit-questionnaire-answer
supabase functions deploy finish-questionnaire
```

- [ ] Quatro deploys OK
- [ ] **Edge Functions** no Dashboard listam as quatro funções
- [ ] Secrets padrão do projeto presentes (`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` — automático no hosted)

Teste manual (após login OK):

```bash
./scripts/validate-remote-supabase.sh --full
```

---

## Fase 4 — Validar no app Flutter

```bash
cd mobile
open -a Simulator   # se necessário
flutter run -d "iPhone 16 Pro" --dart-define-from-file=env.local.json
```

### 4.1 Login

- [ ] Chip **Admin** → login sem erro
- [ ] Logout → chip **Psicólogo** → login OK
- [ ] Logout → chip **Paciente** → login OK

### 4.2 Admin

- [ ] Home admin carrega nome do profile
- [ ] **Pacientes** → lista (≥ 1 paciente seed)
- [ ] Abrir detalhe do paciente seed
- [ ] **Novo paciente** → criar com e-mail novo → sucesso (Edge `create-patient`)

### 4.3 Psicólogo

- [ ] Lista só pacientes do psicólogo logado (RLS)
- [ ] Criar paciente com ele como responsável

### 4.4 Paciente

- [ ] Home paciente (sem menu de staff)
- [ ] Sem acesso à rota de pacientes do admin

---

## Fase 5 — Critérios de “100% funcional” (MVP atual)

| Critério | Obrigatório para MVP |
|----------|----------------------|
| Login 3 roles | Sim |
| Profile + RLS | Sim |
| Listar / detalhe pacientes | Sim |
| Criar paciente (Edge) | Sim |
| Questionários no app | **Não** (backend existe; UI Flutter pendente) |
| Editar paciente | **Não** (pendente) |

Quando Fases 1–4 estiverem marcadas: **MVP remoto funcional** para auth + pacientes.

---

## Troubleshooting

### `Database error querying schema` no login

1. Ver **Logs → Auth** e **Postgres** no Dashboard.
2. `supabase db push` + `seed.sql` (Fase 2).
3. Confirmar que `auth.users` tem linhas para os e-mails seed (`supabase db query --linked`).
4. Se persistir: projeto **Restore** / suporte Supabase com `error_id`.

### `Invalid login credentials`

- Seed não aplicada ou senha diferente de `TesteMVP2025!`.
- E-mail com typo (domínio `@clinicateste-mvp.example`).

### `create-patient` 401 / 403

- JWT expirado — faça login de novo.
- Function não deployada (Fase 3).
- Role não é `admin` nem `psychologist`.

### App não conecta

- `env.local.json` aponta para o mesmo `project-ref`.
- Comando sempre com `--dart-define-from-file=env.local.json`.
- iOS: use `-d "iPhone 16 Pro"`, não `-d ios`.

### RLS retorna `[]` vazio

- Usuário logado mas sem `profile` — rodar seed ou trigger `handle_new_user`.
- Psychologist vendo lista vazia: paciente sem `responsible_psychologist_id` correto.

---

## Comandos de referência (copiar/colar)

```bash
# Repo
cd /Users/starkbfs/dev/Aplicativo-Clinica-Psicologia
supabase login
supabase link --project-ref wxotrgmhevztoquqqmno
supabase db push
supabase db query --linked -f supabase/seed.sql
supabase functions deploy create-patient
supabase functions deploy start-questionnaire
supabase functions deploy submit-questionnaire-answer
supabase functions deploy finish-questionnaire
./scripts/validate-remote-supabase.sh --full

# App
cd mobile && flutter run -d "iPhone 16 Pro" --dart-define-from-file=env.local.json
```

---

## Após concluir

Atualize mentalmente `docs/next-steps.md` (itens remoto / deploy / login) e guarde o output de:

```bash
./scripts/validate-remote-supabase.sh --full > /tmp/validate-remote.log 2>&1
```

Se quiser ajuda na execução: rode `supabase login` no terminal, avise quando terminar, e peça para revalidar com o script.
