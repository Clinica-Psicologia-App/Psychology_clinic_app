-- =============================================================================
-- Migration 035: platform_admin pode visualizar e inativar pacientes
-- =============================================================================

-- 1. Atualiza user_can_access_patient para incluir platform_admin
CREATE OR REPLACE FUNCTION public.user_can_access_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE public.current_role()::text
    WHEN 'platform_admin' THEN EXISTS (
      SELECT 1 FROM public.patients WHERE id = p_patient_id
    )
    WHEN 'psychologist' THEN EXISTS (
      SELECT 1 FROM public.patients
      WHERE id = p_patient_id
        AND clinic_id = public.current_clinic_id()
        AND responsible_psychologist_id = auth.uid()
    )
    WHEN 'patient' THEN EXISTS (
      SELECT 1 FROM public.patients
      WHERE id = p_patient_id
        AND profile_id = auth.uid()
    )
    ELSE false
  END;
$$;

-- 2. platform_admin pode atualizar pacientes (inativação, reatribuição)
DROP POLICY IF EXISTS patients_update_staff ON public.patients;
CREATE POLICY patients_update_staff
  ON public.patients
  FOR UPDATE
  TO authenticated
  USING (public.user_can_access_patient(id))
  WITH CHECK (
    public.current_role()::text = 'platform_admin'
    OR (
      clinic_id = public.current_clinic_id()
      AND public.current_role()::text = 'psychologist'
      AND responsible_psychologist_id = auth.uid()
    )
  );

-- 3. Atualiza set_patient_active_status para aceitar platform_admin
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
  v_current_role TEXT;
BEGIN
  v_current_role := public.current_role()::TEXT;

  IF v_current_role NOT IN ('psychologist', 'platform_admin') THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Apenas psicólogos e administradores podem alterar o status de pacientes';
  END IF;

  SELECT *
  INTO v_patient
  FROM public.patients
  WHERE id = p_patient_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Paciente não encontrado';
  END IF;

  -- Psicólogo só pode alterar seus próprios pacientes na mesma clínica
  IF v_current_role = 'psychologist' THEN
    IF v_patient.clinic_id IS DISTINCT FROM public.current_clinic_id()
      OR v_patient.responsible_psychologist_id IS DISTINCT FROM auth.uid() THEN
      RAISE EXCEPTION USING
        ERRCODE = '42501',
        MESSAGE = 'Paciente não pertence ao psicólogo';
    END IF;
  END IF;

  IF v_patient.is_active IS DISTINCT FROM p_is_active THEN
    v_action := CASE
      WHEN p_is_active THEN 'patient_reactivated'
      ELSE 'patient_inactivated'
    END;

    UPDATE public.patients
    SET
      is_active = p_is_active,
      inactivated_at = CASE WHEN p_is_active THEN NULL ELSE timezone('utc', now()) END,
      inactivated_by = CASE WHEN p_is_active THEN NULL ELSE auth.uid() END,
      updated_at = timezone('utc', now())
    WHERE id = p_patient_id
    RETURNING * INTO v_patient;

    INSERT INTO public.audit_events (
      clinic_id, actor_profile_id, action,
      entity_type, entity_id, patient_id, metadata
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
        'is_active', p_is_active,
        'actor_role', v_current_role
      )
    );
  END IF;

  IF v_patient.profile_id IS NOT NULL THEN
    UPDATE public.profiles
    SET is_active = p_is_active, updated_at = timezone('utc', now())
    WHERE id = v_patient.profile_id AND role = 'patient';
  END IF;

  RETURN v_patient;
END;
$$;
