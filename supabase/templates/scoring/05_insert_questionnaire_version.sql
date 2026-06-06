-- =============================================================================
-- Template 05: questionnaire_versions
-- Pré-requisito: questionnaire + todas as questions cadastradas
-- =============================================================================
--
-- Placeholders:
--   {{VERSION_ID}}        UUID fixo da versão
--   {{QUESTIONNAIRE_ID}}  UUID do questionário
--
-- Regras:
--   - Apenas UMA versão status = 'active' por questionnaire_id
--   - published_at obrigatório quando status = 'active'
--   - Recomendado: começar com status = 'draft', ativar após revisão
-- =============================================================================

INSERT INTO public.questionnaire_versions (
  id,
  questionnaire_id,
  version,
  status,
  scoring_method,
  scale_min,
  scale_max,
  instructions,
  reference_period,
  published_at
)
VALUES (
  '{{VERSION_ID}}'::uuid,
  '{{QUESTIONNAIRE_ID}}'::uuid,
  '{{VERSION_LABEL}}',           -- ex.: v1.0-2025-05 (único por questionnaire, case-insensitive)
  'draft',                       -- alterar para 'active' após validação
  '{{SCORING_METHOD}}',          -- ex.: weighted_sum
  {{VERSION_SCALE_MIN}},
  {{VERSION_SCALE_MAX}},
  '{{VERSION_INSTRUCTIONS}}',    -- instruções ao paciente (texto validado)
  '{{REFERENCE_PERIOD}}',        -- unspecified | last_month | last_year | lifetime
  NULL                           -- preencher timezone('utc', now()) ao ativar
)
ON CONFLICT (id) DO NOTHING;

-- Para publicar (executar em passo separado, após homologação):
-- UPDATE public.questionnaire_versions
-- SET status = 'active',
--     published_at = timezone('utc', now())
-- WHERE id = '{{VERSION_ID}}'::uuid;
