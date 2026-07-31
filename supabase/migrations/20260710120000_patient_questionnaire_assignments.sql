-- Atribuição de questionários por paciente.
-- Psicólogo escolhe quais questionários cada paciente deve preencher;
-- paciente vê apenas os atribuídos (pendentes, em andamento ou concluídos).

CREATE TABLE public.patient_questionnaire_assignments (
  id                     UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id              UUID        NOT NULL REFERENCES public.clinics(id)                 ON DELETE CASCADE,
  patient_id             UUID        NOT NULL REFERENCES public.patients(id)                ON DELETE CASCADE,
  questionnaire_id       UUID        NOT NULL REFERENCES public.questionnaires(id)          ON DELETE CASCADE,
  assigned_by_profile_id UUID        NOT NULL REFERENCES public.profiles(id),
  assigned_at            TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  message                TEXT,
  response_id            UUID        REFERENCES public.questionnaire_responses(id)          ON DELETE SET NULL,
  cancelled_at           TIMESTAMPTZ
);

CREATE INDEX ON public.patient_questionnaire_assignments (patient_id);
CREATE INDEX ON public.patient_questionnaire_assignments (clinic_id);

ALTER TABLE public.patient_questionnaire_assignments ENABLE ROW LEVEL SECURITY;

-- Staff (psicólogo / admin): leitura de todas as atribuições dos seus pacientes
CREATE POLICY pqa_select_staff
  ON public.patient_questionnaire_assignments
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

-- Staff: pode criar atribuições para os seus pacientes
CREATE POLICY pqa_insert_staff
  ON public.patient_questionnaire_assignments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
    AND assigned_by_profile_id = auth.uid()
  );

-- Staff: pode cancelar atribuições (UPDATE cancelled_at) e linkar response_id
CREATE POLICY pqa_update_staff
  ON public.patient_questionnaire_assignments
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  );

-- Paciente: vê apenas suas próprias atribuições ativas (não canceladas)
CREATE POLICY pqa_select_patient
  ON public.patient_questionnaire_assignments
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'patient'
    AND patient_id = public.current_patient_id()
    AND cancelled_at IS NULL
  );
