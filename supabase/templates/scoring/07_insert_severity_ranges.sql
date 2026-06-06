-- =============================================================================
-- Template 07: severity_ranges
-- Pré-requisito: version (05); schemas/domains já cadastrados
-- Motor classifica pela média ponderada do grupo (ver severity.ts).
-- =============================================================================
--
-- Placeholders:
--   {{VERSION_ID}}        UUID da questionnaire_versions
--   {{SCHEMA_ID}}         UUID do esquema (recomendado) ou NULL
--   {{DOMAIN_ID}}         UUID do domínio (fallback; use NULL se escopo só schema)
--
-- Faixas devem ser validadas clinicamente (limiares do instrumento / literatura).
-- =============================================================================

INSERT INTO public.severity_ranges (
  id,
  questionnaire_version_id,
  schema_id,
  domain_id,
  label,
  min_score,
  max_score,
  color_key,
  sort_order,
  metadata
)
VALUES (
  gen_random_uuid(),
  '{{VERSION_ID}}'::uuid,
  {{SCHEMA_ID_SQL}},        -- '{{SCHEMA_ID}}'::uuid ou NULL
  {{DOMAIN_ID_SQL}},        -- '{{DOMAIN_ID}}'::uuid ou NULL
  '{{SEVERITY_LABEL}}',
  {{SEVERITY_MIN_SCORE}},
  {{SEVERITY_MAX_SCORE}},
  '{{SEVERITY_COLOR_KEY}}',  -- ex.: severity_low | severity_moderate | severity_high
  {{SEVERITY_SORT_ORDER}},
  '{}'::jsonb
);

-- Repita para cada faixa e cada esquema (ou domínio) conforme protocolo aprovado.
-- Evite sobreposição de intervalos no mesmo escopo (schema_id / domain_id).
