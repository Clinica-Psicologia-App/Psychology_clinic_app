-- Check-ins rápidos do paciente (humor, ansiedade, energia, etc.).

CREATE TABLE public.patient_check_ins (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id               UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id              UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  created_by              UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  mood_score              INTEGER,
  anxiety_score           INTEGER,
  energy_score            INTEGER,
  problem_intensity_score INTEGER,
  notes                   TEXT,
  checked_in_at           TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  created_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_check_ins_mood_score_range
    CHECK (mood_score IS NULL OR (mood_score >= 0 AND mood_score <= 10)),
  CONSTRAINT patient_check_ins_anxiety_score_range
    CHECK (anxiety_score IS NULL OR (anxiety_score >= 0 AND anxiety_score <= 10)),
  CONSTRAINT patient_check_ins_energy_score_range
    CHECK (energy_score IS NULL OR (energy_score >= 0 AND energy_score <= 10)),
  CONSTRAINT patient_check_ins_problem_intensity_score_range
    CHECK (
      problem_intensity_score IS NULL
      OR (problem_intensity_score >= 0 AND problem_intensity_score <= 10)
    )
);

COMMENT ON TABLE public.patient_check_ins IS
  'Check-in breve e recorrente do paciente. Staff somente leitura.';

CREATE INDEX idx_patient_check_ins_clinic_id ON public.patient_check_ins (clinic_id);
CREATE INDEX idx_patient_check_ins_patient_id ON public.patient_check_ins (patient_id);
CREATE INDEX idx_patient_check_ins_checked_in_at ON public.patient_check_ins (checked_in_at DESC);
CREATE INDEX idx_patient_check_ins_patient_checked_in
  ON public.patient_check_ins (patient_id, checked_in_at DESC);

CREATE TRIGGER trg_patient_check_ins_set_updated_at
  BEFORE UPDATE ON public.patient_check_ins
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.validate_patient_check_in_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id do check-in';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_check_ins_validate_clinic
  BEFORE INSERT OR UPDATE ON public.patient_check_ins
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_patient_check_in_clinic();

ALTER TABLE public.patient_check_ins ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_check_ins_select
  ON public.patient_check_ins
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY patient_check_ins_insert
  ON public.patient_check_ins
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'patient'
    AND patient_id = public.current_patient_id()
    AND (created_by IS NULL OR created_by = auth.uid())
  );

CREATE POLICY patient_check_ins_update
  ON public.patient_check_ins
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'patient'
    AND patient_id = public.current_patient_id()
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'patient'
    AND patient_id = public.current_patient_id()
  );
