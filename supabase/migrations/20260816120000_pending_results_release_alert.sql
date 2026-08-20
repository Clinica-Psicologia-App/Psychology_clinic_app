-- Adiciona a 4ª categoria de alerta do psicólogo: resultado concluído mas
-- ainda não liberado ao paciente.
--
-- O botão de liberação (set_patient_results_released) fica no fim do
-- Dashboard Clínico, sem nenhuma trava condicionando à existência de
-- resultado — é fácil o psicólogo esquecer de liberar depois que o paciente
-- termina o questionário. Este alerta fecha esse vão.

CREATE OR REPLACE FUNCTION public.get_psychologist_alerts()
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH missing_checkins AS (
    SELECT
      p.id        AS patient_id,
      p.full_name AS patient_name,
      CASE
        WHEN MAX(ci.checked_in_at) IS NULL
          THEN 999
        ELSE EXTRACT(DAY FROM now() - MAX(ci.checked_in_at))::int
      END AS days_since_checkin
    FROM patients p
    LEFT JOIN patient_check_ins ci ON ci.patient_id = p.id
    WHERE p.responsible_psychologist_id = auth.uid()
      AND p.is_active  = true
      AND p.profile_id IS NOT NULL
    GROUP BY p.id, p.full_name
    HAVING MAX(ci.checked_in_at) IS NULL
        OR MAX(ci.checked_in_at) < now() - interval '7 days'
    ORDER BY days_since_checkin DESC
    LIMIT 3
  ),
  expiring_invitations AS (
    SELECT
      id                              AS invitation_id,
      COALESCE(full_name, email)      AS patient_name,
      GREATEST(
        0,
        EXTRACT(DAY FROM expires_at - now())::int
      )                               AS days_until_expiry
    FROM patient_invitations
    WHERE responsible_psychologist_id = auth.uid()
      AND status     = 'pending'
      AND expires_at >  now()
      AND expires_at <= now() + interval '3 days'
    ORDER BY expires_at ASC
    LIMIT 3
  ),
  stale_questionnaires AS (
    SELECT
      p.id        AS patient_id,
      p.full_name AS patient_name,
      EXTRACT(DAY FROM now() - MIN(qr.created_at))::int AS days_waiting
    FROM questionnaire_responses qr
    JOIN patients p ON p.id = qr.patient_id
    WHERE p.responsible_psychologist_id = auth.uid()
      AND qr.status     = 'draft'
      AND qr.created_at < now() - interval '7 days'
    GROUP BY p.id, p.full_name
    ORDER BY days_waiting DESC
    LIMIT 3
  ),
  pending_results_release AS (
    SELECT
      p.id        AS patient_id,
      p.full_name AS patient_name,
      EXTRACT(DAY FROM now() - MIN(qr.completed_at))::int AS days_waiting
    FROM questionnaire_responses qr
    JOIN patients p ON p.id = qr.patient_id
    WHERE p.responsible_psychologist_id = auth.uid()
      AND p.is_active         = true
      AND qr.status            = 'completed'
      AND p.results_released_at IS NULL
    GROUP BY p.id, p.full_name
    ORDER BY days_waiting DESC
    LIMIT 3
  )
  SELECT jsonb_build_object(
    'missing_checkins',
      COALESCE(
        (SELECT jsonb_agg(to_jsonb(mc)) FROM missing_checkins mc),
        '[]'::jsonb
      ),
    'expiring_invitations',
      COALESCE(
        (SELECT jsonb_agg(to_jsonb(ei)) FROM expiring_invitations ei),
        '[]'::jsonb
      ),
    'stale_questionnaires',
      COALESCE(
        (SELECT jsonb_agg(to_jsonb(sq)) FROM stale_questionnaires sq),
        '[]'::jsonb
      ),
    'pending_results_release',
      COALESCE(
        (SELECT jsonb_agg(to_jsonb(pr)) FROM pending_results_release pr),
        '[]'::jsonb
      )
  );
$$;

REVOKE ALL   ON FUNCTION public.get_psychologist_alerts() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.get_psychologist_alerts() TO authenticated;
