-- Problemas / queixas principais do paciente (jornada clínica; sem IA).

CREATE TABLE public.patient_problems (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id       UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id      UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  created_by      UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  title           TEXT NOT NULL,
  description     TEXT,
  category        TEXT,
  intensity       INTEGER,
  status          TEXT NOT NULL DEFAULT 'active',
  identified_at   DATE,
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_problems_title_not_empty
    CHECK (char_length(trim(title)) > 0),
  CONSTRAINT patient_problems_status_valid
    CHECK (status IN ('active', 'improved', 'resolved', 'archived')),
  CONSTRAINT patient_problems_intensity_range
    CHECK (
      intensity IS NULL
      OR (intensity >= 0 AND intensity <= 10)
    ),
  CONSTRAINT patient_problems_resolved_at_when_resolved
    CHECK (
      status <> 'resolved'
      OR resolved_at IS NOT NULL
    )
);

COMMENT ON TABLE public.patient_problems IS
  'Queixas e problemas em acompanhamento. Status: active, improved, resolved, archived.';

CREATE INDEX idx_patient_problems_clinic_id ON public.patient_problems (clinic_id);
CREATE INDEX idx_patient_problems_patient_id ON public.patient_problems (patient_id);
CREATE INDEX idx_patient_problems_status ON public.patient_problems (status);
CREATE INDEX idx_patient_problems_patient_status
  ON public.patient_problems (patient_id, status);

CREATE TRIGGER trg_patient_problems_set_updated_at
  BEFORE UPDATE ON public.patient_problems
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.validate_patient_problem_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id do problema';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_problems_validate_clinic
  BEFORE INSERT OR UPDATE ON public.patient_problems
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_patient_problem_clinic();

CREATE OR REPLACE FUNCTION public.patient_problems_set_resolved_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'resolved' AND NEW.resolved_at IS NULL THEN
    NEW.resolved_at := timezone('utc', now());
  END IF;

  IF TG_OP = 'UPDATE'
    AND NEW.status <> 'resolved'
    AND OLD.status = 'resolved' THEN
    NEW.resolved_at := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_problems_resolved_at
  BEFORE INSERT OR UPDATE ON public.patient_problems
  FOR EACH ROW
  EXECUTE FUNCTION public.patient_problems_set_resolved_at();

ALTER TABLE public.patient_problems ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_problems_select
  ON public.patient_problems
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY patient_problems_insert
  ON public.patient_problems
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

CREATE POLICY patient_problems_update
  ON public.patient_problems
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
