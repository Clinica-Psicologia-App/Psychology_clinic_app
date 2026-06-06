# Modelo de dados — Plataforma Terapia do Esquema (MVP)

Documentação da base PostgreSQL no Supabase. Reflete as migrations em `supabase/migrations/`.

## Visão geral

O modelo é **multi-tenant por clínica** (`clinics`). A maior parte dos dados operacionais carrega `clinic_id` para isolamento futuro via RLS.

**Profissionais** não têm tabela própria: `profiles` com `role` em `admin` ou `psychologist` cobre gestores e psicólogos. Pacientes têm registro em `patients` e, quando houver login, vínculo opcional a `profiles` com `role = patient`.

**Questionários** são catálogo **global** (não por clínica): mesma definição de instrumento para todas as clínicas. A aplicação ao paciente é **por clínica** em `questionnaire_responses`.

---

## Tabelas e objetivo

| Tabela | Objetivo |
|--------|----------|
| `clinics` | Tenant: identidade da clínica e raiz de isolamento. Também suporta clínica pessoal (`clinic_type`) e perfil proprietário (`owner_profile_id`). |
| `profiles` | Usuários da plataforma por clínica (admin, psychologist, patient). Armazena `crp` para profissionais quando aplicável. |
| `patients` | Dados clínicos/demográficos do paciente e vínculo com psicólogo responsável. |
| `patient_invitations` | Convites mínimos para primeiro acesso do paciente. |
| `questionnaires` | Instrumentos padronizados (código, nome, ativo, metadados clínicos). |
| `questionnaire_professional_access` | Liberação de instrumentos por profissional dentro da clínica. |
| `question_categories` | Dimensões de apuração (esquemas, modos, fatores). |
| `questions` | Itens do instrumento, ordem e tipo de resposta. |
| `question_category_items` | Peso de cada pergunta em cada categoria (matriz do motor). |
| `questionnaire_responses` | Sessão de aplicação do questionário a um paciente. |
| `questionnaire_response_contexts` | Contextos múltiplos de uma mesma aplicação, como figuras parentais. |
| `questionnaire_answers` | Valor respondido por pergunta. |
| `questionnaire_results` | Scores calculados por categoria (preenchidos pelo motor). |
| `therapy_resources` | Materiais da clínica (artigos, vídeos, exercícios, links). |
| `patient_resource_access` | Liberação de recurso ao paciente por um profissional. |
| `daily_monitors` | Registro diário (humor, sono, atividade, emoções). |
| `therapy_goals` | Objetivos terapêuticos do paciente (`active`, `completed`, `archived`). |
| `patient_problems` | Problemas/queixas (`active`, `improved`, `resolved`, `archived`; intensidade 0–10). |
| `patient_check_ins` | Check-ins rápidos (escalas 0–10; paciente edita só o de hoje). |
| `patient_timeline_events` | Eventos da linha do tempo (data/período, impacto 0–10, sensível). |
| `genogram_people` | Pessoas do genograma do paciente. |
| `genogram_relationships` | Relações entre pessoas do genograma (`person_a` ≠ `person_b`). |
| `schema_domains` | Domínios clínicos oficiais (global ou por clínica). |
| `schemas` | Esquemas mal-adaptativos vinculados a um domínio. |
| `questionnaire_versions` | Versão publicada de um instrumento (regras, escala, instruções, período de referência). |
| `question_scoring_rules` | Mapeamento pergunta ↔ esquema/domínio, peso, reverse. |
| `severity_ranges` | Faixas de severidade por versão (e opcional esquema/domínio). |

> **Motor clínico (migration `013`):** catálogo no Postgres. `finish-questionnaire` aplica motor DEMO v1 quando há versão `active` + regras; legado `question_category_items` permanece no snapshot para o app Flutter.

---

## Relacionamentos principais

```mermaid
erDiagram
  clinics ||--o{ profiles : has
  clinics ||--o{ patients : has
  clinics ||--o{ patient_invitations : has
  clinics ||--o{ therapy_resources : has
  clinics ||--o{ questionnaire_responses : has
  clinics ||--o{ daily_monitors : has
  profiles ||--o{ clinics : owns_optional

  profiles ||--o| patients : "profile_id optional"
  profiles ||--o{ patients : "responsible_psychologist"
  profiles ||--o{ patient_invitations : invites
  profiles ||--o{ patient_resource_access : releases

  patients ||--o{ questionnaire_responses : answers
  patients ||--o{ patient_resource_access : accesses
  patients ||--o{ daily_monitors : logs
  patients ||--o{ therapy_goals : goals
  patients ||--o{ patient_problems : problems
  patients ||--o{ patient_check_ins : check_ins
  patients ||--o{ patient_timeline_events : timeline
  patients ||--o{ genogram_people : genogram_people
  patients ||--o{ genogram_relationships : genogram_relationships

  questionnaires ||--o{ question_categories : contains
  questionnaires ||--o{ questions : contains
  questionnaires ||--o{ questionnaire_responses : applied
  questionnaire_responses ||--o{ questionnaire_response_contexts : contextualizes
  questionnaires ||--o{ questionnaire_professional_access : enabled_for

  questions ||--o{ question_category_items : weighted_in
  question_categories ||--o{ question_category_items : aggregates

  questionnaire_responses ||--o{ questionnaire_answers : has
  questionnaire_responses ||--o{ questionnaire_results : produces
  questionnaire_response_contexts ||--o{ questionnaire_answers : scopes
  profiles ||--o{ questionnaire_professional_access : granted_to
  clinics ||--o{ questionnaire_professional_access : scoped

  questions ||--o{ questionnaire_answers : answered
  question_categories ||--o{ questionnaire_results : scored

  therapy_resources ||--o{ patient_resource_access : granted

  schema_domains ||--o{ schemas : contains
  questionnaires ||--o{ questionnaire_versions : versions
  questionnaire_versions ||--o{ question_scoring_rules : rules
  questionnaire_versions ||--o{ severity_ranges : severities
  questions ||--o{ question_scoring_rules : scored
  schemas ||--o{ question_scoring_rules : optional
  schema_domains ||--o{ question_scoring_rules : optional
```

### Chaves e enums

- **PK**: `UUID` com `gen_random_uuid()` em todas as tabelas.
- **`profile_role`**: `admin`, `psychologist`, `patient`.
- **`questionnaire_response_status`**: `draft`, `completed`, `cancelled`.
- **`question_answer_type`**: `likert_scale`, `numeric_scale`, `single_choice`, `text`.
- **`therapy_resource_type`**: `article`, `video`, `exercise`, `document`, `link`, `other`.
- **`questionnaire_version_status`**: `draft`, `active`, `archived`.

### Motor clínico — catálogo oficial (`013`)

| Tabela | Escopo `clinic_id` | Unicidade principal |
|--------|-------------------|---------------------|
| `schema_domains` | `NULL` = global; UUID = clínica | `code` único por escopo |
| `schemas` | Alinhado ao domínio (trigger) | `(domain_id, code)` |
| `questionnaire_versions` | Global (por `questionnaire_id`) | `(questionnaire_id, version)`; 1× `active` por instrumento; `reference_period` para orientação pré-resposta |
| `question_scoring_rules` | Via versão global | `(questionnaire_version_id, question_id)` |
| `severity_ranges` | Via versão global | — |

**RLS:** leitura para usuários autenticados da clínica (global + linhas da clínica); escrita de catálogo apenas **admin** (global ou da própria clínica em `schema_domains` / `schemas`).

**Coexistência com MVP:** `question_category_items` continua alimentando o placeholder de `finish-questionnaire` até migração do motor.

### Integridade entre tabelas

Regras que exigem leitura de outras linhas (mesma clínica, mesmo questionário) estão em **triggers** (`20250525120008_cross_table_integrity_triggers.sql`), pois `CHECK` no PostgreSQL não aceita subquery.

## Onboarding de profissional com clínica opcional (`024`)

O sistema continua exigindo `clinic_id` não nulo em `profiles`, mas agora o onboarding público pode criar a clínica automaticamente quando o profissional atua sozinho.

Campos adicionados:

- `clinics.clinic_type` — `clinic` ou `personal`
- `clinics.owner_profile_id` — perfil dono/criador da clínica
- `profiles.crp` — registro profissional opcional

Regras principais da migration `024_professional_onboarding_support.sql`:

- `clinic_id` permanece obrigatório em `profiles`
- `mode = solo` cria uma clínica pessoal automaticamente
- `mode = clinic` cria uma clínica tradicional com os dados informados
- o profissional criado pelo fluxo público entra como `admin` da clínica criada

**Compatibilidade**

Clínicas existentes continuam válidas com `clinic_type = clinic` por padrão. O fluxo novo não altera o login existente nem o onboarding por convite do paciente.

---

## Fluxo dos questionários

### Contextos por figura parental (`025`)

`questionnaire_response_contexts` permite repetir o mesmo conjunto de perguntas dentro de uma única `questionnaire_response`, preservando progresso e snapshot separados por contexto.

Uso atual do FH-04:

- `context_type = parental_figure`
- `context_key = mother | father | other`
- `context_label` guarda o nome visível da figura (`Mãe`, `Pai`, `Avó`, etc.)
- `questionnaire_answers.response_context_id` aponta para o contexto quando o instrumento exige múltiplas figuras

Regras principais da migration `025_questionnaire_response_contexts.sql`:

- `UNIQUE (response_id, context_type, context_key, context_label)`
- `response_context_id` em `questionnaire_answers` é opcional para compatibilidade com respostas antigas
- respostas sem contexto continuam válidas para YSQ, YAMI e demais instrumentos
- para `context_key = other`, `context_label` precisa ser preenchido com o nome real da figura
- triggers validam coerência entre contexto, response, paciente, questionário e clínica

**RLS**

- staff e paciente acessam contexts se já puderem acessar a `questionnaire_response`
- isolamento continua por `clinic_id`

**Compatibilidade**

O FH-04 não altera YSQ/YAMI. O uso atual é direcionado a `PARENTAL_STYLES_V1`, com progresso e snapshot separados por figura parental.

### Catálogo clínico e acesso por profissional (`022`)

`questionnaires` continua sendo um catálogo global, mas agora também pode carregar metadados clínicos exibidos no app:

- `author_name`
- `instrument_version`
- `citation`
- `license_notes`

Quando a clínica quiser restringir visibilidade por profissional, a tabela `questionnaire_professional_access` registra a liberação por `clinic_id`, `questionnaire_id` e `professional_id`.

Regras principais da migration `022_questionnaire_catalog_access.sql`:

- `UNIQUE (questionnaire_id, professional_id)`
- `professional_id` deve apontar para `profiles.role in ('admin', 'psychologist')`
- `clinic_id` deve coincidir com a clínica do profissional
- `granted_by`, quando informado, deve pertencer à mesma clínica
- `is_enabled = false` preenche `revoked_at` automaticamente
- `is_enabled = true` limpa `revoked_at`

**RLS**

- `admin`: gerencia acessos apenas da própria clínica
- `psychologist`: consulta apenas os próprios acessos
- `patient`: sem acesso direto à tabela

**Compatibilidade**

O app Flutter mantém fallback para ambientes em que a migration `022` ainda não foi aplicada. Nesses casos, a listagem de questionários volta ao comportamento anterior, sem filtro por profissional e sem quebrar a demo.

## Fluxo de convite e primeiro acesso (`023`)

`patient_invitations` permite um onboarding gradual: o profissional cria apenas um convite mínimo e o paciente define a senha e completa o próprio cadastro no primeiro acesso.

Campos-chave:

- `invited_by`
- `responsible_psychologist_id`
- `email`
- `token_hash`
- `status`
- `expires_at`
- `accepted_at`
- `patient_profile_id`
- `patient_id`

Regras principais da migration `023_patient_invitations.sql`:

- índice único parcial por `(clinic_id, lower(email))` quando `status = 'pending'`
- `invited_by` deve ser `admin` ou `psychologist` da mesma clínica
- `responsible_psychologist_id` deve ser `admin` ou `psychologist` da mesma clínica
- `expires_at` deve estar no futuro enquanto o convite estiver `pending`
- o token puro nunca é salvo no banco; apenas `token_hash` em SHA-256

**RLS**

- `admin`: vê e gerencia convites da própria clínica
- `psychologist`: vê e gerencia convites sob sua responsabilidade
- `patient`: sem acesso direto à tabela

**Compatibilidade**

O fluxo legado `create-patient` continua ativo. O convite não substitui imediatamente o cadastro completo; ele passa a coexistir como caminho preferencial para primeiro acesso.

1. **Cadastro do instrumento** (admin da plataforma / seed futuro)
   - Criar `questionnaires`.
   - Criar `question_categories` e `questions`.
   - Popular `question_category_items` (pergunta ↔ categoria + `weight`).

2. **Abertura da aplicação**
   - Inserir `questionnaire_responses` com `status = draft`, `clinic_id`, `patient_id`, `questionnaire_id`.
   - Opcional: preencher `started_at`.

3. **Preenchimento**
   - Para cada pergunta respondida: `INSERT`/`UPDATE` em `questionnaire_answers` (`response_id`, `question_id`, `answer_value`).
   - Uma linha por pergunta por resposta (índice único `response_id + question_id`).

4. **Conclusão**
   - Atualizar `questionnaire_responses`: `status = completed`, `completed_at = now()`.
   - Disparar motor de apuração (etapa futura) → gravar `questionnaire_results`.

5. **Cancelamento**
   - `status = cancelled` sem exigir `completed_at`.

```text
questionnaires
    ├── question_categories
    ├── questions
    │       └── question_category_items (pesos)
    └── questionnaire_responses (por clinic + patient)
            ├── questionnaire_answers
            └── questionnaire_results (após apuração)
```

---

## Fluxo do motor de apuração (planejado, não implementado)

O schema já suporta o pipeline; a **lógica de cálculo** fica para uma função/Edge Function/job posterior.

### Entradas

- `questionnaire_answers.answer_value` para o `response_id` concluído.
- `question_category_items` (`question_id`, `category_id`, `weight`).
- Metadados da pergunta (`scale_min`, `scale_max`, `answer_type`) se necessário para normalização.

### Processamento esperado (por categoria)

Para cada `category_id` do `questionnaire_id`:

1. Listar itens em `question_category_items` da categoria.
2. Buscar respostas correspondentes em `questionnaire_answers`.
3. Calcular agregados, por exemplo:
   - `total_score` = Σ (`answer_value` × `weight`)
   - `average_score` = média ponderada ou simples (regra a validar por instrumento)
   - `percentage` = normalização em relação ao máximo teórico da categoria
4. Derivar `classification` (faixas: baixo / moderado / elevado) conforme tabela de cortes do instrumento.

### Saída

- Um registro em `questionnaire_results` por (`response_id`, `category_id`).
- Índice único evita duplicar resultado da mesma categoria na mesma sessão.

### Uso downstream

- **Dashboard**: agregar `questionnaire_results` por paciente, período e categoria.
- **Mapa mental** (futuro): pode mapear `question_categories.code` para nós/arestas; `therapy_resources` e `patient_resource_access` para conteúdo vinculado ao plano terapêutico.

---

## Autenticação e perfis

### Vínculo `auth.users` ↔ `profiles`

- `profiles.id` é **igual** a `auth.users.id` (FK `profiles_id_fkey_auth_users`, `ON DELETE CASCADE`).
- Login via **Supabase Auth** (e-mail/senha); sem auth customizado no app.
- No signup (ou criação via Dashboard/Admin API), enviar em `raw_user_meta_data`:
  - `clinic_id` (UUID da clínica)
  - `role` (`admin` | `psychologist` | `patient`)
  - `full_name` (opcional)
  - `phone` (opcional)

### Trigger `handle_new_user`

Após `INSERT` em `auth.users`, cria ou atualiza a linha em `profiles` com o mesmo `id`. Se faltar `clinic_id` ou `role`, o usuário auth existe mas **sem profile** — não acessa dados clínicos (RLS nega).

`handle_user_email_updated` mantém `profiles.email` alinhado ao Auth.

### Seed de desenvolvimento

`supabase/seed.sql` insere `auth.users` + `auth.identities` com UUIDs fixos; profiles são criados pelo trigger. Senha de teste local: `TesteMVP2025!`.

---

## RLS e segurança

RLS está **habilitado** em todas as tabelas públicas. Policies na migration `20250525120009_auth_and_rls.sql`.

### Funções auxiliares (`SECURITY DEFINER`)

| Função | Uso |
|--------|-----|
| `current_clinic_id()` | Tenant do usuário logado |
| `current_role()` | `admin`, `psychologist` ou `patient` |
| `current_patient_id()` | `patients.id` quando `profile_id = auth.uid()` |
| `is_staff()` | admin ou psychologist |
| `user_can_access_patient(uuid)` | Regra central de acesso a paciente |
| `user_can_access_response(uuid)` | Via `questionnaire_responses` + paciente |

Todas usam `auth.uid()` e leem `profiles` com bypass controlado de RLS.

### Matriz de acesso (resumo)

| Papel | Escopo |
|-------|--------|
| **admin** | Todos os dados da **própria clínica** (`clinic_id`) |
| **psychologist** | Pacientes com `responsible_psychologist_id = auth.uid()` e vínculos derivados (respostas, monitors, etc.) |
| **patient** | Apenas **próprio** registro em `patients` e dados ligados (`profile_id = auth.uid()`) |

**Cross-tenant:** bloqueado — toda policy compara `clinic_id` com `current_clinic_id()`.

**Questionários** (`questionnaires`, `questions`, …): catálogo global; **SELECT** para qualquer usuário autenticado com profile ativo. Escrita de catálogo não exposta ao cliente (sem policy INSERT/UPDATE).

**therapy_resources:** staff da clínica gerencia; paciente só **SELECT** em recursos com `patient_resource_access` ativo.

**questionnaire_results:** leitura via acesso à response; **INSERT/UPDATE** apenas staff (motor de apuração futuro).

`service_role` continua bypassando RLS (apenas backend/jobs).

---

## Convenções técnicas

- Timestamps em **UTC** (`timezone('utc', now())`).
- `updated_at` automático via trigger `set_updated_at()`.
- Índices em `clinic_id`, `patient_id`, `questionnaire_id` onde aplicável, além de índices compostos para listagens comuns.

---

## Migrations (ordem)

| Arquivo | Conteúdo |
|---------|----------|
| `20250525120001_extensions_and_enums.sql` | Extensões, enums, `set_updated_at()` |
| `20250525120002_clinics_and_profiles.sql` | Clínicas e perfis |
| `20250525120003_patients.sql` | Pacientes |
| `20250525120004_questionnaires.sql` | Questionários, categorias, perguntas, pesos |
| `20250525120005_questionnaire_responses.sql` | Respostas, answers, results |
| `20250525120006_therapy_resources_and_monitors.sql` | Recursos e monitor diário |
| `20250525120007_triggers_and_rls_prep.sql` | `updated_at` + enable RLS |
| `20250525120008_cross_table_integrity_triggers.sql` | Validações entre tabelas |
| `20250525120009_auth_and_rls.sql` | FK auth, triggers, helpers e policies RLS |

Aplicar com Supabase CLI: `supabase db push` ou `supabase migration up` no projeto vinculado.
