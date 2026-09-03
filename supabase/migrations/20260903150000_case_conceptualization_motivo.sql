-- Conceitualização de caso — seção 2 "Motivo da terapia": complemento de
-- texto livre do terapeuta, além do que vem agregado do Mapa mental
-- (contexto de vida, demandas, resumo da queixa).
--
-- Aditivo à tabela existente (case_conceptualizations). RLS herdada.

ALTER TABLE public.case_conceptualizations
  ADD COLUMN motivo_notes TEXT;

COMMENT ON COLUMN public.case_conceptualizations.motivo_notes IS
  'Seção 2 — complemento do terapeuta ao motivo/queixa (texto livre).';
