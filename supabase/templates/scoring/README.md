# Templates SQL — catálogo do motor clínico

Arquivos **vazios de conteúdo clínico**: apenas estrutura e placeholders. Não executar no `db reset`; aplicar manualmente no Supabase após validação.

## Ordem de execução

| # | Arquivo | Tabela |
|---|---------|--------|
| 1 | `01_insert_domains.sql` | `schema_domains` |
| 2 | `02_insert_schemas.sql` | `schemas` |
| 3 | `03_insert_questionnaire.sql` | `questionnaires` |
| 4 | `04_insert_questions.sql` | `questions` |
| 5 | `05_insert_questionnaire_version.sql` | `questionnaire_versions` |
| 6 | `06_insert_scoring_rules.sql` | `question_scoring_rules` |
| 7 | `07_insert_severity_ranges.sql` | `severity_ranges` |

## Placeholders de ID (obrigatórios no plano)

| Placeholder | Uso |
|-------------|-----|
| `{{CLINIC_ID_OR_NULL}}` | `NULL` ou `'uuid'::uuid` |
| `{{DOMAIN_ID}}` | `schema_domains.id` |
| `{{SCHEMA_ID}}` | `schemas.id` |
| `{{QUESTIONNAIRE_ID}}` | `questionnaires.id` |
| `{{QUESTION_ID}}` | `questions.id` |
| `{{VERSION_ID}}` | `questionnaire_versions.id` |

Templates também usam placeholders de **texto/número** (`{{DOMAIN_CODE}}`, `{{QUESTION_TEXT}}`, etc.) — substituir por valores da planilha clínica aprovada.

Guia completo: [docs/scoring-engine/real-questionnaire-onboarding.md](../../../docs/scoring-engine/real-questionnaire-onboarding.md)
