-- =============================================================================
-- Fluxo "Conhecer" — tabelas visíveis ao paciente (mesma lente do paciente).
--   Bloco 2 → patient_intake (1:1)
--   Bloco 3 → patient_life_areas (1 linha por área)
-- Ambos podem ser preenchidos pelo paciente OU pelo terapeuta em nome dele;
-- por isso guardam filled_by_profile_id + filled_by_role.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Bloco 2 — "O que está acontecendo?" (Motivo da procura, lado do paciente)
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_intake (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            UUID NOT NULL UNIQUE REFERENCES public.patients (id) ON DELETE CASCADE,
  reason_for_seeking    TEXT, -- "O que fez você procurar terapia agora?"
  problem_duration      TEXT, -- "Há quanto tempo isso acontece?"
  main_discomfort       TEXT, -- "O que mais incomoda hoje?"
  expectations          TEXT, -- "O que espera que seja diferente após a terapia?"
  related_event         TEXT, -- "Existe algum acontecimento importante relacionado a isso?"
  filled_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  filled_by_role        TEXT,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_intake_filled_by_role_valid
    CHECK (filled_by_role IS NULL OR filled_by_role IN ('patient', 'psychologist', 'admin'))
);

COMMENT ON TABLE public.patient_intake IS
  'Bloco 2 do fluxo Conhecer — respostas do paciente sobre o motivo da procura. Visível ao paciente.';

CREATE INDEX idx_patient_intake_patient_id ON public.patient_intake (patient_id);

CREATE TRIGGER trg_patient_intake_set_updated_at
  BEFORE UPDATE ON public.patient_intake
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Bloco 3 — "Como está sua vida hoje?" (Funcionamento atual, lado do paciente)
-- Snapshot atual: uma linha por área (upsert). 12 áreas (Roda da Vida).
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_life_areas (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id            UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  area_key              TEXT NOT NULL,
  score                 SMALLINT, -- nível de satisfação 1–10
  suffering             SMALLINT, -- sofrimento 0–10 (opcional, "quando pertinente")
  guided_answer         TEXT,     -- comentário breve / resposta à pergunta guiada
  filled_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  filled_by_role        TEXT,
  assessed_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_life_areas_area_key_valid CHECK (area_key IN (
    'work_career',            -- Trabalho e Carreira
    'finances_money',         -- Finanças & Dinheiro
    'health_fitness',         -- Saúde & Fitness
    'family',                 -- Família
    'friends',                -- Amigos
    'love_romance',           -- Amor e Romance
    'personal_growth',        -- Crescimento Pessoal
    'recreation_fun',         -- Recreação & Diversão
    'physical_environment',   -- Ambiente Físico
    'contribution_social',    -- Contribuição & Impacto Social
    'spirituality',           -- Espiritualidade
    'mental_emotional_health' -- Saúde Mental & Emocional
  )),
  CONSTRAINT patient_life_areas_score_range
    CHECK (score IS NULL OR score BETWEEN 1 AND 10),
  CONSTRAINT patient_life_areas_suffering_range
    CHECK (suffering IS NULL OR suffering BETWEEN 0 AND 10),
  CONSTRAINT patient_life_areas_filled_by_role_valid
    CHECK (filled_by_role IS NULL OR filled_by_role IN ('patient', 'psychologist', 'admin')),
  CONSTRAINT patient_life_areas_unique_area UNIQUE (patient_id, area_key)
);

COMMENT ON TABLE public.patient_life_areas IS
  'Bloco 3 do fluxo Conhecer — avaliação por área de vida (nota + sofrimento + pergunta guiada). Alimenta o "Mapa da Vida". Visível ao paciente.';

CREATE INDEX idx_patient_life_areas_patient_id ON public.patient_life_areas (patient_id);

CREATE TRIGGER trg_patient_life_areas_set_updated_at
  BEFORE UPDATE ON public.patient_life_areas
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS — visível ao paciente e ao staff com acesso (mesma regra da tabela patients)
-- -----------------------------------------------------------------------------

ALTER TABLE public.patient_intake ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_life_areas ENABLE ROW LEVEL SECURITY;

-- patient_intake
CREATE POLICY patient_intake_select
  ON public.patient_intake
  FOR SELECT
  TO authenticated
  USING (public.user_can_access_patient(patient_id));

CREATE POLICY patient_intake_insert
  ON public.patient_intake
  FOR INSERT
  TO authenticated
  WITH CHECK (public.user_can_access_patient(patient_id));

CREATE POLICY patient_intake_update
  ON public.patient_intake
  FOR UPDATE
  TO authenticated
  USING (public.user_can_access_patient(patient_id))
  WITH CHECK (public.user_can_access_patient(patient_id));

CREATE POLICY patient_intake_delete
  ON public.patient_intake
  FOR DELETE
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id));

-- patient_life_areas
CREATE POLICY patient_life_areas_select
  ON public.patient_life_areas
  FOR SELECT
  TO authenticated
  USING (public.user_can_access_patient(patient_id));

CREATE POLICY patient_life_areas_insert
  ON public.patient_life_areas
  FOR INSERT
  TO authenticated
  WITH CHECK (public.user_can_access_patient(patient_id));

CREATE POLICY patient_life_areas_update
  ON public.patient_life_areas
  FOR UPDATE
  TO authenticated
  USING (public.user_can_access_patient(patient_id))
  WITH CHECK (public.user_can_access_patient(patient_id));

CREATE POLICY patient_life_areas_delete
  ON public.patient_life_areas
  FOR DELETE
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id));
