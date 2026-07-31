-- =============================================================================
-- Substitui os checklists de hipóteses de esquemas e modos por campos de
-- texto livre na tabela patient_clinical_impressions.
-- As tabelas junction (patient_schema_hypotheses, patient_mode_hypotheses)
-- permanecem no banco para preservação de dados históricos.
-- =============================================================================

ALTER TABLE public.patient_clinical_impressions
  ADD COLUMN IF NOT EXISTS schema_hypotheses_text TEXT,
  ADD COLUMN IF NOT EXISTS mode_hypotheses_text   TEXT,
  ADD COLUMN IF NOT EXISTS emotional_needs_text   TEXT;

COMMENT ON COLUMN public.patient_clinical_impressions.schema_hypotheses_text IS
  'Hipóteses de esquemas em texto livre (substituiu o checklist patient_schema_hypotheses).';

COMMENT ON COLUMN public.patient_clinical_impressions.mode_hypotheses_text IS
  'Hipóteses de modos em texto livre (substituiu o checklist patient_mode_hypotheses).';

COMMENT ON COLUMN public.patient_clinical_impressions.emotional_needs_text IS
  'Necessidades emocionais percebidas em texto livre (substituiu o checklist patient_emotional_needs).';
