-- =============================================================================
-- Template 03: questionnaires
-- Catálogo global de instrumentos (não possui clinic_id).
-- =============================================================================
--
-- Placeholders:
--   {{QUESTIONNAIRE_ID}}  UUID fixo do questionário
-- =============================================================================

INSERT INTO public.questionnaires (
  id,
  code,
  name,
  description,
  is_active
)
VALUES (
  '{{QUESTIONNAIRE_ID}}'::uuid,
  '{{QUESTIONNAIRE_CODE}}',   -- único na plataforma (lower); não usar MVP_DEMO
  '{{QUESTIONNAIRE_NAME}}',
  '{{QUESTIONNAIRE_DESCRIPTION}}',
  false  -- true somente após validação clínica e homologação
)
ON CONFLICT (id) DO NOTHING;
