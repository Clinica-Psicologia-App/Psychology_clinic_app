-- Bloco textual inicial para anamnese breve, contexto atual e demandas terapêuticas.

ALTER TABLE public.patients
  ADD COLUMN intake_summary TEXT,
  ADD COLUMN current_life_context TEXT,
  ADD COLUMN therapy_demands TEXT;
