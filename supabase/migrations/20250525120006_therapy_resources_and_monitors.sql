-- =============================================================================
-- Migration 006: recursos terapêuticos, liberação ao paciente e monitor diário
-- =============================================================================

-- -----------------------------------------------------------------------------
-- therapy_resources — materiais da clínica (base para mapa mental / conteúdo)
-- -----------------------------------------------------------------------------

CREATE TABLE public.therapy_resources (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  title       TEXT NOT NULL,
  type        public.therapy_resource_type NOT NULL DEFAULT 'other',
  description TEXT,
  url         TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT therapy_resources_title_not_empty CHECK (char_length(trim(title)) > 0)
);

COMMENT ON TABLE public.therapy_resources IS
  'Recursos terapêuticos por clínica. Suporta evolução para mapa mental e biblioteca de conteúdo.';

CREATE INDEX idx_therapy_resources_clinic_id ON public.therapy_resources (clinic_id);
CREATE INDEX idx_therapy_resources_clinic_type ON public.therapy_resources (clinic_id, type);

-- -----------------------------------------------------------------------------
-- patient_resource_access — liberação de recurso ao paciente pelo profissional
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_resource_access (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id              UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  resource_id             UUID NOT NULL REFERENCES public.therapy_resources (id) ON DELETE CASCADE,
  released_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  released_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  is_active               BOOLEAN NOT NULL DEFAULT true
);

COMMENT ON TABLE public.patient_resource_access IS
  'Controle de quais recursos o paciente pode acessar e quem liberou.';

CREATE INDEX idx_patient_resource_access_patient_id
  ON public.patient_resource_access (patient_id);

CREATE INDEX idx_patient_resource_access_resource_id
  ON public.patient_resource_access (resource_id);

CREATE UNIQUE INDEX idx_patient_resource_access_patient_resource
  ON public.patient_resource_access (patient_id, resource_id);

-- -----------------------------------------------------------------------------
-- daily_monitors — registro diário de humor, sono, atividade e emoções
-- -----------------------------------------------------------------------------

CREATE TABLE public.daily_monitors (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id       UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id      UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  mood_notes      TEXT,
  sleep_notes     TEXT,
  activity_notes  TEXT,
  emotion_notes   TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.daily_monitors IS
  'Monitoramento diário do paciente. Texto livre no MVP; métricas estruturadas podem ser adicionadas depois.';

CREATE INDEX idx_daily_monitors_clinic_id ON public.daily_monitors (clinic_id);
CREATE INDEX idx_daily_monitors_patient_id ON public.daily_monitors (patient_id);
CREATE INDEX idx_daily_monitors_patient_created ON public.daily_monitors (patient_id, created_at DESC);
