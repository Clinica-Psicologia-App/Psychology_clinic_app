-- Patient lifecycle management: reversible inactivation without deleting clinical history.

ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS inactivated_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS inactivated_by UUID
    REFERENCES public.profiles (id) ON DELETE SET NULL;

ALTER TABLE public.patients
  DROP CONSTRAINT IF EXISTS patients_inactivation_consistency;

ALTER TABLE public.patients
  ADD CONSTRAINT patients_inactivation_consistency CHECK (
    (is_active AND inactivated_at IS NULL AND inactivated_by IS NULL)
    OR
    (NOT is_active AND inactivated_at IS NOT NULL AND inactivated_by IS NOT NULL)
  );

CREATE INDEX IF NOT EXISTS idx_patients_responsible_active
  ON public.patients (responsible_psychologist_id, is_active);

COMMENT ON COLUMN public.patients.is_active IS
  'False archives the patient operationally while preserving the clinical record.';
COMMENT ON COLUMN public.patients.inactivated_at IS
  'UTC timestamp of the latest patient inactivation.';
COMMENT ON COLUMN public.patients.inactivated_by IS
  'Psychologist who performed the latest patient inactivation.';

CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_user IN ('postgres', 'supabase_admin')
    OR auth.role() = 'service_role'
    OR public.current_role()::text = 'platform_admin' THEN
    RETURN NEW;
  END IF;

  -- The lifecycle RPC may only toggle the access profile of an owned patient.
  IF OLD.role::TEXT = 'patient'
    AND public.current_role()::TEXT = 'psychologist'
    AND NEW.role IS NOT DISTINCT FROM OLD.role
    AND NEW.clinic_id IS NOT DISTINCT FROM OLD.clinic_id
    AND NEW.can_receive_patients IS NOT DISTINCT FROM OLD.can_receive_patients
    AND NEW.patient_assignment_limit IS NOT DISTINCT FROM OLD.patient_assignment_limit
    AND EXISTS (
      SELECT 1
      FROM public.patients AS patient
      WHERE patient.profile_id = OLD.id
        AND patient.clinic_id = public.current_clinic_id()
        AND patient.responsible_psychologist_id = auth.uid()
    ) THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role
    OR NEW.clinic_id IS DISTINCT FROM OLD.clinic_id
    OR NEW.is_active IS DISTINCT FROM OLD.is_active
    OR NEW.can_receive_patients IS DISTINCT FROM OLD.can_receive_patients
    OR NEW.patient_assignment_limit IS DISTINCT FROM OLD.patient_assignment_limit THEN
    RAISE EXCEPTION 'Campos administrativos do perfil nao podem ser alterados pelo proprio usuario';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_patient_active_status(
  p_patient_id UUID,
  p_is_active BOOLEAN
)
RETURNS public.patients
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient public.patients%ROWTYPE;
  v_action TEXT;
BEGIN
  IF public.current_role()::TEXT <> 'psychologist' THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Apenas psicologos podem alterar o status de pacientes';
  END IF;

  SELECT *
  INTO v_patient
  FROM public.patients
  WHERE id = p_patient_id
  FOR UPDATE;

  IF NOT FOUND
    OR v_patient.clinic_id IS DISTINCT FROM public.current_clinic_id()
    OR v_patient.responsible_psychologist_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Paciente nao encontrado ou nao pertence ao psicologo';
  END IF;

  IF v_patient.is_active IS DISTINCT FROM p_is_active THEN
    v_action := CASE
      WHEN p_is_active THEN 'patient_reactivated'
      ELSE 'patient_inactivated'
    END;

    UPDATE public.patients
    SET
      is_active = p_is_active,
      inactivated_at = CASE
        WHEN p_is_active THEN NULL
        ELSE timezone('utc', now())
      END,
      inactivated_by = CASE
        WHEN p_is_active THEN NULL
        ELSE auth.uid()
      END,
      updated_at = timezone('utc', now())
    WHERE id = p_patient_id
    RETURNING * INTO v_patient;

    INSERT INTO public.audit_events (
      clinic_id,
      actor_profile_id,
      action,
      entity_type,
      entity_id,
      patient_id,
      metadata
    )
    VALUES (
      v_patient.clinic_id,
      auth.uid(),
      v_action,
      'patients',
      v_patient.id,
      v_patient.id,
      jsonb_build_object(
        'source', 'set_patient_active_status',
        'is_active', p_is_active
      )
    );
  END IF;

  IF v_patient.profile_id IS NOT NULL THEN
    UPDATE public.profiles
    SET
      is_active = p_is_active,
      updated_at = timezone('utc', now())
    WHERE id = v_patient.profile_id
      AND role = 'patient';
  END IF;

  RETURN v_patient;
END;
$$;

REVOKE ALL ON FUNCTION public.set_patient_active_status(UUID, BOOLEAN)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_patient_active_status(UUID, BOOLEAN)
  TO authenticated;

-- Physical deletion remains unavailable to authenticated application users.
DROP POLICY IF EXISTS patients_delete_staff ON public.patients;
DROP POLICY IF EXISTS patients_delete_psychologist ON public.patients;
