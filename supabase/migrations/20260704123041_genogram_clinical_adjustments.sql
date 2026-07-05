-- Ajustes clinicos do genograma:
-- - novas naturezas de relacao: neutra e rompida
-- - checklist de padroes familiares visivel apenas para psicologos

ALTER TABLE public.genogram_relationships
  DROP CONSTRAINT IF EXISTS genogram_relationships_type_valid;

ALTER TABLE public.genogram_relationships
  ADD CONSTRAINT genogram_relationships_type_valid
  CHECK (
    relationship_type IN (
      'parent_child',
      'spouse',
      'ex_spouse',
      'sibling',
      'conflict',
      'distant',
      'neutral',
      'close',
      'ruptured',
      'other'
    )
  );

CREATE TABLE public.genogram_family_patterns (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id    UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id   UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  pattern_keys TEXT[] NOT NULL DEFAULT '{}',
  other_text   TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT genogram_family_patterns_patient_unique UNIQUE (patient_id),
  CONSTRAINT genogram_family_patterns_other_required CHECK (
    NOT ('other' = ANY(pattern_keys))
    OR NULLIF(trim(COALESCE(other_text, '')), '') IS NOT NULL
  )
);

COMMENT ON TABLE public.genogram_family_patterns IS
  'Padroes familiares percebidos no genograma. Conteudo clinico reservado ao psicologo.';

CREATE INDEX idx_genogram_family_patterns_clinic_id
  ON public.genogram_family_patterns (clinic_id);

CREATE TRIGGER trg_genogram_family_patterns_set_updated_at
  BEFORE UPDATE ON public.genogram_family_patterns
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.validate_genogram_family_patterns_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic
  FROM public.patients
  WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer a clinic_id dos padroes do genograma';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_genogram_family_patterns_validate_clinic
  BEFORE INSERT OR UPDATE ON public.genogram_family_patterns
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_genogram_family_patterns_clinic();

ALTER TABLE public.genogram_family_patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY genogram_family_patterns_select_psychologist
  ON public.genogram_family_patterns
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role()::text = 'psychologist'
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY genogram_family_patterns_insert_psychologist
  ON public.genogram_family_patterns
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role()::text = 'psychologist'
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY genogram_family_patterns_update_psychologist
  ON public.genogram_family_patterns
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role()::text = 'psychologist'
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role()::text = 'psychologist'
    AND public.user_can_access_patient(patient_id)
  );
