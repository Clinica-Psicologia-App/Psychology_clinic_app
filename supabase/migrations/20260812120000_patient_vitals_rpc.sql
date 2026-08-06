-- RPC que agrega os "sinais vitais" clínicos de um paciente para o
-- psicólogo responsável: último check-in, metas ativas e questionários
-- em andamento. Uma única chamada em vez de três queries independentes.
--
-- Acesso: user_can_access_patient() garante que só o responsável (ou o
-- próprio paciente) consegue chamar. Admin recebe { access: false }.

CREATE OR REPLACE FUNCTION public.get_patient_vitals(p_patient_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    CASE WHEN NOT public.user_can_access_patient(p_patient_id)
    THEN jsonb_build_object('access', false)
    ELSE jsonb_build_object(
      'access', true,
      'last_checkin_days',
        (SELECT
          CASE
            WHEN MAX(checked_in_at) IS NULL THEN NULL
            ELSE EXTRACT(DAY FROM now() - MAX(checked_in_at))::int
          END
         FROM patient_check_ins
         WHERE patient_id = p_patient_id),
      'active_goals',
        (SELECT COUNT(*)::int
         FROM therapy_goals
         WHERE patient_id = p_patient_id
           AND status = 'active'),
      'pending_questionnaires',
        (SELECT COUNT(*)::int
         FROM questionnaire_responses
         WHERE patient_id = p_patient_id
           AND status = 'draft')
    )
    END;
$$;

REVOKE ALL   ON FUNCTION public.get_patient_vitals(UUID) FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.get_patient_vitals(UUID) TO authenticated;
