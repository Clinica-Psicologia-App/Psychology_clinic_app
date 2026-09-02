-- Conceitualização de caso — seções adicionais preenchidas pelo terapeuta:
--   3  Impressões gerais (inicial/atual)
--   4  Perspectiva diagnóstica (sistema + diagnósticos)
--   13 Comentários adicionais
--
-- Aditivo à tabela existente (case_conceptualizations). RLS herdada.

ALTER TABLE public.case_conceptualizations
  -- 3 — { "initial": "...", "current": "..." }
  ADD COLUMN general_impressions JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- 4 — { "system": "CID-11" | "DSM-5-TR", "items": [ { "name", "code" } ] }
  ADD COLUMN diagnosis JSONB NOT NULL DEFAULT '{}'::jsonb,
  -- 13 — texto livre
  ADD COLUMN additional_comments TEXT;

COMMENT ON COLUMN public.case_conceptualizations.general_impressions IS
  'Seção 3 — impressões gerais { initial, current }.';
COMMENT ON COLUMN public.case_conceptualizations.diagnosis IS
  'Seção 4 — { system, items:[{name, code}] }.';
COMMENT ON COLUMN public.case_conceptualizations.additional_comments IS
  'Seção 13 — comentários/explicações adicionais.';
