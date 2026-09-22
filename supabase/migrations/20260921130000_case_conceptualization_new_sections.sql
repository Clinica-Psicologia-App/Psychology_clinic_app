-- Conceitualização de caso — seções adicionais preenchidas pelo terapeuta:
--   5  Nível de funcionamento (functioning)
--   6  Problemas de vida (life_problems)
--   8  Esquemas desadaptativos centrais (central_schemas)
--   9  Modos de esquema — 9.1 Modos saudáveis, 9.2 Criança vulnerável,
--      9.3 Outros modos da criança, 9.4 Modos parentais / coping (mode_assessment)
--  12  Objetivos terapêuticos (therapy_objectives)
--
-- Aditivo à tabela existente (case_conceptualizations). RLS herdada.

ALTER TABLE public.case_conceptualizations

  -- 5 — { entries: { "<key>": { rating, explanation } } }
  --   key = domínio de funcionamento (interpessoal, sexual, trabalho…)
  ADD COLUMN functioning       JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- 6 — { main_problem, problem_list: [{ description, examples }] }
  ADD COLUMN life_problems     JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- 8 — [ { name, description } ]  (até 6 esquemas centrais)
  ADD COLUMN central_schemas   JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- 9 — { healthy_modes, vulnerable_child, other_child,
  --        parental_modes: [...], coping_modes: [...] }
  ADD COLUMN mode_assessment   JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- 12 — [ { goal, subcategories: [...], notes } ]  (até 5 objetivos)
  ADD COLUMN therapy_objectives JSONB NOT NULL DEFAULT '[]'::jsonb;


COMMENT ON COLUMN public.case_conceptualizations.functioning IS
  'Seção 5 — nível de funcionamento por domínio { entries: { key: { rating, explanation } } }.';
COMMENT ON COLUMN public.case_conceptualizations.life_problems IS
  'Seção 6 — problemas de vida { main_problem, problem_list: [{description, examples}] }.';
COMMENT ON COLUMN public.case_conceptualizations.central_schemas IS
  'Seção 8 — esquemas desadaptativos centrais [{name, description}].';
COMMENT ON COLUMN public.case_conceptualizations.mode_assessment IS
  'Seção 9 — avaliação de modos de esquema (9.1–9.4): healthy_modes, vulnerable_child, other_child, parental_modes, coping_modes.';
COMMENT ON COLUMN public.case_conceptualizations.therapy_objectives IS
  'Seção 12 — objetivos terapêuticos [{goal, subcategories, notes}].';
