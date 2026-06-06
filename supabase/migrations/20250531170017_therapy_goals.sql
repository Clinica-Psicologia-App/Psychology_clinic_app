-- Objetivos terapêuticos por paciente (simples; sem IA nem plano complexo).

CREATE TABLE public.therapy_goals (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id     UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id    UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  created_by    UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  title         TEXT NOT NULL,
  description   TEXT,
  status        TEXT NOT NULL DEFAULT 'active',
  target_date   DATE,
  completed_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT therapy_goals_title_not_empty
    CHECK (char_length(trim(title)) > 0),
  CONSTRAINT therapy_goals_status_valid
    CHECK (status IN ('active', 'completed', 'archived')),
  CONSTRAINT therapy_goals_completed_at_when_completed
    CHECK (
      status <> 'completed'
      OR completed_at IS NOT NULL
    )
);

COMMENT ON TABLE public.therapy_goals IS
  'Objetivos terapêuticos acordados entre paciente e equipe. Status: active, completed, archived.';

COMMENT ON COLUMN public.therapy_goals.created_by IS
  'Profile que criou o registro (paciente ou staff).';

CREATE INDEX idx_therapy_goals_clinic_id ON public.therapy_goals (clinic_id);
CREATE INDEX idx_therapy_goals_patient_id ON public.therapy_goals (patient_id);
CREATE INDEX idx_therapy_goals_status ON public.therapy_goals (status);
CREATE INDEX idx_therapy_goals_patient_status
  ON public.therapy_goals (patient_id, status);

CREATE TRIGGER trg_therapy_goals_set_updated_at
  BEFORE UPDATE ON public.therapy_goals
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Integridade clinic_id ↔ patient_id
CREATE OR REPLACE FUNCTION public.validate_therapy_goal_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id do objetivo';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_therapy_goals_validate_clinic
  BEFORE INSERT OR UPDATE ON public.therapy_goals
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_therapy_goal_clinic();

-- completed_at automático ao marcar completed (staff ou paciente)
CREATE OR REPLACE FUNCTION public.therapy_goals_set_completed_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.status = 'completed' AND NEW.completed_at IS NULL THEN
    NEW.completed_at := timezone('utc', now());
  END IF;

  IF TG_OP = 'UPDATE'
    AND NEW.status <> 'completed'
    AND OLD.status = 'completed' THEN
    NEW.completed_at := NULL;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_therapy_goals_completed_at
  BEFORE INSERT OR UPDATE ON public.therapy_goals
  FOR EACH ROW
  EXECUTE FUNCTION public.therapy_goals_set_completed_at();

ALTER TABLE public.therapy_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY therapy_goals_select
  ON public.therapy_goals
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY therapy_goals_insert
  ON public.therapy_goals
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

CREATE POLICY therapy_goals_update
  ON public.therapy_goals
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
