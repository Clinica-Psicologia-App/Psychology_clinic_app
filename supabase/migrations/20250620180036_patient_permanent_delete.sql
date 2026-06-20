-- =============================================================================
-- Migration 036: exclusão permanente de paciente pelo platform_admin
-- =============================================================================
-- A exclusão é uma operação destrutiva e irreversível:
--   • questionnaire_responses: ON DELETE RESTRICT → deletados explicitamente
--   • demais registros clínicos: ON DELETE CASCADE → removidos automaticamente
--   • audit_events: ON DELETE SET NULL → preservados como log histórico

-- 1. Política RLS de DELETE para platform_admin
DROP POLICY IF EXISTS patients_delete_admin ON public.patients;
CREATE POLICY patients_delete_admin
  ON public.patients
  FOR DELETE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');

-- 2. RPC que executa a exclusão com ordem correta para contornar o RESTRICT
CREATE OR REPLACE FUNCTION public.delete_patient_as_admin(p_patient_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clinic_id UUID;
  v_full_name TEXT;
BEGIN
  IF public.current_role()::TEXT <> 'platform_admin' THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Apenas administradores podem excluir pacientes definitivamente';
  END IF;

  SELECT clinic_id, full_name
    INTO v_clinic_id, v_full_name
  FROM public.patients
  WHERE id = p_patient_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = 'Paciente não encontrado';
  END IF;

  -- Remove questionnaire_responses antes (ON DELETE RESTRICT)
  DELETE FROM public.questionnaire_responses
  WHERE patient_id = p_patient_id;

  -- Remove o paciente (demais vínculos em CASCADE)
  DELETE FROM public.patients
  WHERE id = p_patient_id;

  -- Registra no audit log (clinic_id pode ser null se a clínica foi removida)
  INSERT INTO public.audit_events (
    clinic_id, actor_profile_id, action,
    entity_type, entity_id, metadata
  )
  VALUES (
    v_clinic_id,
    auth.uid(),
    'patient_deleted_permanently',
    'patients',
    p_patient_id,
    jsonb_build_object(
      'patient_full_name', v_full_name,
      'actor_role', 'platform_admin'
    )
  );
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_patient_as_admin(UUID) TO authenticated;
