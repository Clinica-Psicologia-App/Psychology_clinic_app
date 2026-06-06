-- =============================================================================
-- Template 06: question_scoring_rules
-- Pré-requisito: version (05), questions (04), schemas (02)
-- Uma regra por (questionnaire_version_id, question_id).
-- =============================================================================
--
-- Placeholders:
--   {{VERSION_ID}}        UUID da questionnaire_versions
--   {{QUESTION_ID}}       UUID da pergunta
--   {{SCHEMA_ID}}         UUID do esquema (pode ser NULL se só domínio)
--   {{DOMAIN_ID}}         UUID do domínio (deve coincidir com domain do schema se ambos setados)
-- =============================================================================

INSERT INTO public.question_scoring_rules (
  id,
  questionnaire_version_id,
  question_id,
  schema_id,
  domain_id,
  weight,
  reverse_score,
  min_value,
  max_value,
  sort_order,
  metadata
)
VALUES (
  gen_random_uuid(),  -- ou UUID fixo documentado na planilha de implantação
  '{{VERSION_ID}}'::uuid,
  '{{QUESTION_ID}}'::uuid,
  {{SCHEMA_ID_SQL}},        -- '{{SCHEMA_ID}}'::uuid ou NULL
  {{DOMAIN_ID_SQL}},        -- '{{DOMAIN_ID}}'::uuid ou NULL
  {{RULE_WEIGHT}},         -- NUMERIC > 0, ex.: 1
  {{RULE_REVERSE_SCORE}},  -- true | false
  {{RULE_MIN_VALUE}},      -- NULL ou limite inferior da escala do item
  {{RULE_MAX_VALUE}},
  {{RULE_SORT_ORDER}},
  '{}'::jsonb              -- ex.: '{"source": "manual v1", "item_ref": "..."}' — sem interpretação
)
ON CONFLICT (questionnaire_version_id, question_id) DO NOTHING;

-- Repita para cada pergunta da versão.
