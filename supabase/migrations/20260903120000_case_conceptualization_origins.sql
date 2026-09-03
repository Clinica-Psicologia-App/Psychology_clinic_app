-- Conceitualização de caso — seção 7 "Origens infantis e adolescentes dos
-- problemas atuais", subseções de texto livre do terapeuta:
--   7.1 Descrição geral da história inicial
--   7.3 Possíveis fatores temperamentais/biológicos
--   7.4 Possíveis fatores culturais, étnicos e religiosos
-- (7.2 — necessidades não atendidas — já vive em unmet_needs.)
--
-- Aditivo à tabela existente (case_conceptualizations). RLS herdada.

ALTER TABLE public.case_conceptualizations
  -- { "early_history": "...", "temperament": "...", "cultural": "..." }
  ADD COLUMN origins JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.case_conceptualizations.origins IS
  'Seção 7 — { early_history (7.1), temperament (7.3), cultural (7.4) }.';
