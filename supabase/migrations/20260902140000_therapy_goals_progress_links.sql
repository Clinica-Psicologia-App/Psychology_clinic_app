-- Objetivos terapêuticos: progresso (0–100) e vínculo com esquemas/modos.
-- Usado no detalhamento da seção 12 da Conceitualização de caso e no CRUD
-- de objetivos (staff). Aditivo — não altera RLS existente.

ALTER TABLE public.therapy_goals
  ADD COLUMN progress SMALLINT NOT NULL DEFAULT 0,
  -- Esquemas/modos que o objetivo endereça: [{ "code": "...", "name": "..." }]
  ADD COLUMN linked_schemas JSONB NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.therapy_goals
  ADD CONSTRAINT therapy_goals_progress_range
    CHECK (progress BETWEEN 0 AND 100);

COMMENT ON COLUMN public.therapy_goals.progress IS
  'Progresso do objetivo em porcentagem (0–100), avaliado pela equipe.';
COMMENT ON COLUMN public.therapy_goals.linked_schemas IS
  'Esquemas/modos endereçados pelo objetivo: array de { code, name }.';
