# Motor clínico — Terapia do Esquema

## Fonte de verdade

**Supabase / PostgreSQL** é o catálogo oficial de domínios, esquemas, versões de questionário, regras por pergunta e faixas de severidade.

Planilhas Excel **não** são fonte de verdade. Documentos de extração antigos (`questionnaires-catalog.md`, `gap-analysis.md`, etc.) são referência histórica ou checklist de conteúdo a **popular via SQL/Studio**, não via import de `.xlsx`.

## Migration

`supabase/migrations/20250531130013_scoring_engine_foundation.sql`

| Tabela | Papel |
|--------|--------|
| `schema_domains` | Domínios clínicos (`clinic_id` NULL = global) |
| `schemas` | Esquemas por domínio |
| `questionnaire_versions` | Versão do instrumento (`draft` / `active` / `archived`); `reference_period` orienta o paciente no app |
| `question_scoring_rules` | Peso, reverse, vínculo pergunta ↔ esquema/domínio |
| `severity_ranges` | Faixas `min_score` / `max_score` + `label` |

## Status

| Item | Status |
|------|--------|
| Schema + RLS + triggers | **Implementado** (migration 013) |
| Seed DEMO global (`supabase/seed.sql` §16) | **Implementado** — não é instrumento clínico validado |
| Carga YSQ planilha (`20250531140014_seed_real_ysq_foundation.sql`) | **Implementado** — `YSQ_FOUNDATION_V1`; ver [ysq-import-report.md](./ysq-import-report.md) |
| Carga YAMI modos (`20250531150015_seed_yami_modes_foundation.sql`) | **Implementado** — `YAMI_MODES_FOUNDATION_V1`; modos em `schemas`; ver [yami-import-report.md](./yami-import-report.md) |
| Período de referência (`20250531160016_questionnaire_reference_period.sql`) | **Implementado** — YSQ `last_year`, YAMI `last_month`, MVP `unspecified`; exibido no Flutter antes de iniciar |
| Cálculo DEMO (`finish-questionnaire` + `_shared/scoring/`) | **Implementado** (v1; sem interpretação clínica) |
| Flutter / dashboard | **Não alterados** |

## Seed DEMO (seção 16)

Catálogo global (`clinic_id` NULL), UUIDs fixos prefixo `66666666-…`, idempotente (`ON CONFLICT DO NOTHING`).

| Entidade | Quantidade | Observação |
|----------|------------|------------|
| `schema_domains` | 2 | `DEMO_DOMAIN_*` — fictícios |
| `schemas` | 5 | `DEMO_SCHEMA_*` — 1 por pergunta MVP |
| `questionnaire_versions` | 1 | `v1-demo` **active** em `MVP_DEMO` (`1111…1301`) |
| `question_scoring_rules` | 5 | Q01–Q05 (`1111…1501`–`1505`) |
| `severity_ranges` | 20 | 4 faixas × 5 esquemas DEMO (limiares fictícios 1–6) |

`finish-questionnaire` usa o motor DEMO quando existe `questionnaire_versions.status = active` e regras em `question_scoring_rules`. Mantém agregação legado por `question_category_items` para compatibilidade com o app Flutter.

## Multi-tenant

- **Global:** `schema_domains.clinic_id IS NULL` (e `schemas` filhos alinhados).
- **Por clínica:** `clinic_id` preenchido; visível só para usuários dessa clínica.
- **Versões de questionário:** globais por `questionnaires.id` (como o catálogo MVP).

## Testes unitários (Deno)

```bash
cd supabase/functions
deno task test:scoring
# ou: deno test _shared/scoring/ --allow-read
```

Cobre: `reverse_score`, soma ponderada, média, agrupamento schema/domain, lookup de severidade.

## Documentação

| Documento | Uso |
|-----------|-----|
| [../database-model.md](../database-model.md) | Modelo integrado ao restante do banco |
| [database-schema.md](./database-schema.md) | Detalhe das colunas e policies |
| [real-questionnaire-onboarding.md](./real-questionnaire-onboarding.md) | Plano para cadastrar o primeiro instrumento real (sem dados inventados) |
| [ysq-import-report.md](./ysq-import-report.md) | Relatório da importação YSQ-Esquemas (Excel → migration 014) |
| [yami-import-report.md](./yami-import-report.md) | Relatório YAMI-Modos (modos → `schemas`; migration 015) |
| [clinical-validation-checklist.md](./clinical-validation-checklist.md) | **Checklist de validação clínica** YSQ + YAMI (catálogo / licença) |
| [clinical-homologation.md](./clinical-homologation.md) | **Homologação** — roteiro psicólogo (responder + revisar snapshot) |
| [mvp-placeholder-only.md](./mvp-placeholder-only.md) | Comportamento atual do `finish-questionnaire` (legado) |

## Templates SQL (instrumento real)

`supabase/templates/scoring/` — scripts 01–07 com placeholders (`{{QUESTIONNAIRE_ID}}`, `{{VERSION_ID}}`, etc.). Não fazem parte do `seed`; aplicar após validação clínica.

## Próximos passos (ordem sugerida)

1. ~~Seed DEMO global~~ — feito em `seed.sql` §16.
2. ~~Motor de apuração v1~~ — `supabase/functions/_shared/scoring/` + `finish-questionnaire`.
3. ~~Plano + templates SQL~~ — [real-questionnaire-onboarding.md](./real-questionnaire-onboarding.md) + `supabase/templates/scoring/`.
4. ~~Carga inicial YSQ-Esquemas~~ — migration `014`.
5. ~~Carga YAMI modos~~ — migration `015` (`YAMI_MODES_FOUNDATION_V1`, 124 itens).
6. **Validação clínica** — preencher [clinical-validation-checklist.md](./clinical-validation-checklist.md); só então migrations de correção.
7. Homologação clínica — [clinical-homologation.md](./clinical-homologation.md) (YSQ + YAMI no app).
8. Testes de integração E2E com `edge-functions-flow.ps1` após deploy.
9. Migrar/descontinuar `question_category_items` quando o catálogo oficial estiver validado.
