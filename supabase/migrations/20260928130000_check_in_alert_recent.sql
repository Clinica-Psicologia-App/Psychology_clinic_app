-- Adiciona a categoria recent_checkins em get_psychologist_alerts().
-- Notifica o psicólogo quando um paciente seu realizou um check-in nas
-- últimas 24 horas, ordenado do mais recente para o mais antigo (até 5).

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
  recent_checkins AS (
    SELECT
      p.id        AS patient_id,
      p.full_name AS patient_name,
      (EXTRACT(EPOCH FROM (now() - MAX(ci.checked_in_at))) / 3600)::int
                  AS hours_ago
    FROM patients p
    JOIN patient_check_ins ci ON ci.patient_id = p.id
    WHERE p.responsible_psychologist_id = auth.uid()
      AND p.is_active = true
      AND ci.checked_in_at >= now() - interval '24 hours'
    GROUP BY p.id, p.full_name
    ORDER BY MAX(ci.checked_in_at) DESC
    LIMIT 5
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
    'recent_checkins',
      COALESCE(
        (SELECT jsonb_agg(to_jsonb(rc)) FROM recent_checkins rc),
        '[]'::jsonb
      )
  );
$$;

REVOKE ALL   ON FUNCTION public.get_psychologist_alerts() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.get_psychologist_alerts() TO authenticated;
