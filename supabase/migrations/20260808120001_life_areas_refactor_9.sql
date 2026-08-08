-- =============================================================================
-- Refatoração das áreas de vida: 12 → 9 (conforme especificação do cliente).
--
-- Áreas RENOMEADAS (dados do paciente preservados):
--   health_fitness          → physical_health    (Saúde Física)
--   mental_emotional_health → emotional_health   (Saúde Emocional)
--
-- Áreas REMOVIDAS (sem mapeamento; dados descartados — MVP):
--   finances_money, personal_growth, recreation_fun,
--   physical_environment, contribution_social, spirituality
--
-- Áreas NOVAS (sem dados anteriores):
--   alone_time, self_care, routine_organization
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. patient_life_areas
-- Remove o constraint ANTES dos UPDATEs para evitar violação durante a renomeação.
-- -----------------------------------------------------------------------------

ALTER TABLE public.patient_life_areas
  DROP CONSTRAINT patient_life_areas_area_key_valid;

UPDATE public.patient_life_areas
  SET area_key = 'physical_health'
  WHERE area_key = 'health_fitness';

UPDATE public.patient_life_areas
  SET area_key = 'emotional_health'
  WHERE area_key = 'mental_emotional_health';

DELETE FROM public.patient_life_areas
  WHERE area_key IN (
    'finances_money',
    'personal_growth',
    'recreation_fun',
    'physical_environment',
    'contribution_social',
    'spirituality'
  );

ALTER TABLE public.patient_life_areas
  ADD CONSTRAINT patient_life_areas_area_key_valid CHECK (area_key IN (
    'work_career',           -- Trabalho ou Estudos
    'love_romance',          -- Relacionamento Amoroso
    'family',                -- Família
    'friends',               -- Amigos
    'alone_time',            -- Tempo para mim
    'physical_health',       -- Saúde Física
    'emotional_health',      -- Saúde Emocional
    'self_care',             -- Autocuidado
    'routine_organization'   -- Rotina e Organização
  ));

-- -----------------------------------------------------------------------------
-- 2. patient_life_area_notes (comentários clínicos do terapeuta)
-- -----------------------------------------------------------------------------

ALTER TABLE public.patient_life_area_notes
  DROP CONSTRAINT patient_life_area_notes_area_key_valid;

UPDATE public.patient_life_area_notes
  SET area_key = 'physical_health'
  WHERE area_key = 'health_fitness';

UPDATE public.patient_life_area_notes
  SET area_key = 'emotional_health'
  WHERE area_key = 'mental_emotional_health';

DELETE FROM public.patient_life_area_notes
  WHERE area_key IN (
    'finances_money',
    'personal_growth',
    'recreation_fun',
    'physical_environment',
    'contribution_social',
    'spirituality'
  );

ALTER TABLE public.patient_life_area_notes
  ADD CONSTRAINT patient_life_area_notes_area_key_valid CHECK (area_key IN (
    'work_career',
    'love_romance',
    'family',
    'friends',
    'alone_time',
    'physical_health',
    'emotional_health',
    'self_care',
    'routine_organization'
  ));
