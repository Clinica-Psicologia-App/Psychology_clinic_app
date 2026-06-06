-- Genograma simplificado: pessoas e relações familiares do paciente.

CREATE TABLE public.genogram_people (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id               UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id              UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  created_by              UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  full_name               TEXT NOT NULL,
  nickname                TEXT,
  relationship_to_patient TEXT,
  gender                  TEXT,
  birth_year              INTEGER,
  death_year              INTEGER,
  is_deceased             BOOLEAN NOT NULL DEFAULT false,
  notes                   TEXT,
  is_sensitive            BOOLEAN NOT NULL DEFAULT false,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT genogram_people_full_name_not_empty
    CHECK (char_length(trim(full_name)) > 0),
  CONSTRAINT genogram_people_gender_valid
    CHECK (
      gender IS NULL
      OR gender IN ('male', 'female', 'other', 'unknown')
    ),
  CONSTRAINT genogram_people_birth_year_range
    CHECK (
      birth_year IS NULL
      OR (birth_year >= 1800 AND birth_year <= 2200)
    ),
  CONSTRAINT genogram_people_death_year_range
    CHECK (
      death_year IS NULL
      OR (death_year >= 1800 AND death_year <= 2200)
    ),
  CONSTRAINT genogram_people_death_after_birth
    CHECK (
      birth_year IS NULL
      OR death_year IS NULL
      OR death_year >= birth_year
    )
);

COMMENT ON TABLE public.genogram_people IS
  'Membros do genograma do paciente (MVP lista; visualização gráfica futura).';

CREATE TABLE public.genogram_relationships (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id         UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id        UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  created_by        UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  person_a_id       UUID NOT NULL REFERENCES public.genogram_people (id) ON DELETE CASCADE,
  person_b_id       UUID NOT NULL REFERENCES public.genogram_people (id) ON DELETE CASCADE,
  relationship_type TEXT NOT NULL,
  notes             TEXT,
  is_sensitive      BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT genogram_relationships_distinct_people
    CHECK (person_a_id <> person_b_id),
  CONSTRAINT genogram_relationships_type_valid
    CHECK (
      relationship_type IN (
        'parent_child',
        'spouse',
        'ex_spouse',
        'sibling',
        'conflict',
        'distant',
        'close',
        'other'
      )
    )
);

COMMENT ON TABLE public.genogram_relationships IS
  'Relações entre pessoas do genograma (arestas simplificadas).';

CREATE INDEX idx_genogram_people_clinic_id ON public.genogram_people (clinic_id);
CREATE INDEX idx_genogram_people_patient_id ON public.genogram_people (patient_id);
CREATE INDEX idx_genogram_relationships_clinic_id ON public.genogram_relationships (clinic_id);
CREATE INDEX idx_genogram_relationships_patient_id ON public.genogram_relationships (patient_id);
CREATE INDEX idx_genogram_relationships_person_a ON public.genogram_relationships (person_a_id);
CREATE INDEX idx_genogram_relationships_person_b ON public.genogram_relationships (person_b_id);

CREATE TRIGGER trg_genogram_people_set_updated_at
  BEFORE UPDATE ON public.genogram_people
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_genogram_relationships_set_updated_at
  BEFORE UPDATE ON public.genogram_relationships
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.validate_genogram_person_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id da pessoa do genograma';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_genogram_people_validate_clinic
  BEFORE INSERT OR UPDATE ON public.genogram_people
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_genogram_person_clinic();

CREATE OR REPLACE FUNCTION public.validate_genogram_relationship_consistency()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_a_patient UUID;
  v_a_clinic UUID;
  v_b_patient UUID;
  v_b_clinic UUID;
BEGIN
  SELECT patient_id, clinic_id
  INTO v_a_patient, v_a_clinic
  FROM public.genogram_people
  WHERE id = NEW.person_a_id;

  SELECT patient_id, clinic_id
  INTO v_b_patient, v_b_clinic
  FROM public.genogram_people
  WHERE id = NEW.person_b_id;

  IF v_a_patient IS NULL OR v_b_patient IS NULL THEN
    RAISE EXCEPTION 'Pessoas da relação devem existir no genograma';
  END IF;

  IF v_a_patient <> v_b_patient
    OR v_a_patient <> NEW.patient_id
    OR v_b_patient <> NEW.patient_id THEN
    RAISE EXCEPTION 'As pessoas devem pertencer ao mesmo paciente da relação';
  END IF;

  IF v_a_clinic <> NEW.clinic_id OR v_b_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'clinic_id da relação deve coincidir com as pessoas';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_genogram_relationships_validate_consistency
  BEFORE INSERT OR UPDATE ON public.genogram_relationships
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_genogram_relationship_consistency();

ALTER TABLE public.genogram_people ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.genogram_relationships ENABLE ROW LEVEL SECURITY;

CREATE POLICY genogram_people_select
  ON public.genogram_people
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY genogram_people_insert
  ON public.genogram_people
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND (
      (
        public.current_role() = 'patient'
        AND patient_id = public.current_patient_id()
        AND (created_by IS NULL OR created_by = auth.uid())
      )
      OR (
        public.is_staff()
        AND public.user_can_access_patient(patient_id)
      )
    )
  );

CREATE POLICY genogram_people_update
  ON public.genogram_people
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY genogram_relationships_select
  ON public.genogram_relationships
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY genogram_relationships_insert
  ON public.genogram_relationships
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND (
      (
        public.current_role() = 'patient'
        AND patient_id = public.current_patient_id()
        AND (created_by IS NULL OR created_by = auth.uid())
      )
      OR (
        public.is_staff()
        AND public.user_can_access_patient(patient_id)
      )
    )
  );

CREATE POLICY genogram_relationships_update
  ON public.genogram_relationships
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );
