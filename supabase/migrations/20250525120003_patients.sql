-- =============================================================================
-- Migration 003: pacientes
-- =============================================================================

-- -----------------------------------------------------------------------------
-- patients — dados clínicos e demográficos do paciente
-- -----------------------------------------------------------------------------

CREATE TABLE public.patients (
  id                           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id                    UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  profile_id                   UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  responsible_psychologist_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  full_name                    TEXT NOT NULL,
  email                        TEXT,
  phone                        TEXT,
  cpf                          VARCHAR(14),
  birth_date                   DATE,
  gender                       TEXT,
  relationship_status          TEXT,
  education_level              TEXT,
  occupation                   TEXT,
  country_birth                TEXT,
  state_birth                  TEXT,
  religious_orientation        TEXT,
  ethnic_group                 TEXT,
  sexual_orientation           TEXT,
  has_children                 BOOLEAN,
  created_at                   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at                   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patients_full_name_not_empty CHECK (char_length(trim(full_name)) > 0)
);

COMMENT ON TABLE public.patients IS
  'Registro clínico do paciente na clínica. profile_id liga ao perfil com role patient quando houver login.';

COMMENT ON COLUMN public.patients.responsible_psychologist_id IS
  'Psicólogo responsável (profiles.role = psychologist).';

COMMENT ON COLUMN public.patients.profile_id IS
  'Perfil de acesso do paciente; opcional até existir autenticação.';

CREATE INDEX idx_patients_clinic_id ON public.patients (clinic_id);
CREATE INDEX idx_patients_profile_id ON public.patients (profile_id);
CREATE INDEX idx_patients_responsible_psychologist_id ON public.patients (responsible_psychologist_id);

CREATE UNIQUE INDEX idx_patients_clinic_cpf
  ON public.patients (clinic_id, cpf)
  WHERE cpf IS NOT NULL;
