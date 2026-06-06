# Agregação legado vs motor DEMO

## Estado atual

`finish-questionnaire` combina:

1. **Legado (compatibilidade Flutter):** agregação por `question_categories` / `question_category_items` — campos `category_code`, `category_name`, `answer_count`, `total_weighted_score`, `average_score`, `items` (formato MVP).
2. **Motor DEMO:** quando há `questionnaire_versions.status = active` e regras em `question_scoring_rules`, preenche também `questionnaire`, `questionnaire_version`, `completed_at`, `summary`, `domains`, `schemas` e enriquece `items` com scores ajustados.

Código: `supabase/functions/_shared/scoring/` + `finish-questionnaire/index.ts`.

## Algoritmo DEMO (resumo)

```
Para cada regra em question_scoring_rules (versão active):
  adjusted = reverse(answer) se reverse_score (escala min/max da regra ou versão)
  weighted = adjusted × weight
Agrupar por schema_id e domain_id
  raw_score, weighted_score, average_score (média ponderada), max_possible_score
Classificar severidade (severity_ranges): schema_id → fallback domain_id
Snapshot version = "scoring-demo-1"
classification na linha = "pending_review" (sem interpretação clínica automática na UI)
```

## O que NÃO faz

- Interpretação clínica textual ao paciente/staff
- Instrumentos oficiais (YSQ/SMI) sem validação
- IA / PDF

## Uso permitido

- Demo de fluxo e estrutura de snapshot JSONB
- Testes de integração Edge Function

## Uso proibido

- Publicar como resultado clínico validado
- Substituir parecer de psicólogo responsável
