-- =============================================================================
-- Migration 010: snapshot JSONB em questionnaire_results (finish-questionnaire MVP)
-- =============================================================================

ALTER TABLE public.questionnaire_results
  ADD COLUMN IF NOT EXISTS snapshot JSONB;

COMMENT ON COLUMN public.questionnaire_results.snapshot IS
  'Agregação inicial por categoria (JSON). Motor clínico completo virá em etapa futura.';
