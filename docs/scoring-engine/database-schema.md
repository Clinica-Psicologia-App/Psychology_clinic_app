# Schema do motor clínico (migration 013)

Referência das tabelas criadas em `20250531130013_scoring_engine_foundation.sql`.

## `schema_domains`

| Coluna | Tipo | Notas |
|--------|------|--------|
| `id` | UUID PK | |
| `clinic_id` | UUID FK → `clinics`, nullable | `NULL` = catálogo global |
| `code` | TEXT | Único por escopo (global ou por clínica) |
| `name` | TEXT | |
| `description` | TEXT | |
| `sort_order` | INTEGER ≥ 0 | |
| `is_active` | BOOLEAN | |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

## `schemas`

| Coluna | Tipo | Notas |
|--------|------|--------|
| `id` | UUID PK | |
| `domain_id` | UUID FK → `schema_domains` | |
| `clinic_id` | UUID FK → `clinics`, nullable | Deve alinhar ao domínio (trigger) |
| `code` | TEXT | Único por `(domain_id, code)` |
| `name` | TEXT | |
| `description` | TEXT | |
| `sort_order` | INTEGER | |
| `is_active` | BOOLEAN | |

## `questionnaire_versions`

| Coluna | Tipo | Notas |
|--------|------|--------|
| `id` | UUID PK | |
| `questionnaire_id` | UUID FK → `questionnaires` | |
| `version` | TEXT | Único por questionário |
| `status` | `questionnaire_version_status` | `draft`, `active`, `archived` |
| `scoring_method` | TEXT | Ex.: `weighted_sum` (livre até padronizar) |
| `scale_min` / `scale_max` | INTEGER | Escala default da versão |
| `instructions` | TEXT | Instruções ao paciente |
| `reference_period` | TEXT | Janela temporal para orientação no app (`unspecified`, `last_month`, `last_year`, `lifetime`); **não** entra no motor |
| `published_at` | TIMESTAMPTZ | Obrigatório se `status = active` |
| `created_at` / `updated_at` | TIMESTAMPTZ | |

Índice parcial: no máximo **uma** versão `active` por `questionnaire_id`.

**Períodos configurados (migration 016):**

| `questionnaires.code` | `reference_period` |
|-----------------------|-------------------|
| `YSQ_FOUNDATION_V1` | `last_year` |
| `YAMI_MODES_FOUNDATION_V1` | `last_month` |
| `MVP_DEMO` | `unspecified` |
| Futuro `ESTILOS_PARENTAIS_FOUNDATION_V1` | `lifetime` (quando importado) |

## `question_scoring_rules`

| Coluna | Tipo | Notas |
|--------|------|--------|
| `id` | UUID PK | |
| `questionnaire_version_id` | UUID FK | |
| `question_id` | UUID FK | Mesmo `questionnaire_id` da versão |
| `schema_id` | UUID FK, nullable | |
| `domain_id` | UUID FK, nullable | Deve bater com `schemas.domain_id` se ambos setados |
| `weight` | NUMERIC | Default 1, > 0 |
| `reverse_score` | BOOLEAN | Default false |
| `min_value` / `max_value` | NUMERIC | Override opcional por item |
| `sort_order` | INTEGER | |
| `metadata` | JSONB | Extensões futuras |

Único: `(questionnaire_version_id, question_id)`.

## `severity_ranges`

| Coluna | Tipo | Notas |
|--------|------|--------|
| `id` | UUID PK | |
| `questionnaire_version_id` | UUID FK | |
| `schema_id` | UUID FK, nullable | Escopo da faixa |
| `domain_id` | UUID FK, nullable | |
| `label` | TEXT | Ex.: Baixo, Moderado, Alto |
| `min_score` / `max_score` | NUMERIC | Intervalo inclusivo (validar na implementação) |
| `color_key` | TEXT | UI futura |
| `sort_order` | INTEGER | |
| `metadata` | JSONB | |

## RLS (resumo)

| Operação | `schema_domains` / `schemas` | `questionnaire_versions` + regras + faixas |
|----------|------------------------------|--------------------------------------------|
| SELECT | Autenticado; global + sua clínica | Autenticado com `current_clinic_id()` |
| INSERT/UPDATE/DELETE | Admin; global ou sua clínica | Admin (catálogo plataforma) |

Funções: `scoring_row_visible_to_current_clinic`, `scoring_admin_can_manage_row`.

## Seed DEMO (seção 16 de `supabase/seed.sql`)

**Aviso:** conteúdo fictício para validar estrutura e RLS. Não substitui YSQ/SMI nem domínios oficiais da Terapia do Esquema.

| Tabela | IDs fixos (prefixo `66666666-6666-6666-6666-`) |
|--------|--------------------------------------------------|
| `schema_domains` | `…6601` Desconexão/Rejeição; `…6602` Orientação ao outro |
| `schemas` | `…6701`–`…6705` (Abandono, Desconfiança, Exclusão social, Aprovação, Controle emocional) |
| `questionnaire_versions` | `…6801` — `questionnaire_id` = `11111111-1111-1111-1111-111111111301` (`MVP_DEMO`), `version` = `v1-demo`, `status` = `active` |
| `question_scoring_rules` | `…6901`–`…6905` → perguntas `11111111-…1501`–`1505` |
| `severity_ranges` | `…6B01`–`…6B04`, `…6B11`–`…6B14`, … `…6B41`–`…6B44` (4 níveis por esquema) |

Todos os registros usam `clinic_id` NULL (global). `metadata.demo = true` nas regras e faixas.

## Legado MVP (inalterado)

- `question_categories`, `question_category_items`, `questionnaire_results`
- `finish-questionnaire` usa estas tabelas quando há versão `active` + regras; mantém `question_category_items` no snapshot para o app Flutter
