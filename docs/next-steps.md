# Próximos passos técnicos — MVP Terapia do Esquema

Roadmap **técnico** após a modelagem inicial do banco (`supabase/migrations/`).

**Roadmap de produto (wireframes + diagrama lógico):** [product/master-roadmap.md](./product/master-roadmap.md) · gaps: [product/gap-analysis-from-wireframes.md](./product/gap-analysis-from-wireframes.md)

**Estabilização pós-roadmap (2026-05-31):** [qa/post-roadmap-stabilization.md](./qa/post-roadmap-stabilization.md)

**Homologação final MVP (2026-06-04):** [demo/final-mvp-homologation.md](./demo/final-mvp-homologation.md) · deploy: [deploy/supabase-deploy-checklist.md](./deploy/supabase-deploy-checklist.md) · [deploy/mobile-build-checklist.md](./deploy/mobile-build-checklist.md)

**QA pós-feedback FH-01 a FH-04 (2026-06-06):** [qa/post-feedback-homologation-qa.md](./qa/post-feedback-homologation-qa.md)

**QA Dashboard v3 + Mapa Mental v3 (2026-06-07):** [qa/dashboard-v3-mental-map-v3-homologation.md](./qa/dashboard-v3-mental-map-v3-homologation.md)

**Specs visão clínica v3 (2026-06-07):** [product/dashboard-v3-spec.md](./product/dashboard-v3-spec.md) · [product/mental-map-v3-spec.md](./product/mental-map-v3-spec.md) — Dashboard v3 fatia 1 (D1+D3) e Mapa Mental v3 (M1–M5) entregues; homologação UX/clínica pendente.

---

## Pacote de homologação / demo (2026-06-04)

- [x] Documento mestre [demo/final-mvp-homologation.md](./demo/final-mvp-homologation.md)
- [x] Checklist deploy Supabase
- [x] Checklist build mobile
- [x] [demo-checklist.md](./demo-checklist.md) e [demo-script.md](./demo-script.md) atualizados (trilha, PDF, YSQ/YAMI)
- [x] Rodada de QA pós-feedback documentada: [qa/post-feedback-homologation-qa.md](./qa/post-feedback-homologation-qa.md)
- [x] Roteiro QA Dashboard v3 + Mapa Mental v3: [qa/dashboard-v3-mental-map-v3-homologation.md](./qa/dashboard-v3-mental-map-v3-homologation.md)
- [ ] Executar homologação v3 (§1–§5 do doc QA v3) — paciente + staff + psicóloga
- [ ] Preencher tabela de feedbacks §6 e registro de sessão §7
- [x] `flutter test` pós-FH-01/FH-02/FH-03/FH-04 — `156` testes OK
- [x] `flutter analyze` pós-FH — baseline atual `47 issues`, sem erro bloqueante novo
- [ ] Sessão presencial com cliente/psicólogas — preencher critérios §11 do doc de homologação
- [ ] Homologação clínica YSQ/YAMI — [scoring-engine/clinical-homologation.md](./scoring-engine/clinical-homologation.md)
- [ ] Executar checklist manual pós-feedback em dispositivo/emulador e backend local

---

## Estabilização pós-roadmap MVP (2026-05-31)

- [x] `flutter test` — ~110 testes OK
- [x] `supabase db reset` — migrations 001–021 + seed OK
- [ ] `deno task test:scoring` — pendente (Deno não instalado localmente; ver QA doc)
- [x] **Relatório clínico PDF v1** — Edge Function `generate-clinical-report` + Flutter `clinical_reports` (staff)
- [x] Auditoria de rotas — `route_access_test` ampliado; redirect por perfil
- [x] RLS dos módulos 017–021 — documentada com queries manuais no QA
- [x] Estados loading/empty/error/refresh — revisados (limitação `AsyncStateBody` documentada)
- [ ] Roteiros manuais paciente + staff no dispositivo — checklist em [qa/post-roadmap-stabilization.md](./qa/post-roadmap-stabilization.md) §5–6

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
- [x] Seed YSQ + YAMI (migrations 014–015, planilha `ProjetoApp_questionários.xlsx`) — outras abas (Personalidade, Apego, etc.) pendentes.
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
- [x] Onboarding público de profissional: Edge Function `create-professional-account` cria clínica pessoal ou clínica/equipe sem `clinic_id` nullable.
- [x] Convite do paciente implementado com `create-patient-invitation` e `accept-patient-invitation`.
- [ ] Validar login real no remoto após `db push` da migration `009` + seed atualizada.

### 4. Row Level Security (policies)

- [x] Helpers `current_clinic_id()`, `current_role()`, `user_can_access_patient()`, etc.
- [x] Policies em `clinics`, `profiles`, `patients`, questionários, respostas, recursos, monitors (`009`).
- [x] `supabase db reset` local sem erro (migration + seed).
- [ ] `supabase db push` no remoto (substitui profiles órfãos da seed antiga — ver nota abaixo).
- [ ] Testes manuais com JWT de cada role via REST/Studio (plano: `docs/rls-test-plan.md`, smoke: `supabase/tests/rls-smoke-tests.sql`).

**Remoto:** após `009`, perfis antigos sem `auth.users` violam a FK ao validar. Rodar seed atualizada ou limpar profiles de teste antes do push.

### 5. Motor de apuração (clínico)

- [x] Fundação no Postgres: migration `20250531130013_scoring_engine_foundation.sql` (`schema_domains`, `schemas`, `questionnaire_versions`, `question_scoring_rules`, `severity_ranges` + RLS).
- [x] Fonte de verdade: **Supabase** (não Excel). Ver `docs/scoring-engine/database-schema.md`.
- [ ] `supabase db reset` / `db push` validado no ambiente de cada dev (requer Docker para reset local).
- [x] Seed DEMO global (`seed.sql` §16): 2 domínios, 5 esquemas, versão `v1-demo` active em `MVP_DEMO`, 5 regras, 20 faixas — **não é conteúdo clínico oficial**.
- [ ] Validação clínica (catálogo): `docs/scoring-engine/clinical-validation-checklist.md`.
- [ ] Homologação clínica (app + snapshot): `docs/scoring-engine/clinical-homologation.md` — YSQ e YAMI com `response_id` registrado.
- [x] Plano + templates SQL para primeiro questionário real (`docs/scoring-engine/real-questionnaire-onboarding.md`, `supabase/templates/scoring/`).
- [x] Migration `20250531140014_seed_real_ysq_foundation.sql` — YSQ (`YSQ_FOUNDATION_V1`); relatório `docs/scoring-engine/ysq-import-report.md`.
- [x] Migration `20250531150015_seed_yami_modes_foundation.sql` — YAMI (`YAMI_MODES_FOUNDATION_V1`, 19 modos, 124 itens); relatório `docs/scoring-engine/yami-import-report.md`.
- [x] Migration `20250531160016_questionnaire_reference_period.sql` — `questionnaire_versions.reference_period` (YSQ último ano, YAMI último mês, MVP unspecified).
- [ ] `db push` / `db reset` com migrations 014–016 no ambiente de cada dev.
- [ ] Licenciamento YSQ/SMI e pendências P01–P15 do checklist resolvidas antes de uso terapêutico oficial.
- [x] Motor DEMO v1 em `finish-questionnaire` (`_shared/scoring/`) — lê tabelas `013`; mantém legado `question_category_items` no snapshot para Flutter.
- [ ] Testes Deno: `deno test supabase/functions/_shared/scoring/` (na máquina com Deno instalado).
- [x] Testes Flutter: parsing `scoring-demo-1`, fallback `mvp-1`, severidade/domínios vazios (`results_domain_test.dart`).
- [ ] Idempotência: recalcular apaga/reinsere `questionnaire_results` da mesma `response_id`.
- [ ] Logs/auditoria de recálculo (opcional).

### 6. App Flutter mobile

- [x] Projeto em `mobile/` com arquitetura `core` / `shared` / `features`.
- [x] Supabase Flutter + `env.local.json` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).
- [x] Login e-mail/senha, sessão persistida, leitura de `profiles`.
- [x] Redirect por role: admin, psychologist, patient.
- [x] Telas home com atalho para módulo de pacientes (staff).
- [x] Módulo `features/patients/`: listagem (RLS), detalhe, cadastro via `create-patient`.
- [x] Módulo `features/patient_invitations/`: convite mínimo de paciente + rota pública de primeiro acesso, mantendo `create-patient` legado.
- [x] Documentação: `docs/mobile-app.md`.
- [ ] `flutter create .` + `flutter run` na máquina de desenvolvimento (SDK não validado no CI deste repo).
- [x] Fluxo de questionários via Edge Functions (`features/questionnaires/`).
- [x] Catálogo de questionários com metadados clínicos e filtro por liberação do profissional (`questionnaire_professional_access`) com fallback compatível sem migration `022`.
- [x] Introdução pré-resposta com `reference_period` (`QuestionnaireIntroPage`, `reference_period.dart`, testes).
- [x] Trilha do paciente (`features/patient_journey/`): `PatientJourneyPage`, placeholders, home → Meu plano terapêutico (`/patient/journey`).
- [x] Objetivos da terapia (`features/therapy_goals/`, migration `017`): paciente + staff, integração na trilha.
- [x] Problemas do paciente (`features/patient_problems/`, migration `018`): paciente + staff, trilha com status Em andamento.
- [x] Check-in do paciente (`features/patient_check_ins/`, migration `019`): escalas 0–10, trilha concluído se feito hoje.
- [x] Linha do tempo (`features/patient_timeline/`, migration `020`): eventos com data/período, trilha em andamento se houver registros.
- [x] Genograma (`features/genogram/`, migration `021`): pessoas + relações, trilha em andamento se houver conteúdo.
- [x] Mapa mental v1 (`features/mental_map/`): agregador read-only, sem nova migration.
- [x] Módulo `features/results/`: listagem e detalhe de resultados (staff, RLS, snapshot MVP).
- [x] `PatientResultDetailsPage`: snapshot `scoring-demo-1` + banner por questionário (`MVP_DEMO` / `YSQ_FOUNDATION_V1` / `YAMI_MODES_FOUNDATION_V1` / outros); fallback `mvp-1`.
- [x] Módulo `features/therapy_resources/`: biblioteca, liberação/revogação (staff), consumo e progresso (paciente, RLS).
- [x] Módulo `features/daily_monitors/`: registro pelo paciente, histórico staff (RLS, sem Edge Function).
- [x] Migration `012` — `viewed_at`, `completed_at` + policy de update do paciente em `patient_resource_access`.
- [x] Estabilização MVP: `RouteAccess`, refresh de sessão, erros unificados, 35 testes `flutter test`.
- [ ] Edição de paciente / troca de psicólogo responsável (UI).

### 7. API / camada de acesso (Edge Functions)

- [x] Funções MVP: `create-patient`, `create-patient-invitation`, `accept-patient-invitation`, `start-questionnaire`, `submit-questionnaire-answer`, `finish-questionnaire`.
- [x] Shared `_shared/` (auth, HTTP, errors, supabase clients).
- [x] Documentação: `docs/api.md`.
- [x] Migration `010` — coluna `questionnaire_results.snapshot` (JSONB).
- [x] Script de teste: `supabase/tests/edge-functions-flow.ps1`.
- [ ] Deploy remoto das functions + `db push` (migration 010).
- [ ] Gerar tipos TypeScript (`supabase gen types typescript`) para Flutter.
- [x] Repository Flutter para `create-patient` (`EdgeApiClient`).
- [x] Repository Flutter para convites de paciente e aceite público (`patient_invitations` + Edge Functions).
- [x] Repository Flutter para questionários (`QuestionnairesRepository` + Edge Functions).

### 7d. Estilos Parentais com múltiplas figuras parentais

- [x] Migration `025_questionnaire_response_contexts.sql`: contexts por `questionnaire_response` + `response_context_id` em `questionnaire_answers`.
- [x] Edge Functions `start-questionnaire`, `submit-questionnaire-answer` e `finish-questionnaire` adaptadas para `PARENTAL_STYLES_V1`.
- [x] Flutter: seleção de figuras parentais antes do início (`Mãe`, `Pai`, `Outro`).
- [x] Flutter: progresso separado por figura e resposta sequencial por contexto.
- [x] Resultados staff: snapshot `parental-context-v1` com seções por figura parental.
- [ ] Dashboard específico de estilos parentais, PDF e visual avançado continuam fora de escopo.

### 7b. Convite do paciente e primeiro acesso

- [x] Migration `023_patient_invitations.sql`: convites mínimos com token em hash, expiração e vínculo à clínica/profissional.
- [x] Edge Functions `create-patient-invitation` e `accept-patient-invitation`.
- [x] Staff mobile: listagem de convites, criação e cópia do link.
- [x] Paciente mobile: rota pública `/accept-invitation?token=...` para senha + dados cadastrais.
- [ ] Envio real de e-mail, reset de senha e MFA permanecem fora de escopo.

### 7c. Onboarding de profissional com clínica opcional

- [x] Migration `024_professional_onboarding_support.sql`: `clinics.clinic_type`, `clinics.owner_profile_id`, `profiles.crp`.
- [x] Edge Function pública `create-professional-account`.
- [x] Flutter: rota pública `/professional-sign-up` + `ProfessionalSignUpPage`.
- [x] Modo `solo` cria clínica pessoal automaticamente sem tornar `profiles.clinic_id` nullable.
- [x] Modo `clinic` exige nome da clínica e cria o profissional como `admin` da clínica criada.
- [ ] Billing, convite de outros profissionais, gestão de equipe, MFA e recuperação de senha permanecem fora de escopo.

### 8. Recursos e monitor (backend)

- [x] RLS para `therapy_resources` e `patient_resource_access` (migration `009`).
- [x] Progresso do paciente (`viewed_at`, `completed_at`, migration `012`).
- [x] App Flutter: liberação/revogação staff + listagem/consumo paciente (PostgREST, sem Edge Function).
- [x] App Flutter: monitor diário — paciente cria/edita; staff consulta histórico (PostgREST, RLS).
- [ ] CRUD `daily_monitors` com paginação por paciente e data (filtros avançados / API dedicada).

### 9. Estabilização pré-demo

- [x] Auditoria de rotas por role (`RouteAccess` + redirect no `go_router`).
- [x] Sessão: refresh token, logout global, splash com retry, mensagem de sessão expirada no login.
- [x] `error_mapper.dart`: Auth, PostgREST (RLS/JWT), Edge Functions, rede.
- [x] Testes: `route_access_test`, `error_mapper_test`, domínio dos módulos.
- [ ] `supabase db reset` e `edge-functions-flow.ps1` na máquina de CI/demo antes de cada release.
- [ ] Checklist manual RLS: `docs/rls-test-plan.md` no remoto.
- [ ] Rodar QA pós-feedback FH-01 a FH-04: [qa/post-feedback-homologation-qa.md](./qa/post-feedback-homologation-qa.md)

### 10. Demo funcional (mobile + seed)

- [x] `docs/demo-checklist.md` — pré-requisitos, comandos, validações, erros conhecidos.
- [x] `docs/demo-script.md` — roteiro admin → paciente → psicólogo.
- [x] Seed demo: nomes legíveis, questionário, resultados com snapshot, recursos, monitor.
- [x] Android: `applicationId` `br.com.terapiaesquema.mvp`, label **Terapia do Esquema**, doc APK debug.
- [ ] Ensaio completo do roteiro gravado ou validado 48h antes da apresentação.

### 11. Dashboard e mapa mental

- [x] **Dashboard clínico v1.1 (mobile)** — `clinical_dashboard`: home por instrumento, YSQ/YAMI com barras a partir de `snapshot`, placeholders de versão futura; trilha + staff; sem PDF/IA/web.
- [x] **Mapa mental v2 (mobile)** — `mental_map`: Formulação Visual do Caso com centro clínico, camadas principal/contextual, navegação por nós e fallback em grid; trilha + staff; sem IA e sem nova migration.
- [x] **Especificação Dashboard v3** — [product/dashboard-v3-spec.md](./product/dashboard-v3-spec.md): visão do caso, painéis por instrumento, parentais por figura, comparativo longitudinal (client-side), domínios YSQ.
- [x] **Especificação Mapa Mental v3** — [product/mental-map-v3-spec.md](./product/mental-map-v3-spec.md): camadas Núcleo/História/Plano, hub 8 nós, sparkline check-in, bottom sheet por nó.
- [x] **Dashboard v3 fatia 1 (D1 + D3)** — visão executiva do caso, prioridades, sinais recentes, callouts, estilos parentais por figura; detalhes por instrumento colapsáveis; `flutter test` 181 OK.
- [ ] **Dashboard v3 fatia 2 (D2, D4, D5)** — painel completo por instrumento, comparativo longitudinal, domínios YSQ.
- [x] **Mapa Mental v3 fatia 1 (M1 + M5)** — hub 8 nós, bottom sheet, parentais por figura.
- [x] **Mapa Mental v3 fatia 2 (M2–M4)** — tabs Núcleo/História/Plano, sparkline check-in, recursos; `flutter test` 197 OK.
- [ ] **Homologação UX/clínica v3** — [qa/dashboard-v3-mental-map-v3-homologation.md](./qa/dashboard-v3-mental-map-v3-homologation.md)
- [ ] Views materializadas ou queries agregadas para `questionnaire_results` (após motor) — **não necessário para v3**.
- [ ] Modelagem de nós/arestas do mapa mental (tabelas novas — **fora de escopo v3**).
- [x] Relatório clínico PDF v1 (staff, Edge Function) — ver [api.md](./api.md) §5.
- [ ] Dashboard web, comparativo entre instrumentos diferentes e PDF avançado — ver [product/master-roadmap.md](./product/master-roadmap.md) (Fases 5–6).

### 11b. Catálogo de questionários e acesso clínico

- [x] Migration `022_questionnaire_catalog_access.sql`: metadados clínicos em `questionnaires` e tabela `questionnaire_professional_access`.
- [x] Seed atualizada com autor, versão e observação de licença pendente para instrumentos existentes.
- [x] Admin mobile: tela `/admin/questionnaire-access` para habilitar/desabilitar instrumentos por profissional.
- [x] Fallback Flutter para ambientes sem migration `022`, preservando a listagem atual e a demo.
- [ ] Aplicar `db push` / `db reset` com a migration `022` no ambiente de cada dev e homologação.
- [ ] Validar com a clínica os autores, citações e notas de licenciamento antes de produção.

### 12. Trilha do paciente (Fase 2 produto)

- [x] `PatientJourneyPage` — hub com status Disponível / Concluído / Em desenvolvimento / Bloqueado.
- [x] Navegação para questionários, monitor e biblioteca (módulos existentes).
- [x] Objetivos da terapia integrados na trilha (`therapy_goals`).
- [x] Problemas integrados na trilha (`patient_problems`).
- [x] Check-in integrado na trilha (`patient_check_ins`).
- [x] Linha do tempo integrada na trilha (`patient_timeline_events`).
- [x] Genograma integrado na trilha (`genogram_people`, `genogram_relationships`).
- [x] Mapa mental integrado na trilha (`mental_map`).
- [x] Dashboard clínico integrado na trilha (`clinical_dashboard`).
- [ ] Evoluir trilha: ordem obrigatória, anamnese — ver [product/master-roadmap.md](./product/master-roadmap.md).

### 12b. Objetivos da terapia

- [x] Migration `20250531170017_therapy_goals.sql` + RLS.
- [x] Flutter: listagem, formulário, detalhe, concluir/arquivar (paciente e staff).
- [ ] `db push` / `db reset` com migration 017 no ambiente de cada dev.

### 12c. Problemas do paciente

- [x] Migration `20250531180018_patient_problems.sql` + RLS.
- [x] Flutter: listagem, formulário, detalhe, status melhorou/resolvido/arquivado.
- [ ] `db push` / `db reset` com migration 018 no ambiente de cada dev.

### 12d. Check-in do paciente

- [x] Migration `20250531190019_patient_check_ins.sql` + RLS (staff somente leitura).
- [x] Flutter: sliders 0–10, edição do check-in de hoje, histórico staff.
- [ ] `db push` / `db reset` com migration 019 no ambiente de cada dev.

### 12e. Linha do tempo do paciente

- [x] Migration `20250531200020_patient_timeline_events.sql` + RLS (paciente e staff).
- [x] Flutter: lista cronológica, eventos sensíveis em destaque, CRUD paciente/staff.
- [ ] `db push` / `db reset` com migration 020 no ambiente de cada dev.

### 12f. Genograma do paciente

- [x] Migration `20250531210021_patient_genogram.sql` + RLS (paciente e staff).
- [x] Flutter: listas de pessoas/relações, formulários, aviso de visualização gráfica futura.
- [ ] `db push` / `db reset` com migration 021 no ambiente de cada dev.

### 12g. Mapa mental (Formulação Visual do Caso v2 → v3)

- [x] Feature `mental_map`: hub radial responsivo com fallback em grid, cards por seção, links "Ver detalhes" e aviso clínico.
- [x] Builder `mental_case_map_builder.dart`: centro do caso + anel principal (esquemas, modos, problemas, objetivos) + anel contextual (apego, enfrentamento, parentais, história/vínculos).
- [x] Agrega `questionnaire_results`, `patient_problems`, `therapy_goals`, `patient_check_ins`, `patient_timeline_events`, `genogram_people` e `genogram_relationships`.
- [x] Sem nova migration, sem IA, sem alteração no scoring e sem inferência automática de relações.
- [x] Spec v3: [product/mental-map-v3-spec.md](./product/mental-map-v3-spec.md) — tabs Núcleo/História/Plano, hub 8 nós, sparkline, bottom sheet M5.
- [x] **v3 fatia 1 (M1 + M5):** hub 8 nós, indicador preenchido/pendente, `MentalMapNodeDetailSheet`, CTAs via `mental_map_hub_builder.dart`, parentais via `snapshot.contexts[]`.
- [x] **v3 fatia 2 (M2–M4):** tabs Núcleo/História/Plano, builders `mental_map_clinical_core_builder`, `mental_map_history_links_builder`, `mental_map_therapy_plan_builder`, sparkline check-in, recursos terapêuticos.

### 12h. Dashboard clínico (home v1.1 → v3)

- [x] `DashboardHomePage` com seções YSQ, YAMI, Estilos Parentais, Estilos de Apego, Estilos de Enfrentamento e Personalidade.
- [x] YSQ, YAMI e ATTACHMENT seguem usando painéis reais baseados em `snapshot`.
- [x] Spec v3: [product/dashboard-v3-spec.md](./product/dashboard-v3-spec.md).
- [x] **Fatia 1 implementada:** D1 visão executiva + D3 parentais por figura (`ClinicalExecutiveHeader`, `ClinicalPriorityGrid`, `ParentalStylesDashboardSection`).
- [ ] Fatia 2: D2 painel completo, D4 comparativo, D5 domínios YSQ.

### 12i. Auditoria dos instrumentos complementares (2026-06-07)

Escopo auditado nesta rodada:

- `ATTACHMENT_STYLES_V1`
- `YCI_FOUNDATION_V1`
- `YRAI_FOUNDATION_V1`
- `PERSONALITY_V1` (verificação de existência)

Critérios verificados:

- Catálogo (`questionnaires`)
- Perguntas (`questions`)
- Versão ativa (`questionnaire_versions.status = active`)
- Regras estruturadas (`question_scoring_rules`)
- Faixas (`severity_ranges`)
- Suporte no dashboard
- Suporte no mapa mental
- Suporte em resultados
- Suporte de snapshot

| Instrumento | Catálogo | Perguntas | Versão ativa | Scoring (`question_scoring_rules`) | Faixas (`severity_ranges`) | Dashboard | Mapa mental | Resultados | Snapshot | Classificação |
|-------------|----------|-----------|--------------|------------------------------------|----------------------------|-----------|--------------|------------|----------|---------------|
| `ATTACHMENT_STYLES_V1` | Sim | Sim (42) | Sim | Sim | Não documentadas | Sim | Sim | Sim | Sim (`scoring-demo-1` + fallback legado) | **IMPLEMENTADO** |
| `YCI_FOUNDATION_V1` | Sim | Sim (48) | Sim | Sim | Não | Sim | Sim | Sim | Sim | **IMPLEMENTADO** |
| `YRAI_FOUNDATION_V1` | Sim | Sim (40) | Sim | Sim | Não | Sim | Sim | Sim | Sim | **IMPLEMENTADO** |
| `PERSONALITY_V1` | Não | Não | Não | Não | Não | Não | Não | Não | Não | **NÃO IMPLEMENTADO** |

Notas de leitura:

- `Dashboard = Parcial` significa placeholder visual já presente no app, mas sem painel dedicado alimentado por dados do instrumento.
- `Snapshot = Sim (legado / genérico)` significa compatibilidade com `finish-questionnaire` + `question_category_items`, resultando em `snapshot.version = "mvp-1"` ou payload híbrido sem motor estruturado próprio do instrumento.
- `ATTACHMENT_STYLES_V1` passou a contar com `question_scoring_rules` próprias e painel dedicado no app.
- `YRAI_FOUNDATION_V1` passou a contar com `question_scoring_rules` próprias, painel dedicado no dashboard e agregação estruturada junto do nó de enfrentamento no mapa mental.

#### 12i.1 `ATTACHMENT_STYLES_V1`

- **Existe no catálogo:** sim.
- **Possui perguntas:** sim, `42` itens.
- **Possui versão ativa:** sim (`legacy_category_average`).
- **Possui scoring estruturado:** sim, via migration `026_attachment_styles_scoring.sql`, reutilizando o agrupamento legado em 3 estilos (`Ansioso`, `Seguro`, `Evitante`) dentro do domínio global `Estilos de Apego`.
- **Possui faixas:** não nesta etapa; ausência documentada, sem cortes inventados.
- **Aparece no dashboard:** sim, com painel real em `DashboardHomePage`.
- **Aparece no mapa mental:** sim, na agregação de questionários concluídos.
- **Aparece nos resultados:** sim, com parsing estruturado `scoring-demo-1`, disclaimer específico e fallback legado mantido.
- **Classificação:** **IMPLEMENTADO**.

#### 12i.2 `YCI_FOUNDATION_V1`

- **Existe no catálogo:** sim.
- **Possui perguntas:** sim, `48` itens.
- **Possui versão ativa:** sim (`legacy_category_average`).
- **Possui scoring estruturado:** sim, via migration `027_yci_scoring.sql`, reaproveitando o agrupamento legado `YCI_TOTAL` como `YCI Geral` dentro do domínio global `Estilos de Enfrentamento`.
- **Possui faixas:** não nesta etapa; ausência documentada, sem cortes inventados.
- **Aparece no dashboard:** sim, com painel real `Estilos de enfrentamento — YCI`.
- **Aparece no mapa mental:** sim, como nó contextual de `Estilos de Enfrentamento` quando houver resultado estruturado.
- **Aparece nos resultados:** sim, com parsing estruturado `scoring-demo-1`, disclaimer específico e fallback legado mantido.
- **Classificação:** **IMPLEMENTADO**.

#### 12i.3 `YRAI_FOUNDATION_V1`

- **Existe no catálogo:** sim.
- **Possui perguntas:** sim, `40` itens.
- **Possui versão ativa:** sim (`legacy_category_average`).
- **Possui scoring estruturado:** sim, via migration `028_yrai_scoring.sql`, reaproveitando o agrupamento legado `YRAI_TOTAL` como `YRAI Geral` dentro do domínio global `Estilos de Enfrentamento`.
- **Possui faixas:** não nesta etapa; ausência documentada, sem cortes inventados.
- **Aparece no dashboard:** sim, com painel real `Estilos de enfrentamento — YRAI`.
- **Aparece no mapa mental:** sim, como parte do nó contextual de `Estilos de Enfrentamento`, isoladamente ou junto com `YCI`.
- **Aparece nos resultados:** sim, com parsing estruturado `scoring-demo-1`, disclaimer específico e fallback legado mantido.
- **Classificação:** **IMPLEMENTADO**.

#### 12i.4 `PERSONALITY_V1`

- **Existe no catálogo:** não foi encontrado no catálogo nem no código.
- **Possui perguntas:** não.
- **Possui versão ativa:** não.
- **Possui scoring estruturado:** não.
- **Possui faixas:** não.
- **Aparece no dashboard:** não como instrumento real; existe apenas o card futuro `Personalidade`.
- **Aparece no mapa mental:** não.
- **Aparece nos resultados:** não.
- **Classificação:** **NÃO IMPLEMENTADO**.

Próximo passo sugerido para esses instrumentos, sem mudar banco nesta etapa:

- decidir se `ATTACHMENT`, `YCI` e `YRAI` entrarão só como instrumentos legados com leitura genérica ou se receberão onboarding completo no motor estruturado (`question_scoring_rules` + `severity_ranges` + painel dedicado);
- definir se `PERSONALITY_V1` fará parte do catálogo real ou permanece apenas como placeholder de produto/UI.

### 13. Produto — wireframes e diagrama (documentação)

- [x] `docs/product/master-roadmap.md` — mapa de módulos, comparação MVP, fases 1–7.
- [x] `docs/product/gap-analysis-from-wireframes.md` — ausências, diferenças, riscos, recomendações.
- [ ] Copiar `Wireframe App Esquemas 19Abr2026.drawio.pdf` e `Diagrama APP Esquemas.pdf` para `docs/product/sources/`.
- [ ] Revisar colunas *PDF/tela* e decisões pendentes (DP/DN) após leitura dos PDFs.

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

- Dashboard web ou gráficos radar (fora de escopo v3; ver specs v3).
- Relações automáticas inferidas no mapa mental (v3 proíbe explicitamente).
- Integração com IA no mapa mental ou dashboard.
- Gateway de pagamento / assinaturas.
- Cálculo automático em produção (função de apuração) até validação das fórmulas.
- Testes E2E automatizados de RLS por role (opcional nesta fase).
- Notificações push/e-mail.
- Relatório clínico PDF v1 (staff) — Storage permanente, e-mail e versão paciente.
- Multi-idioma do schema.
- Replicação/analytics warehouse.

---

## Artefatos entregues nesta etapa

- `supabase/migrations/20250525120001` … `20008` — schema completo do MVP.
- `supabase/migrations/20250531130013_scoring_engine_foundation.sql` — catálogo oficial do motor clínico (sem cálculo).
- `supabase/seed.sql` — seed mínima com `auth.users` + dados clínicos.
- `supabase/migrations/20250525120009_auth_and_rls.sql` — Auth + policies RLS.
- `supabase/migrations/20250525120010_questionnaire_results_snapshot.sql` — JSONB snapshot.
- `supabase/functions/*` — Edge Functions MVP.
- `docs/api.md` — contratos HTTP.
- `mobile/` — app Flutter MVP (auth + sessão).
- `docs/mobile-app.md` — guia do app mobile.
- `docs/database-model.md` — modelo e fluxos.
- `docs/next-steps.md` — este arquivo.
- `docs/product/master-roadmap.md` — roadmap de produto.
- `docs/product/dashboard-v3-spec.md` — spec Dashboard clínico v3.
- `docs/product/mental-map-v3-spec.md` — spec Mapa Mental v3.
- `docs/product/gap-analysis-from-wireframes.md` — gaps vs wireframes.

---

## Comando rápido (referência)

```bash
cd App_Clinica_Psicologia
supabase init   # se ainda não existir config local
supabase link --project-ref <PROJECT_REF>
supabase db push
```
