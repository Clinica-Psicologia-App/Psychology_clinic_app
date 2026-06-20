# App mobile Flutter — MVP Terapia do Esquema

> Regra vigente desde 2026-06-20: o cadastro profissional público foi removido.
> Administradores criam os acessos da equipe; pacientes entram por convite.

Cliente iOS/Android com autenticação Supabase e navegação por `role` do profile.

**QA pós-roadmap:** rotas, RLS, estados de UI e roteiros manuais em [qa/post-roadmap-stabilization.md](./qa/post-roadmap-stabilization.md).

## Localização no repositório

```text
mobile/
  lib/
    core/                 # config, erros, router, Supabase, rede (Edge Functions)
    shared/               # widgets compartilhados
    features/
      auth/               # login, sessão, telas home
      profile/            # leitura do próprio profile (RLS)
      patients/           # listagem, detalhe e cadastro (staff)
      questionnaires/   # listar, responder e finalizar (Edge Functions)
      results/          # visualizar respostas e snapshot MVP (staff, RLS)
      therapy_resources/ # liberar e consumir materiais (staff + paciente, RLS)
      daily_monitors/    # registro diário do paciente (insert/update paciente, leitura staff)
      patient_journey/   # trilha / plano terapêutico do paciente (hub de módulos)
      therapy_goals/     # objetivos terapêuticos (paciente + staff, RLS)
      patient_problems/  # problemas / queixas (paciente + staff, RLS)
      patient_check_ins/ # check-in rápido 0–10 (paciente edita; staff leitura)
      patient_timeline/  # linha do tempo (paciente + staff CRUD)
      genogram/          # genograma: pessoas + relações (lista; gráfico futuro)
      mental_map/        # mapa mental: hub visual radial + agregador read-only
      clinical_dashboard/ # dashboard home por instrumento (snapshot, sem recálculo)
      clinical_reports/   # relatório PDF staff via Edge Function
  env.example.json        # modelo de variáveis
  env.local.json          # gitignored — cópia local (não commitar produção)
```

## Configuração Supabase

| Variável | Origem |
|----------|--------|
| `SUPABASE_URL` | `--dart-define-from-file=env.local.json` |
| `SUPABASE_ANON_KEY` | idem |

Classe: `lib/core/config/env_config.dart`

- **iOS Simulator / desktop:** `http://127.0.0.1:54321`
- **Android Emulator:** `http://10.0.2.2:54321` (automático se não houver define)
- **Dispositivo físico:** IP da máquina na rede (ex.: `http://192.168.x.x:54321`)

Obter chaves locais:

```bash
supabase status -o json
```

## Autenticação e sessão

- `supabase_flutter` com **PKCE** e persistência nativa de sessão.
- Login: `signInWithPassword`.
- Ao abrir o app: `restoreSession()` → se JWT válido, busca `profiles`.
- Logout: `signOut()` + redirect para login.
- Não existe rota pública de cadastro profissional.

## Onboarding profissional removido

O antigo módulo `professional_onboarding` e a rota `/professional-sign-up`
foram removidos. O texto abaixo é histórico; o fluxo vigente é a criação de
acessos por administradores autorizados.

Feature: `lib/features/professional_onboarding/`.

| Tela | Função |
|------|--------|
| `ProfessionalSignUpPage` | Cadastro público de profissional autônomo ou clínica/equipe |

**Entrada pública:** link na `LoginPage` com o texto `Sou profissional, criar conta`.

**Fluxo:**

- `mode = solo`: cria clínica pessoal automaticamente
- `mode = clinic`: exige nome da clínica e aceita e-mail/telefone opcionais da clínica
- senha mínima de 8 caracteres
- após sucesso, redireciona para `/login` com mensagem `Conta criada com sucesso`

**Regra de produto atual:** o profissional criado pelo onboarding entra como `admin` da própria clínica.

## Profile e RLS

Após login, o app consulta o próprio profile:

```sql
SELECT id, clinic_id, role, full_name, email, is_active
FROM profiles WHERE id = auth.uid()
```

Demais tabelas respeitam RLS com o JWT do usuário (sem `service_role` no app).

## Navegação por role

| `profiles.role` | Home | Pacientes | Questionários | Recursos | Monitor diário |
|-----------------|------|-----------|---------------|----------|----------------|
| `admin` | `/admin` | `/admin/patients`, … | `/admin/patients/:id/questionnaires` | `/admin/patients/:id/therapy-resources` | `/admin/patients/:id/daily-monitors` |
| `psychologist` | `/psychologist` | `/psychologist/patients`, … | `/psychologist/patients/:id/questionnaires` | `/psychologist/patients/:id/therapy-resources` | `/psychologist/patients/:id/daily-monitors` |
| `patient` | `/patient` | **sem acesso** | `/patient/journey` → módulos | `/patient/resources` | `/patient/daily-monitors` |

**Resultados (somente staff):** `/admin/patients/:id/results`, `/psychologist/patients/:id/results`, detalhe `…/results/:responseId`.

Router: `go_router` + `authControllerProvider` (`lib/core/router/app_router.dart`).

Sub-rotas do staff ficam sob o prefixo da home (`/admin/...`, `/psychologist/...`).

## Módulo de pacientes (staff)

Feature: `lib/features/patients/` (`data` / `domain` / `presentation`).

| Tela | Função |
|------|--------|
| `PatientsPage` | Lista via `patients` + join em `profiles` (psicólogo e status de acesso) |
| `PatientDetailsPage` | Dados básicos + atalhos (questionários, resultados, recursos, monitores) |
| `CreatePatientPage` | Cadastro completo legado → Edge Function `create-patient` |

**Listagem:** `PatientsRepository.listPatients()` — RLS filtra por clínica e, para psychologist, só pacientes com `responsible_psychologist_id = auth.uid()`.

**Cadastro legado:** `EdgeApiClient.invoke('create-patient')` — não insere direto em `patients`/`profiles`. Admin escolhe psicólogo; psychologist envia o próprio `id` como responsável.

**Convite gradual:** o módulo de pacientes também expõe o fluxo de convite para primeiro acesso, mantendo o cadastro completo antigo por compatibilidade.

**Status exibido:** derivado de `profile_id` + `profiles.is_active` (`Ativo`, `Inativo`, `Sem acesso ao app`).

**UX:** loading, empty, error com retry, pull-to-refresh, FAB “Novo paciente”, ação `Convidar paciente` na lista e atalho no detalhe quando o paciente ainda não tem acesso ao app.

## Módulo de convites (`patient_invitations`)

Feature: `lib/features/patient_invitations/`.

| Tela | Função |
|------|--------|
| `PatientInvitationsPage` | Lista convites `pending`, `accepted`, `expired`, `revoked` |
| `CreatePatientInvitationPage` | Staff cria convite mínimo e copia o link |
| `AcceptPatientInvitationPage` | Fluxo público para senha + dados cadastrais |

**Staff:** rotas `/admin/patient-invitations` e `/psychologist/patient-invitations`, com sub-rota `/new`.

**Paciente:** rota pública `/accept-invitation?token=...`, sem JWT prévio.

**Fluxo:** `create-patient-invitation` gera um token seguro, salva somente `token_hash` e retorna `invite_url` para cópia manual. `accept-patient-invitation` valida o token, cria `auth.users`, `profiles` e `patients`, e marca o convite como `accepted`.

**Compatibilidade:** `create-patient` continua funcionando e não foi removido.

## Módulo de questionários

Feature: `lib/features/questionnaires/` (`data` / `domain` / `presentation`).

| Tela | Função |
|------|--------|
| `QuestionnairesPage` | Lista instrumentos visíveis para o contexto atual |
| `QuestionnaireIntroPage` | Orientação de `reference_period` da versão ativa antes de iniciar |
| `QuestionnaireAnswerPage` | Resposta pergunta a pergunta + progresso |
| `QuestionnaireSuccessPage` | Confirmação após `finish-questionnaire` |
| `QuestionnaireAccessManagementPage` | Admin gerencia liberação por profissional |

**Catálogo clínico:** cada card pode exibir `code`, `author_name`, `instrument_version`, `reference_period` e, para staff, `license_notes`.

**Listagem:** `QuestionnairesRepository.listVisibleQuestionnaires()` faz join na versão `active` para `reference_period` (`ReferencePeriod` em `domain/reference_period.dart`) e aplica a visibilidade por perfil:

- `admin`: vê o catálogo suportado e pode gerenciar acessos
- `psychologist`: vê apenas instrumentos liberados em `questionnaire_professional_access`
- `patient`: vê apenas instrumentos liberados para seu psicólogo responsável

**Fallback da migration `022`:** se `author_name`, `instrument_version`, `citation`, `license_notes` ou `questionnaire_professional_access` ainda não existirem no banco, o app volta para a listagem atual sem quebrar a demo.

**Fluxo (somente Edge Functions — sem insert direto em `questionnaire_responses` / `answers` / `results`):**

0. Toque no instrumento → intro (texto temporal se `last_year` / `last_month` / `lifetime`)
1. `start-questionnaire` → `QuestionnaireSession` (response_id + perguntas)
2. `submit-questionnaire-answer` a cada avanço (upsert por pergunta)
3. `finish-questionnaire` → tela de sucesso (snapshot placeholder, sem interpretação clínica)

**FH-04 — Estilos Parentais com múltiplas figuras:**

- `PARENTAL_STYLES_V1` mostra, antes do início, a seleção de figuras parentais
- opções atuais: `Mãe`, `Pai`, `Outro`
- se `Outro` for marcado, o nome da figura passa a ser obrigatório
- o app inicia a response com `contexts[]` e responde uma figura por vez
- a barra de progresso passa a ser separada por figura parental
- o envio das respostas inclui `response_context_id` apenas nesse instrumento

**Paciente:** home → **Meu plano terapêutico** (`/patient/journey`) → passo da trilha → módulo (questionários, monitor, biblioteca) ou placeholder.

**Paciente (atalho direto):** rotas `/patient/questionnaires`, `/patient/resources`, `/patient/daily-monitors` permanecem válidas.

**Staff:** detalhe do paciente → Questionários → inicia para `patient_id` do contexto.

**Admin:** home `/admin` → atalho **Acesso a questionários** → `/admin/questionnaire-access`.

**Tipos de pergunta:** `likert_scale`, `numeric_scale`, `single_choice` (escala numérica); `text` exibe aviso (API MVP só aceita `answer_value` numérico).

**UX:** loading, empty, error com retry, barra de progresso, confirmação ao sair com respostas pendentes, validação de escala.

## Módulo de trilha do paciente (`patient_journey`)

Feature: `lib/features/patient_journey/` — hub da jornada (Fase 2 do [product/master-roadmap.md](./product/master-roadmap.md)).

| Tela | Função |
|------|--------|
| `PatientJourneyPage` | Trilha vertical com 10 passos e status |
| `JourneyPlaceholderPage` | Módulos futuros ou bloqueados |

**Home paciente:** um card **Meu plano terapêutico** → `/patient/journey` (substitui três atalhos soltos na home).

**Status por passo:** `Disponível` · `Em andamento` · `Concluído` · `Em desenvolvimento` · `Bloqueado` (chips no card).

| Passo | Navegação |
|-------|-----------|
| Questionários | `/patient/questionnaires` |
| Monitor diário | `/patient/daily-monitors` |
| Biblioteca | `/patient/resources` |
| Dashboard clínico | `/patient/clinical-dashboard` |
| Objetivos da terapia | `/patient/therapy-goals` |
| Problemas | `/patient/problems` |
| Check-in | `/patient/check-ins` |
| Linha do tempo | `/patient/timeline` |
| Genograma | `/patient/genogram` |
| Mapa mental | `/patient/mental-map` |

**Progresso (leitura RLS):** `PatientJourneyRepository` agrega questionários, monitor do dia, recursos e objetivos terapêuticos.

## Módulo de objetivos da terapia (`therapy_goals`)

Feature: `lib/features/therapy_goals/` — migration `20250531170017_therapy_goals.sql`.

| Tela | Função |
|------|--------|
| `PatientTherapyGoalsPage` | Lista, criar, pull-to-refresh (paciente) |
| `StaffPatientTherapyGoalsPage` | Lista e criar pelo detalhe do paciente |
| `TherapyGoalFormPage` | Título, descrição, data alvo (staff), status (staff na edição) |
| `TherapyGoalDetailPage` | Detalhe, concluir, arquivar, editar |

**Rotas paciente:** `/patient/therapy-goals`, `…/new`, `…/:goalId`, `…/:goalId/edit`  
**Rotas staff:** `…/patients/:patientId/therapy-goals` (mesma estrutura)

**RLS:** leitura por `user_can_access_patient`; paciente cria/edita os próprios; staff CRUD nos pacientes permitidos.

**Trilha:** passo *Objetivos da terapia* → disponível (com ativos) ou concluído (só concluídos, sem ativos).

**UX:** layout em trilha (numeração + conector), legenda de status, pull-to-refresh, `AppScaffold` + cards do design system existente.

## Módulo de problemas (`patient_problems`)

Feature: `lib/features/patient_problems/` — migration `20250531180018_patient_problems.sql`.

| Tela | Função |
|------|--------|
| `PatientProblemsPage` | Lista, criar, refresh (paciente) |
| `StaffPatientProblemsPage` | Staff no detalhe do paciente |
| `PatientProblemFormPage` | Título, descrição, categoria, intensidade 0–10 |
| `PatientProblemDetailPage` | Melhorou, resolvido, arquivar, editar |

**Rotas paciente:** `/patient/problems` · **staff:** `…/patients/:patientId/problems`

**Trilha:** *Problemas* → Disponível · Em andamento · Concluído (conforme registros abertos).

## Módulo de check-in (`patient_check_ins`)

Feature: `lib/features/patient_check_ins/` — migration `20250531190019_patient_check_ins.sql`.

| Tela | Função |
|------|--------|
| `PatientCheckInsPage` | Lista, check-in de hoje em destaque, sliders |
| `StaffPatientCheckInsPage` | Histórico somente leitura |
| `PatientCheckInFormPage` | Humor, ansiedade, energia, problemas 0–10 + notas |
| `PatientCheckInDetailPage` | Detalhe; paciente edita só o de hoje |

**Rotas:** `/patient/check-ins` · staff: `…/patients/:patientId/check-ins`

**Trilha:** *Check-in* → Disponível (sem registro hoje) · Concluído (já fez hoje).

## Módulo de linha do tempo (`patient_timeline_events`)

Feature: `lib/features/patient_timeline/` — migration `20250531200020_patient_timeline_events.sql`.

| Tela | Função |
|------|--------|
| `PatientTimelinePage` | Lista cronológica, criar/editar eventos |
| `StaffPatientTimelinePage` | Histórico e CRUD pelo detalhe do paciente |
| `PatientTimelineEventFormPage` | Título, descrição, data, período, categoria, impacto 0–10, sensível |
| `PatientTimelineEventDetailPage` | Detalhe e edição |

**Rotas:** `/patient/timeline` · staff: `…/patients/:patientId/timeline`

**Trilha:** *Linha do tempo* → Disponível (sem eventos) · Em andamento (com eventos).

## Módulo de genograma (`genogram_people`, `genogram_relationships`)

Feature: `lib/features/genogram/` — migration `20250531210021_patient_genogram.sql`.

| Tela | Função |
|------|--------|
| `PatientGenogramPage` | Lista pessoas, resumo de relações, FAB pessoa, botão relação |
| `StaffPatientGenogramPage` | Mesmo fluxo para staff |
| `GenogramPersonFormPage` | Cadastro/edição de pessoa |
| `GenogramPersonDetailPage` | Detalhe + relações vinculadas |
| `GenogramRelationshipFormPage` | Pessoa A/B, tipo, notas |
| `GenogramRelationshipDetailPage` | Detalhe + editar |

**Rotas:** `/patient/genogram` · staff: `…/patients/:patientId/genogram`

**Trilha:** *Genograma* → Disponível (vazio) · Em andamento (com pessoas ou relações).

## Módulo de mapa mental (`mental_map`)

Feature: `lib/features/mental_map/` — sem migration; agrega dados via RLS dos módulos existentes.

| Tela | Função |
|------|--------|
| `PatientMentalMapPage` | Formulação visual do caso com centro clínico, camadas e síntese por módulo |
| `StaffPatientMentalMapPage` | Mesma visão no detalhe do paciente |

**Layout v3 (M1–M5):** formulação visual do caso com hub de 8 nós, tabs de camadas e bottom sheet por nó.

**Centro do mapa:** nome do paciente + resumo curto com:

- problemas ativos
- objetivos ativos
- último check-in

**Anel principal:** Esquemas · Modos · Problemas · Objetivos

**Anel contextual:** Apego · Enfrentamento · Parentais · História/Vínculos (timeline + genograma)

**Dados usados no builder `mental_case_map_builder.dart`:**

- `questionnaire_results` (via `ResultsRepository`) — YSQ, YAMI, ATTACHMENT, YCI, YRAI, PARENTAL
- `patient_problems`
- `therapy_goals`
- `patient_check_ins`
- `patient_timeline_events`
- `genogram_people`
- `genogram_relationships`
- `snapshot.contexts[]` para resumo por figura parental (`extractParentalFigureSummaries`)

**Comportamento dos nós (M1):**

- título, status preenchido/pendente, até 3 itens principais
- indicador visual (borda sólida vs tracejada + ícone)
- toque abre bottom sheet (M5), não navega direto

**Bottom sheet (M5):** título, itens, origem dos dados, última atualização, CTA para módulo relacionado.

**Tabs de formulação (M2–M4):** segmented control abaixo do hub:

| Tab | Conteúdo |
|-----|----------|
| **Núcleo** | Top esquemas YSQ, modos YAMI, problemas por intensidade, apego, enfrentamento |
| **História** | Timeline (top 5), genograma resumido, parentais por figura, apego; sensíveis mascarados |
| **Plano** | Objetivos + problemas (proximidade visual), check-ins, sparkline 7 dias, recursos |

**Domain/builders:** `mental_case_map_builder.dart`, `mental_map_hub_builder.dart`, `mental_map_clinical_core_builder.dart`, `mental_map_history_links_builder.dart`, `mental_map_therapy_plan_builder.dart`.

**Spec:** [product/mental-map-v3-spec.md](./product/mental-map-v3-spec.md) — v3 completo (M1–M5).

**Rotas:** `/patient/mental-map` · staff: `…/patients/:patientId/mental-map`

**Trilha:** *Mapa mental* → Disponível (sem dados clínicos relevantes) · Em andamento (com ao menos um dado).

Aviso fixo na tela: *Mapa mental em construção. Esta visão organiza informações registradas, mas não substitui avaliação clínica.* Sem IA, sem inferência automática de relações e sem interpretação clínica automática.

## Módulo de dashboard clínico (`clinical_dashboard`)

Feature: `lib/features/clinical_dashboard/` — sem migration; lê `questionnaire_results.snapshot` via `ResultsRepository`.

| Tela | Função |
|------|--------|
| `DashboardHomePage` | **v3 fatia 1:** visão executiva do caso (D1) + estilos parentais por figura (D3) + detalhes colapsáveis por instrumento |
| `PatientClinicalDashboardPage` | Wrapper paciente do dashboard home |
| `StaffPatientClinicalDashboardPage` | Mesmo painel no detalhe do paciente |

**Visão executiva (D1 — v3):**

- Header com nome do paciente, última atualização clínica, KPIs (problemas, objetivos, resultados, check-in)
- Grid de prioridades: top 3 YSQ, top 3 YAMI, apego, enfrentamento (YCI/YRAI)
- Sinais recentes: check-in, eventos da timeline, problemas mais intensos
- Callouts orientativos (sem interpretação clínica): instrumentos pendentes, check-in ausente

**Estilos parentais (D3 — v3):**

- Lê `snapshot.contexts[]` (`parental-context-v1`) da última resposta `PARENTAL_STYLES_V1`
- Chips por figura (Mãe, Pai, Outro/label informado)
- Top scores, contagem de itens respondidos e resumo por figura

**Detalhes por instrumento:** seção colapsável com barras completas YSQ · YAMI · Apego · YCI · YRAI (compatível com v1.1).

**Estado atual:** YSQ, YAMI, `ATTACHMENT_STYLES_V1`, `YCI_FOUNDATION_V1`, `YRAI_FOUNDATION_V1` e `PARENTAL_STYLES_V1` usam painéis reais. Personalidade continua placeholder.

**Domain/builders:** `clinical_case_summary_builder.dart`, `clinical_parental_dashboard_builder.dart`, `clinical_dashboard_callouts.dart`.

**Spec:** [product/dashboard-v3-spec.md](./product/dashboard-v3-spec.md)

**Rotas:** `/patient/clinical-dashboard` · staff: `…/patients/:patientId/clinical-dashboard`

**Trilha (passo *Dashboard clínico*):** Disponível sem resultados YSQ/YAMI · Em andamento com ao menos um.

Aviso: *Dashboard em validação clínica. Use como apoio visual, não como diagnóstico.*

## Módulo de relatório clínico PDF (`clinical_reports`)

Feature: `lib/features/clinical_reports/` — somente **staff** (admin/psicólogo).

| Componente | Função |
|------------|--------|
| `ClinicalReportOptionsPage` | Seleção de seções + geração |
| `ClinicalReportRepository` | `POST generate-clinical-report` → bytes PDF |

**Rota:** `/{admin\|psychologist}/patients/:patientId/clinical-report`  
**Entrada no detalhe do paciente:** card *Gerar relatório*.

PDF gerado na Edge Function (`pdf-lib`); aviso de uso supervisionado; sem IA nem interpretação automática. Após gerar: salva em temp e abre com `open_filex`.

## Módulo de resultados (staff)

Feature: `lib/features/results/` (`data` / `domain` / `providers` / `presentation`).

| Tela | Função |
|------|--------|
| `PatientResultsPage` | Lista `questionnaire_responses` do paciente (RLS) |
| `PatientResultDetailsPage` | Resposta, snapshot MVP ou apuração DEMO (`scoring-demo-1`), perguntas/respostas |

**Leitura:** `ResultsRepository` via PostgREST — `questionnaire_responses`, `questionnaire_answers`, `questionnaire_results`, `questions` (sem insert/update).

**Acesso:** admin (clínica) e psychologist (seus pacientes). Paciente **não** acessa nesta etapa.

**Listagem:** questionário, status, data de conclusão, quantidade de respostas, indicador de resultado.

**Detalhe:** dados da response, `snapshot` JSONB por categoria, lista de perguntas com rótulos Likert legíveis.

**FH-04:** quando o snapshot vier com `contexts[]` (`parental-context-v1`), o detalhe exibe seções separadas por figura parental sem alterar o dashboard.

- **`version: scoring-demo-1`:** exibe apuração estruturada (resumo, domínios, esquemas, itens). Banner por `questionnaire.code` (`ResultStructuredDisclaimer`):
  - `MVP_DEMO` → “Resultado demonstrativo, sem validade clínica oficial.”
  - `YSQ_FOUNDATION_V1` → “Resultado estruturado para validação clínica…” (interpretação pelo psicólogo)
  - `YAMI_MODES_FOUNDATION_V1` → “Resultado estruturado de modos esquemáticos para validação clínica…”
  - `ATTACHMENT_STYLES_V1` → “Resultado estruturado por estilo de apego para validação clínica…”
  - demais → “Resultado estruturado. Revise as regras clínicas…”
- Modelos: `features/results/domain/scoring_*.dart`, `result_disclaimer.dart`.
- **`version: mvp-1` (ou ausente):** visualização legada por categoria (soma ponderada, itens simples).

Sem interpretação clínica textual / gráficos avançados / PDF.

**UX:** loading, empty, error, botão atualizar (refresh).

## Módulo de recursos terapêuticos

Feature: `lib/features/therapy_resources/` (`data` / `domain` / `providers` / `presentation`).

| Tela | Função |
|------|--------|
| `TherapyResourcesPage` | Staff: recursos liberados + biblioteca da clínica |
| `AssignResourceToPatientPage` | Staff: confirmar liberação para o paciente |
| `TherapyResourceDetailPage` | Detalhe (staff ou paciente) + abrir URL |
| `PatientResourcesPage` | Paciente: lista de materiais liberados |

**Leitura:** `TherapyResourcesRepository` via PostgREST — `therapy_resources`, `patient_resource_access` (RLS).

**Staff:** insert/update em `patient_resource_access` (liberar, revogar com `is_active = false`). Sem Edge Function — policies permitem staff da clínica.

**Paciente:** SELECT recursos liberados; UPDATE em `viewed_at` / `completed_at` (migration `012`).

**Status exibido:** `liberado` → `visualizado` → `concluído` (derivado de `is_active`, `viewed_at`, `completed_at`).

**Staff:** detalhe do paciente → **Recursos terapêuticos** → liberar da biblioteca ou revogar acesso.

**Paciente:** home → **Meus recursos** → abrir material (`url_launcher`) → marcar visualizado/concluído.

**UX:** loading, empty, error, pull-to-refresh, chips de status.

## Módulo de monitor diário

Feature: `lib/features/daily_monitors/` (`domain` / `data` / `providers` / `presentation`).

| Tela | Função |
|------|--------|
| `PatientDailyMonitorsPage` | Paciente: lista dos próprios registros |
| `CreateDailyMonitorPage` | Paciente: criar ou editar registro do dia |
| `DailyMonitorDetailPage` | Detalhe (paciente ou staff) |
| `PatientDailyMonitorHistoryPage` | Staff: histórico do paciente (somente leitura) |

**Colunas usadas:** `mood_notes`, `sleep_notes`, `activity_notes`, `emotion_notes` (+ `created_at` como data do registro). Intensidade e gatilhos ficam em `emotion_notes` com formato `Intensidade: N/10` e `Gatilhos: …`.

**RLS:** paciente INSERT/UPDATE no próprio `patient_id`; staff SELECT via `user_can_access_patient`. Sem Edge Function.

**Paciente:** home → **Monitor diário** → novo registro / editar apenas no dia de `created_at`.

**Staff:** detalhe do paciente → **Monitor diário** → histórico e detalhe (sem edição).

**UX:** loading, empty, error, pull-to-refresh, validação mínima, SnackBar após salvar.

## Tratamento de erros

Centralizado em `lib/core/errors/`:

| Origem | Mapeamento |
|--------|------------|
| `AuthException` | Credenciais inválidas, sessão expirada |
| `PostgrestException` | RLS (`42501`), JWT (`PGRST301`), perfil ausente (`PGRST116`) |
| Edge `{ ok: false, error }` | `mapEdgeErrorPayload` — mesmos códigos da API |
| Rede | `NETWORK_ERROR` |

UI: `userMessageFor()`, `ErrorBanner`, `AsyncStateBody` (listas).

## Sessão e navegação (estabilização MVP)

- **Router:** `RouteAccess` — cada role só acessa prefixo `/admin`, `/psychologist` ou `/patient`; cross-role redireciona para a home correta.
- **Sessão:** PKCE, `autoRefreshToken`, `refreshSession()` no splash; logout `SignOutScope.global`.
- **Expiração:** perfil/JWT inválido → logout + mensagem na tela de login (`authRedirectMessageProvider`).
- **Splash:** loading, erro com retry; login mantido montado durante `signIn`.

## Segurança no cliente

- Apenas `SUPABASE_ANON_KEY` via `--dart-define-from-file` (sem `service_role` no Flutter).
- Operações sensíveis: `create-patient`, `create-patient-invitation`, `accept-patient-invitation` e questionários (start/submit/finish) via Edge Functions.
- Recursos terapêuticos e monitor diário: PostgREST com RLS (sem bypass).

## Como rodar

```bash
cd mobile
flutter pub get
supabase start                                     # backend local
supabase functions serve                           # create-patient, patient invitations etc.

flutter run --dart-define-from-file=env.local.json
```

### Android — HTTP local

Em `android/app/src/main/AndroidManifest.xml`, no `<application>`:

```xml
android:usesCleartextTraffic="true"
```

### Testes

```bash
flutter test    # 35+ testes (domínio, rotas, erros)
```

Testes incluem: `route_access_test.dart`, `error_mapper_test.dart`, domínio por módulo.

Teste manual (staff): login admin/psychologist → **Pacientes** → detalhe → **Monitor diário** (seed inclui 1 registro do paciente teste).

Teste manual (paciente): login `paciente.login@…` → **Monitor diário** → novo registro; **Questionários** / **Meus recursos** conforme módulos anteriores.

Usuários seed: `docs/rls-test-plan.md`.

## Demo

- Checklist: [demo-checklist.md](./demo-checklist.md)
- Roteiro: [demo-script.md](./demo-script.md)
- APK debug: `flutter build apk --debug --dart-define-from-file=env.local.json`

## Próximas integrações (fora desta etapa)

- Histórico de respostas / retomar rascunho na UI.
- Deep links / recuperação de senha.
- Tema clínico e acessibilidade.
