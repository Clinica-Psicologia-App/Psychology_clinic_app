-- =============================================================================
-- Migration 037: questionnaire_responses.patient_id → ON DELETE CASCADE
-- =============================================================================
-- Motivo: a RPC delete_patient_as_admin precisa deletar manualmente
-- questionnaire_responses antes do paciente por causa do RESTRICT.
-- Isso cria fragilidade de ordem; CASCADE é a semântica correta —
-- se o paciente é removido, suas respostas de questionário devem
-- ser removidas junto (o administrador já confirmou a intenção).

ALTER TABLE public.questionnaire_responses
  DROP CONSTRAINT IF EXISTS questionnaire_responses_patient_id_fkey;

ALTER TABLE public.questionnaire_responses
  ADD CONSTRAINT questionnaire_responses_patient_id_fkey
    FOREIGN KEY (patient_id)
    REFERENCES public.patients (id)
    ON DELETE CASCADE;

-- Simplifica a RPC para não precisar mais do DELETE manual
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

  -- CASCADE cuida de questionnaire_responses, questionnaire_answers,
  -- questionnaire_results, questionnaire_response_contexts,
  -- patient_timeline_events, genogram, therapy_goals, etc.
  DELETE FROM public.patients
  WHERE id = p_patient_id;

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
