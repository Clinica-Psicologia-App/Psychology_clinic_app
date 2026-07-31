-- =============================================================================
-- Migration: "Passar a régua" — validação item a item do psicólogo.
--
-- Adiciona à questionnaire_answers a nota validada pelo profissional e a
-- observação por item. A nota original do paciente (answer_value) nunca é
-- alterada; o resultado validado usa professional_value onde existir.
-- As escritas são feitas exclusivamente pela edge function (service role)
-- após verificação de acesso — sem nova policy de UPDATE para staff.
-- =============================================================================

BEGIN;

ALTER TABLE public.questionnaire_answers
  ADD COLUMN IF NOT EXISTS professional_value INTEGER,
  ADD COLUMN IF NOT EXISTS professional_note TEXT;

COMMENT ON COLUMN public.questionnaire_answers.professional_value IS
  'Nota validada pelo psicólogo ao "passar a régua" (NULL = mantém a do paciente).';
COMMENT ON COLUMN public.questionnaire_answers.professional_note IS
  'Observação do psicólogo sobre o item, registrada durante a régua.';

COMMIT;
