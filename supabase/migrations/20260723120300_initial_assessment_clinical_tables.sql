-- =============================================================================
-- Fluxo "Conhecer" — tabelas EXCLUSIVAS do terapeuta (o paciente nunca lê).
--   patient_clinical_intake      → Observações Iniciais (Bloco 1) + lente clínica do Bloco 2
--   patient_life_area_notes      → comentários clínicos por área (Bloco 3, "ao lado")
--   patient_clinical_impressions → Bloco 4 (Primeiras Impressões Clínicas)
--   patient_schema_hypotheses    → checklist de esquemas (→ schemas)
--   patient_mode_hypotheses      → checklist de modos (→ schemas sob YAMI_DOMAIN_SCHEMA_MODES)
--   patient_emotional_needs      → checklist de necessidades (→ emotional_needs)
--
-- RLS de TODAS: is_staff() AND user_can_access_patient(patient_id).
-- Nunca usar só user_can_access_patient (isso incluiria o próprio paciente).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Observações Iniciais (Bloco 1 privado) + lente clínica do Motivo da Procura (Bloco 2)
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_clinical_intake (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             UUID NOT NULL UNIQUE REFERENCES public.patients (id) ON DELETE CASCADE,
  initial_observations   TEXT, -- Bloco 1: "Observações Iniciais" (campo privado)
  main_complaint         TEXT, -- Queixa principal
  current_problem        TEXT, -- Problema atual
  precipitating_factors  TEXT, -- Fatores precipitantes
  patient_goals          TEXT, -- Objetivos do paciente
  motivation             TEXT, -- Motivação
  initial_hypotheses     TEXT, -- Hipóteses iniciais
  updated_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.patient_clinical_intake IS
  'Bloco 1 (Observações Iniciais privadas) + lente clínica do Bloco 2. Exclusivo do terapeuta.';

CREATE INDEX idx_patient_clinical_intake_patient_id ON public.patient_clinical_intake (patient_id);

CREATE TRIGGER trg_patient_clinical_intake_set_updated_at
  BEFORE UPDATE ON public.patient_clinical_intake
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Comentários clínicos por área de vida (Bloco 3 — coluna "ao lado")
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_life_area_notes (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  area_key               TEXT NOT NULL,
  clinical_comment       TEXT,
  updated_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_life_area_notes_area_key_valid CHECK (area_key IN (
    'work_career',
    'finances_money',
    'health_fitness',
    'family',
    'friends',
    'love_romance',
    'personal_growth',
    'recreation_fun',
    'physical_environment',
    'contribution_social',
    'spirituality',
    'mental_emotional_health'
  )),
  CONSTRAINT patient_life_area_notes_unique_area UNIQUE (patient_id, area_key)
);

COMMENT ON TABLE public.patient_life_area_notes IS
  'Bloco 3 — comentários clínicos do terapeuta por área de vida. Exclusivo do terapeuta.';

CREATE INDEX idx_patient_life_area_notes_patient_id ON public.patient_life_area_notes (patient_id);

CREATE TRIGGER trg_patient_life_area_notes_set_updated_at
  BEFORE UPDATE ON public.patient_life_area_notes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Bloco 4 — Primeiras Impressões Clínicas (roteiro de conceitualização de Young)
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_clinical_impressions (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             UUID NOT NULL UNIQUE REFERENCES public.patients (id) ON DELETE CASCADE,
  -- Impressão geral
  observed_temperament   TEXT,
  therapeutic_bond       TEXT,
  resources              TEXT,
  vulnerabilities        TEXT,
  -- Perspectiva diagnóstica
  hypotheses             TEXT,
  previous_diagnoses     TEXT,
  differential_diagnosis TEXT,
  -- Nível atual de funcionamento
  functioning_level      TEXT,
  -- Prioridades terapêuticas
  therapeutic_priorities TEXT,
  updated_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_clinical_impressions_functioning_level_valid
    CHECK (functioning_level IS NULL OR functioning_level IN (
      'excellent', 'good', 'moderate', 'impaired', 'severely_impaired'
    ))
);

COMMENT ON TABLE public.patient_clinical_impressions IS
  'Bloco 4 — Primeiras Impressões Clínicas (Young). Exclusivo do terapeuta. Alimenta o Mapa Mental.';

CREATE INDEX idx_patient_clinical_impressions_patient_id ON public.patient_clinical_impressions (patient_id);

CREATE TRIGGER trg_patient_clinical_impressions_set_updated_at
  BEFORE UPDATE ON public.patient_clinical_impressions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Checklists do Bloco 4 (tabelas de junção — uma linha por seleção)
-- -----------------------------------------------------------------------------

-- Hipóteses de esquemas (→ catálogo schemas)
CREATE TABLE public.patient_schema_hypotheses (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  schema_id             UUID NOT NULL REFERENCES public.schemas (id) ON DELETE CASCADE,
  created_by_profile_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_schema_hypotheses_unique UNIQUE (patient_id, schema_id)
);

COMMENT ON TABLE public.patient_schema_hypotheses IS
  'Bloco 4 — hipóteses iniciais de esquemas marcadas pelo terapeuta. Exclusivo do terapeuta.';

CREATE INDEX idx_patient_schema_hypotheses_patient_id ON public.patient_schema_hypotheses (patient_id);
CREATE INDEX idx_patient_schema_hypotheses_schema_id ON public.patient_schema_hypotheses (schema_id);

-- Hipóteses de modos (→ schemas sob o domínio de modos YAMI)
CREATE TABLE public.patient_mode_hypotheses (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  mode_id               UUID NOT NULL REFERENCES public.schemas (id) ON DELETE CASCADE,
  created_by_profile_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_mode_hypotheses_unique UNIQUE (patient_id, mode_id)
);

COMMENT ON TABLE public.patient_mode_hypotheses IS
  'Bloco 4 — hipóteses de modos marcadas pelo terapeuta (modos = schemas sob YAMI_DOMAIN_SCHEMA_MODES). Exclusivo do terapeuta.';

CREATE INDEX idx_patient_mode_hypotheses_patient_id ON public.patient_mode_hypotheses (patient_id);
CREATE INDEX idx_patient_mode_hypotheses_mode_id ON public.patient_mode_hypotheses (mode_id);

-- Necessidades emocionais percebidas (→ catálogo emotional_needs)
CREATE TABLE public.patient_emotional_needs (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  emotional_need_id     UUID NOT NULL REFERENCES public.emotional_needs (id) ON DELETE CASCADE,
  created_by_profile_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_emotional_needs_unique UNIQUE (patient_id, emotional_need_id)
);

COMMENT ON TABLE public.patient_emotional_needs IS
  'Bloco 4 — necessidades emocionais percebidas marcadas pelo terapeuta. Exclusivo do terapeuta.';

CREATE INDEX idx_patient_emotional_needs_patient_id ON public.patient_emotional_needs (patient_id);
CREATE INDEX idx_patient_emotional_needs_need_id ON public.patient_emotional_needs (emotional_need_id);

-- -----------------------------------------------------------------------------
-- RLS — TODAS staff-only: is_staff() AND user_can_access_patient(patient_id)
-- -----------------------------------------------------------------------------

ALTER TABLE public.patient_clinical_intake       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_life_area_notes       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_clinical_impressions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_schema_hypotheses     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_mode_hypotheses       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_emotional_needs       ENABLE ROW LEVEL SECURITY;

-- Helper de leitura/escrita repetido por tabela (Postgres não tem policy "template").
-- patient_clinical_intake
CREATE POLICY patient_clinical_intake_all
  ON public.patient_clinical_intake
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));

-- patient_life_area_notes
CREATE POLICY patient_life_area_notes_all
  ON public.patient_life_area_notes
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));

-- patient_clinical_impressions
CREATE POLICY patient_clinical_impressions_all
  ON public.patient_clinical_impressions
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));

-- patient_schema_hypotheses
CREATE POLICY patient_schema_hypotheses_all
  ON public.patient_schema_hypotheses
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));

-- patient_mode_hypotheses
CREATE POLICY patient_mode_hypotheses_all
  ON public.patient_mode_hypotheses
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));

-- patient_emotional_needs
CREATE POLICY patient_emotional_needs_all
  ON public.patient_emotional_needs
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));
