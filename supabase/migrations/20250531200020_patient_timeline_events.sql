-- Eventos da linha do tempo do paciente (história de vida / processo terapêutico).

CREATE TABLE public.patient_timeline_events (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id         UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id        UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  created_by        UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  title             TEXT NOT NULL,
  description       TEXT,
  event_date        DATE,
  period_label      TEXT,
  category          TEXT,
  emotional_impact  INTEGER,
  is_sensitive      BOOLEAN NOT NULL DEFAULT false,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_timeline_events_title_not_empty
    CHECK (char_length(trim(title)) > 0),
  CONSTRAINT patient_timeline_events_emotional_impact_range
    CHECK (
      emotional_impact IS NULL
      OR (emotional_impact >= 0 AND emotional_impact <= 10)
    )
);

COMMENT ON TABLE public.patient_timeline_events IS
  'Eventos importantes na linha do tempo do paciente. Paciente e staff podem criar/editar.';

CREATE INDEX idx_patient_timeline_events_clinic_id
  ON public.patient_timeline_events (clinic_id);
CREATE INDEX idx_patient_timeline_events_patient_id
  ON public.patient_timeline_events (patient_id);
CREATE INDEX idx_patient_timeline_events_event_date
  ON public.patient_timeline_events (event_date DESC NULLS LAST);
CREATE INDEX idx_patient_timeline_events_patient_event_date
  ON public.patient_timeline_events (patient_id, event_date DESC NULLS LAST);

CREATE TRIGGER trg_patient_timeline_events_set_updated_at
  BEFORE UPDATE ON public.patient_timeline_events
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE OR REPLACE FUNCTION public.validate_patient_timeline_event_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id do evento';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_timeline_events_validate_clinic
  BEFORE INSERT OR UPDATE ON public.patient_timeline_events
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_patient_timeline_event_clinic();

ALTER TABLE public.patient_timeline_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_timeline_events_select
  ON public.patient_timeline_events
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY patient_timeline_events_insert
  ON public.patient_timeline_events
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

CREATE POLICY patient_timeline_events_update
  ON public.patient_timeline_events
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
