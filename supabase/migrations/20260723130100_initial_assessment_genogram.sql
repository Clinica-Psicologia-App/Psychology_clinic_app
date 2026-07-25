-- =============================================================================
-- Fluxo "Conhecer" — Tela 3 (Minha Família / Genograma emocional)
--
-- Estende `genogram_people` (já tinha nome, parentesco, gênero, falecido) com a
-- camada emocional: figura de apego, qualidade e intensidade do vínculo,
-- características do cuidador, necessidades sentidas/desejadas e eventos
-- ligados à pessoa.
--
-- As necessidades experienciais são traduzidas para as 5 necessidades centrais
-- de Young (catálogo `emotional_needs`) na camada de domínio — aqui guardamos a
-- linguagem do paciente.
-- =============================================================================

ALTER TABLE public.genogram_people
  ADD COLUMN is_caregiver           BOOLEAN,
  ADD COLUMN bond_quality           TEXT,
  ADD COLUMN emotional_presence     SMALLINT,
  ADD COLUMN caregiver_traits       TEXT[],
  ADD COLUMN caregiver_traits_other TEXT,
  ADD COLUMN felt_needs             TEXT[],
  ADD COLUMN wished_needs           TEXT[],
  ADD COLUMN linked_events          TEXT[],
  ADD COLUMN linked_events_other    TEXT,
  ADD COLUMN filled_by_profile_id   UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  ADD COLUMN filled_by_role         TEXT;

COMMENT ON COLUMN public.genogram_people.is_caregiver IS
  'Tela 3: "participou da sua criação ou foi sua cuidadora?" — marca figura de apego.';
COMMENT ON COLUMN public.genogram_people.emotional_presence IS
  'Tela 3: "quanto esteve emocionalmente presente" (0–10).';
COMMENT ON COLUMN public.genogram_people.felt_needs IS
  'Tela 3: "quando estava com essa pessoa, geralmente se sentia..." (linguagem do paciente).';
COMMENT ON COLUMN public.genogram_people.wished_needs IS
  'Tela 3: "o que mais gostaria de ter recebido dessa pessoa".';

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_bond_quality_valid
    CHECK (bond_quality IS NULL OR bond_quality IN (
      'affectionate',  -- Afetiva
      'conflictual',   -- Conflituosa
      'distant',       -- Distante
      'ambivalent',    -- Ambivalente
      'broken'         -- Rompida
    )),
  ADD CONSTRAINT genogram_people_emotional_presence_range
    CHECK (emotional_presence IS NULL OR (emotional_presence >= 0 AND emotional_presence <= 10)),
  ADD CONSTRAINT genogram_people_caregiver_traits_valid
    CHECK (caregiver_traits IS NULL OR caregiver_traits <@ ARRAY[
      'welcoming',           -- Acolhia
      'affectionate',        -- Demonstrava carinho
      'encouraging',         -- Incentivava
      'protective',          -- Protegia
      'respectful',          -- Respeitava
      'critical',            -- Criticava
      'controlling',         -- Controlava
      'neglectful',          -- Ignorava
      'unpredictable',       -- Era imprevisível
      'demanding',           -- Cobrava demais
      'emotionally_distant'  -- Era emocionalmente distante
    ]::text[]),
  ADD CONSTRAINT genogram_people_felt_needs_valid
    CHECK (felt_needs IS NULL OR felt_needs <@ ARRAY[
      'safe', 'loved', 'accepted', 'understood', 'valued',
      'respected', 'free_to_be', 'encouraged', 'protected'
    ]::text[]),
  ADD CONSTRAINT genogram_people_wished_needs_valid
    CHECK (wished_needs IS NULL OR wished_needs <@ ARRAY[
      'safe', 'loved', 'accepted', 'understood', 'valued',
      'respected', 'free_to_be', 'encouraged', 'protected'
    ]::text[]),
  ADD CONSTRAINT genogram_people_linked_events_valid
    CHECK (linked_events IS NULL OR linked_events <@ ARRAY[
      'separation',   -- Separação
      'death',        -- Falecimento
      'abandonment',  -- Abandono
      'violence',     -- Violência
      'relocation',   -- Mudança
      'alcoholism',   -- Alcoolismo
      'illness'       -- Doença
    ]::text[]),
  ADD CONSTRAINT genogram_people_filled_by_role_valid
    CHECK (filled_by_role IS NULL OR filled_by_role IN ('patient', 'psychologist', 'admin'));

CREATE INDEX idx_genogram_people_is_caregiver
  ON public.genogram_people (patient_id, is_caregiver);

-- -----------------------------------------------------------------------------
-- Clima familiar e padrões transgeracionais — nível do paciente (não por
-- pessoa). Visível ao paciente, que é quem responde.
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_family_context (
  id                                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id                        UUID NOT NULL UNIQUE REFERENCES public.patients (id) ON DELETE CASCADE,
  family_climate                    TEXT[],
  family_climate_other              TEXT,
  transgenerational_patterns        TEXT[],
  transgenerational_patterns_other  TEXT,
  filled_by_profile_id              UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  filled_by_role                    TEXT,
  created_at                        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at                        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_family_context_climate_valid
    CHECK (family_climate IS NULL OR family_climate <@ ARRAY[
      'show_affection',      -- Demonstrar carinho
      'talk',                -- Conversar
      'resolve_conflicts',   -- Resolver conflitos
      'criticize',           -- Fazer críticas
      'demand_perfection',   -- Cobrar perfeição
      'avoid_emotions',      -- Evitar emoções
      'control',             -- Controlar
      'support',             -- Apoiar
      'frequent_fighting',   -- Brigar frequentemente
      'withhold_feelings',   -- Guardar sentimentos
      'respect_opinions'     -- Respeitar opiniões
    ]::text[]),
  CONSTRAINT patient_family_context_patterns_valid
    CHECK (transgenerational_patterns IS NULL OR transgenerational_patterns <@ ARRAY[
      'separations',            -- Separações
      'violence',               -- Violência
      'alcoholism',             -- Alcoolismo
      'substance_dependence',   -- Dependência química
      'depression',             -- Depressão
      'anxiety',                -- Ansiedade
      'suicide_attempts',       -- Tentativas de suicídio
      'psychiatric_disorders',  -- Transtornos psiquiátricos
      'abandonment',            -- Abandono
      'serious_illness',        -- Doenças graves
      'financial_crises',       -- Crises financeiras
      'abusive_relationships',  -- Relacionamentos abusivos
      'emotional_rigidity',     -- Rigidez emocional
      'perfectionism',          -- Perfeccionismo
      'excessive_caretaking'    -- Cuidar excessivamente dos outros
    ]::text[]),
  CONSTRAINT patient_family_context_filled_by_role_valid
    CHECK (filled_by_role IS NULL OR filled_by_role IN ('patient', 'psychologist', 'admin'))
);

COMMENT ON TABLE public.patient_family_context IS
  'Tela 3 — clima emocional da família e padrões transgeracionais. Visível ao paciente.';

CREATE INDEX idx_patient_family_context_patient_id
  ON public.patient_family_context (patient_id);

CREATE TRIGGER trg_patient_family_context_set_updated_at
  BEFORE UPDATE ON public.patient_family_context
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Comentários clínicos por pessoa — staff-only.
-- -----------------------------------------------------------------------------

CREATE TABLE public.genogram_person_notes (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  person_id              UUID NOT NULL UNIQUE REFERENCES public.genogram_people (id) ON DELETE CASCADE,
  clinical_comment       TEXT,
  updated_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.genogram_person_notes IS
  'Tela 3 — comentário clínico do terapeuta por pessoa do genograma. Exclusivo do terapeuta.';

CREATE INDEX idx_genogram_person_notes_patient_id
  ON public.genogram_person_notes (patient_id);

CREATE TRIGGER trg_genogram_person_notes_set_updated_at
  BEFORE UPDATE ON public.genogram_person_notes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- RLS
-- -----------------------------------------------------------------------------

ALTER TABLE public.patient_family_context ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.genogram_person_notes  ENABLE ROW LEVEL SECURITY;

-- Clima familiar: paciente e staff com acesso (mesma regra do restante da Tela 3).
CREATE POLICY patient_family_context_select
  ON public.patient_family_context
  FOR SELECT
  TO authenticated
  USING (public.user_can_access_patient(patient_id));

CREATE POLICY patient_family_context_insert
  ON public.patient_family_context
  FOR INSERT
  TO authenticated
  WITH CHECK (public.user_can_access_patient(patient_id));

CREATE POLICY patient_family_context_update
  ON public.patient_family_context
  FOR UPDATE
  TO authenticated
  USING (public.user_can_access_patient(patient_id))
  WITH CHECK (public.user_can_access_patient(patient_id));

CREATE POLICY patient_family_context_delete
  ON public.patient_family_context
  FOR DELETE
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id));

-- Notas clínicas por pessoa: staff-only.
CREATE POLICY genogram_person_notes_all
  ON public.genogram_person_notes
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));
