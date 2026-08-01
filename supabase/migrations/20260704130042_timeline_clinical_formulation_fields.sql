-- Campos de formulacao clinica para eventos da linha do tempo.

ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS emotional_need_keys TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS emotional_need_other TEXT,
  ADD COLUMN IF NOT EXISTS emotions_felt TEXT,
  ADD COLUMN IF NOT EXISTS self_meaning TEXT,
  ADD COLUMN IF NOT EXISTS others_meaning TEXT,
  ADD COLUMN IF NOT EXISTS world_meaning TEXT,
  ADD COLUMN IF NOT EXISTS coping_keys TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS coping_other TEXT,
  ADD COLUMN IF NOT EXISTS present_influence INTEGER,
  ADD COLUMN IF NOT EXISTS present_area_keys TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS present_reaction TEXT;

ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_present_influence_range,
  ADD CONSTRAINT patient_timeline_events_present_influence_range
  CHECK (
    present_influence IS NULL
    OR (present_influence >= 0 AND present_influence <= 10)
  );

ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_emotional_need_other_required,
  ADD CONSTRAINT patient_timeline_events_emotional_need_other_required
  CHECK (
    NOT ('other' = ANY(emotional_need_keys))
    OR NULLIF(trim(COALESCE(emotional_need_other, '')), '') IS NOT NULL
  );

ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_coping_other_required,
  ADD CONSTRAINT patient_timeline_events_coping_other_required
  CHECK (
    NOT ('other' = ANY(coping_keys))
    OR NULLIF(trim(COALESCE(coping_other, '')), '') IS NOT NULL
  );

COMMENT ON COLUMN public.patient_timeline_events.period_label IS
  'Etapa da vida: infancia, adolescencia, vida adulta, maturidade ou periodo livre legado.';

COMMENT ON COLUMN public.patient_timeline_events.category IS
  'Observacoes contextuais do evento, como onde aconteceu e quem estava envolvido.';
