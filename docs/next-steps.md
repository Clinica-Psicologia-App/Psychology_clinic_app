# Próximos passos técnicos — MVP Terapia do Esquema

Roadmap após a modelagem inicial do banco (`supabase/migrations/`).

---

## Próximos passos (ordem sugerida)

### 1. Validar schema no Supabase

- [ ] Criar projeto Supabase (dev/staging).
- [ ] Instalar [Supabase CLI](https://supabase.com/docs/guides/cli) e vincular: `supabase link`.
- [ ] Aplicar migrations: `supabase db push`.
- [ ] Conferir tabelas, enums, triggers e RLS no Table Editor / SQL.

### 2. Seeds de questionários

- [x] **Seed mínima** em `supabase/seed.sql` (dados fictícios, UUIDs fixos, `ON CONFLICT (id) DO NOTHING`).
- [x] Validada localmente com `supabase db reset` (2025-05-25).
- [x] Seed replicada no remoto (`wxotrgmhevztoquqqmno`) via `supabase db query --linked -f supabase/seed.sql`.
- [ ] Seed completa de instrumentos reais (ex.: YSQ-S3, SMI) — fora do escopo da seed mínima.
- [ ] Documentar tabela de cortes (`classification`) por instrumento em planilha ou JSON versionado (fora do banco no MVP, se preferir).

#### Seed mínima — o que contém

| Entidade | Qtd | UUID fixo (exemplo) |
|----------|-----|---------------------|
| `clinics` | 1 | `…1101` |
| `profiles` | 3 | admin `…1102`, psychologist `…1103`, patient `…1104` |
| `patients` | 1 | `…1201` → profile + psicólogo `…1103` |
| `questionnaires` | 1 | `…1301` (`MVP_DEMO`) |
| `question_categories` | 1 | `…1401` |
| `questions` | 5 | `…1501`–`…1505` |
| `question_category_items` | 5 | `…1601`–`…1605` |
| `questionnaire_responses` | 1 | `…1701` (`completed`) |
| `questionnaire_answers` | 5 | `…1801`–`…1805` (Likert 1–6) |

E-mails/domínio fictício: `@clinicateste-mvp.example`. CPF fictício: `00000000191`.

**Login local (após `db reset`):** senha `TesteMVP2025!` — `admin@…`, `psicologo@…`, `paciente.login@…`

```bash
supabase start          # se ainda não estiver rodando
supabase db reset       # migrations + seed
supabase db query --local "SELECT count(*) FROM patients;"
```

### 3. Autenticação e vínculo com profiles

- [x] `profiles.id = auth.users.id` (FK + `ON DELETE CASCADE`, migration `009`).
- [x] Triggers `handle_new_user` / `handle_user_email_updated` em `auth.users`.
- [x] Seed com `auth.users` + `auth.identities` e metadata `clinic_id` + `role`.
- [ ] Habilitar/confirmer Auth no projeto remoto (e-mail já suportado).
- [ ] Fluxo de convite: Admin API `createUser` com `user_metadata` para novos profissionais/pacientes.
- [ ] Validar login real no remoto após `db push` da migration `009` + seed atualizada.

### 4. Row Level Security (policies)

- [x] Helpers `current_clinic_id()`, `current_role()`, `user_can_access_patient()`, etc.
- [x] Policies em `clinics`, `profiles`, `patients`, questionários, respostas, recursos, monitors (`009`).
- [x] `supabase db reset` local sem erro (migration + seed).
- [ ] `supabase db push` no remoto (substitui profiles órfãos da seed antiga — ver nota abaixo).
- [ ] Testes manuais com JWT de cada role via REST/Studio (plano: `docs/rls-test-plan.md`, smoke: `supabase/tests/rls-smoke-tests.sql`).

**Remoto:** após `009`, perfis antigos sem `auth.users` violam a FK ao validar. Rodar seed atualizada ou limpar profiles de teste antes do push.

### 5. Motor de apuração

- [ ] Especificar fórmula por instrumento (soma ponderada, média, % máximo teórico).
- [ ] Implementar como `SECURITY DEFINER` function ou Edge Function chamada ao `status = completed`.
- [ ] Idempotência: recalcular apaga/reinsere `questionnaire_results` da mesma `response_id`.
- [ ] Logs/auditoria de recálculo (opcional).

### 6. App Flutter mobile

- [x] Projeto em `mobile/` com arquitetura `core` / `shared` / `features`.
- [x] Supabase Flutter + `env.local.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- [x] Login e-mail/senha, sessão persistida, leitura de `profiles`.
- [x] Redirect por role: admin, psychologist, patient.
- [x] Telas home com atalho para módulo de pacientes (staff).
- [x] Módulo `features/patients/`: listagem (RLS), detalhe, cadastro via `create-patient`.
- [x] Documentação: `docs/mobile-app.md`.
- [ ] `flutter create .` + `flutter run` na máquina de desenvolvimento (SDK não validado no CI deste repo).
- [ ] Fluxo de questionários via Edge Functions.
- [ ] Edição de paciente / troca de psicólogo responsável (UI).

### 7. API / camada de acesso (Edge Functions)

- [x] Funções MVP: `create-patient`, `start-questionnaire`, `submit-questionnaire-answer`, `finish-questionnaire`.
- [x] Shared `_shared/` (auth, HTTP, errors, supabase clients).
- [x] Documentação: `docs/api.md`.
- [x] Migration `010` — coluna `questionnaire_results.snapshot` (JSONB).
- [x] Script de teste: `supabase/tests/edge-functions-flow.ps1`.
- [ ] Deploy remoto das functions + `db push` (migration 010).
- [ ] Gerar tipos TypeScript (`supabase gen types typescript`) para Flutter.
- [x] Repository Flutter para `create-patient` (`EdgeApiClient`).
- [ ] Repositories Flutter para questionários (`start` / `submit` / `finish`).

### 8. Recursos e monitor (backend)

- [ ] Endpoints ou RPC para liberar/revogar `patient_resource_access`.
- [ ] CRUD `daily_monitors` com paginação por paciente e data.

### 9. Dashboard e mapa mental

- [ ] Views materializadas ou queries agregadas para `questionnaire_results` (após motor).
- [ ] Modelagem de nós/arestas do mapa mental (tabelas novas — **não** antecipar no schema atual além de `therapy_resources`).

---

## Pendências de validação (negócio + técnico)

| Tema | Pergunta em aberto |
|------|-------------------|
| Tenant de questionários | Catálogo global está ok para MVP? Clínicas customizadas exigiriam `clinic_id` em `questionnaires`. |
| CPF único | Índice único `(clinic_id, cpf)` quando CPF preenchido — confirmar LGPD e duplicidade entre clínicas. |
| Respostas texto | `answer_value` numérico não cobre `answer_type = text` — adicionar `answer_text`? |
| Psicólogo responsável | Obrigatório no cadastro do paciente ou opcional? |
| Monitor diário | Um registro por dia (unique `patient_id + date`) ou múltiplos por dia? |
| Cortes clínicos | Quem define faixas de `classification` por categoria/instrumento? |
| Timezone | Exibição local vs persistência UTC nas telas. |
| RLS com policies | Cliente deve usar **anon key + JWT** do usuário; `service_role` só no servidor. |
| FK profiles ↔ auth no remoto | Seed antiga sem `auth.users` impede validação da FK | `db push` 009 + `seed.sql` atualizado ou limpar órfãos |

---

## Riscos

| Risco | Impacto | Mitigação |
|-------|---------|-----------|
| RLS ativo sem policies | App cliente não acessa dados | Policies antes de expor API ao front; usar service role só server-side temporariamente |
| Motor de apuração inconsistente | Resultados clínicos incorretos | Testes unitários por instrumento; revisão por psicólogo responsável |
| `profiles.id` ≠ `auth.users.id` | Login quebrado ou duplicidade | Definir estratégia antes do primeiro deploy com Auth |
| Questionários só em seed | Alteração exige migration/ops | Processo de versionamento de instrumentos |
| Campos demográficos sensíveis | LGPD | Minimização de dados; consentimento; política de retenção |
| Falta de soft delete | Dados “apagados” sumiram | Considerar `deleted_at` em pacientes/respostas em iteração futura |

---

## O que ainda NÃO deve ser implementado nesta fase

- Telas React / Flutter.
- Dashboard visual ou gráficos.
- Mapa mental interativo (UI e grafo).
- Integração com IA.
- Gateway de pagamento / assinaturas.
- Cálculo automático em produção (função de apuração) até validação das fórmulas.
- Testes E2E automatizados de RLS por role (opcional nesta fase).
- Notificações push/e-mail.
- Relatórios PDF.
- Multi-idioma do schema.
- Replicação/analytics warehouse.

---

## Artefatos entregues nesta etapa

- `supabase/migrations/20250525120001` … `20008` — schema completo do MVP.
- `supabase/seed.sql` — seed mínima com `auth.users` + dados clínicos.
- `supabase/migrations/20250525120009_auth_and_rls.sql` — Auth + policies RLS.
- `supabase/migrations/20250525120010_questionnaire_results_snapshot.sql` — JSONB snapshot.
- `supabase/functions/*` — Edge Functions MVP.
- `docs/api.md` — contratos HTTP.
- `mobile/` — app Flutter MVP (auth + sessão).
- `docs/mobile-app.md` — guia do app mobile.
- `docs/database-model.md` — modelo e fluxos.
- `docs/next-steps.md` — este arquivo.

---

## Comando rápido (referência)

```bash
cd App_Clinica_Psicologia
supabase init   # se ainda não existir config local
supabase link --project-ref <PROJECT_REF>
supabase db push
```
