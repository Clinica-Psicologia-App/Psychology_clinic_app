-- Demandas terapêuticas: histórico das versões anteriores dos textos
-- (motivos e impressões, inicial e atual).
--
-- Aditiva e opcional: o app grava e lê normalmente sem esta coluna (o
-- histórico fica vazio até ela existir). RLS herdada de case_conceptualizations.
--
-- Formato: { "<campo>": [ { "text", "saved_at", "saved_by" } ] }, mais recente
-- primeiro. Campos: motivo_initial, motivo_current, impressions_initial,
-- impressions_current.

ALTER TABLE public.case_conceptualizations
  ADD COLUMN IF NOT EXISTS demands_history JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.case_conceptualizations.demands_history IS
  'Versões anteriores dos textos de Demandas terapêuticas (motivos e '
  'impressões), por campo, mais recente primeiro.';
