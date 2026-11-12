-- S1 (Marco Segurança Supabase, achado A1 + B2): corrige a regressão de
-- get_psychologist_alerts() e escopa get_patient_vitals() por clínica.
--
-- Contexto: 20260928130000_check_in_alert_recent.sql sobrescreveu o
-- endurecimento do Lote B (20260914130000). A versão em vigor (LANGUAGE sql,
-- search_path = public) não exigia profile ativo nem papel psicólogo, não
-- filtrava por clínica e perdeu a chave pending_results_release.
--
-- Esta migration:
--   1. get_psychologist_alerts(): plpgsql SECURITY DEFINER com o guarda do
--      Lote B (role authenticated + auth.uid() + profile ativo + papel
--      psychologist), search_path = pg_catalog com nomes qualificados,
--      predicados de clínica (p.clinic_id, ci.clinic_id = p.clinic_id,
--      qr.clinic_id = p.clinic_id), mantém recent_checkins (20260928130000) e
--      devolve pending_results_release de novo. Mesma assinatura e contrato
--      jsonb com 5 chaves; psicólogo sem acesso recebe 42501 (como no Lote B).
--   2. get_patient_vitals(uuid): mesma assinatura e contrato; contagens e
--      último check-in passam a considerar só linhas da clínica atual do
--      paciente (histórico de outra clínica deixa de vazar após transferência).
--
-- Grants explícitos (sem anon, sem PUBLIC). Sem mudança de tabela, RLS ou app.

CREATE OR REPLACE FUNCTION public.get_psychologist_alerts()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_id uuid := auth.uid();
  v_clinic_id uuid;
BEGIN
  IF current_setting('role',true) IS DISTINCT FROM 'authenticated' OR v_actor_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Active psychologist required';
  END IF;
  SELECT actor.clinic_id INTO v_clinic_id FROM public.profiles AS actor
  WHERE actor.id=v_actor_id AND actor.is_active IS TRUE AND actor.role::text='psychologist';
  IF NOT FOUND OR v_clinic_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Active psychologist required';
  END IF;
  RETURN (
  WITH missing_checkins AS (
    SELECT
      p.id        AS patient_id,
      p.full_name AS patient_name,
      CASE
        WHEN MAX(ci.checked_in_at) IS NULL
          THEN 999
        ELSE EXTRACT(DAY FROM now() - MAX(ci.checked_in_at))::int
      END AS days_since_checkin
    FROM public.patients p
    LEFT JOIN public.patient_check_ins ci ON ci.patient_id = p.id AND ci.clinic_id = p.clinic_id
    WHERE p.responsible_psychologist_id = v_actor_id
      AND p.clinic_id = v_clinic_id
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
    FROM public.patient_invitations
    WHERE responsible_psychologist_id = v_actor_id
      AND clinic_id = v_clinic_id
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
    FROM public.questionnaire_responses qr
    JOIN public.patients p ON p.id = qr.patient_id AND qr.clinic_id = p.clinic_id
    WHERE p.responsible_psychologist_id = v_actor_id
      AND p.clinic_id = v_clinic_id
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
    FROM public.questionnaire_responses qr
    JOIN public.patients p ON p.id = qr.patient_id AND qr.clinic_id = p.clinic_id
    WHERE p.responsible_psychologist_id = v_actor_id
      AND p.clinic_id = v_clinic_id
      AND p.is_active         = true
      AND qr.status            = 'completed'
      AND p.results_released_at IS NULL
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
    FROM public.patients p
    JOIN public.patient_check_ins ci ON ci.patient_id = p.id AND ci.clinic_id = p.clinic_id
    WHERE p.responsible_psychologist_id = v_actor_id
      AND p.clinic_id = v_clinic_id
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
    'pending_results_release',
      COALESCE(
        (SELECT jsonb_agg(to_jsonb(pr)) FROM pending_results_release pr),
        '[]'::jsonb
      ),
    'recent_checkins',
      COALESCE(
        (SELECT jsonb_agg(to_jsonb(rc)) FROM recent_checkins rc),
        '[]'::jsonb
      )
  )
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.get_psychologist_alerts() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_psychologist_alerts() TO authenticated;


CREATE OR REPLACE FUNCTION public.get_patient_vitals(p_patient_id UUID)
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT
    CASE WHEN NOT public.user_can_access_patient(p_patient_id)
    THEN jsonb_build_object('access', false)
    ELSE jsonb_build_object(
      'access', true,
      'last_checkin_days',
        (SELECT
          CASE
            WHEN MAX(ci.checked_in_at) IS NULL THEN NULL
            ELSE EXTRACT(DAY FROM now() - MAX(ci.checked_in_at))::int
          END
         FROM public.patient_check_ins ci
         JOIN public.patients p ON p.id = ci.patient_id AND p.clinic_id = ci.clinic_id
         WHERE ci.patient_id = p_patient_id),
      'active_goals',
        (SELECT COUNT(*)::int
         FROM public.therapy_goals tg
         JOIN public.patients p ON p.id = tg.patient_id AND p.clinic_id = tg.clinic_id
         WHERE tg.patient_id = p_patient_id
           AND tg.status = 'active'),
      'pending_questionnaires',
        (SELECT COUNT(*)::int
         FROM public.questionnaire_responses qr
         JOIN public.patients p ON p.id = qr.patient_id AND p.clinic_id = qr.clinic_id
         WHERE qr.patient_id = p_patient_id
           AND qr.status = 'draft')
    )
    END;
$$;

REVOKE ALL ON FUNCTION public.get_patient_vitals(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_patient_vitals(UUID) TO authenticated;


-- ROLLBACK (manual, não executado). Definições anteriores abaixo, comentadas.
-- ATENÇÃO: a de get_psychologist_alerts é a versão regredida de 20260928130000 (sem guarda de
-- perfil ativo, sem filtro de clínica, sem pending_results_release). O estado seguro anterior
-- é o do Lote B (20260914130000, linhas 211-323). Reverter só se esta migration quebrar o app.
--
-- === get_psychologist_alerts() (20260928130000_check_in_alert_recent.sql) ===
-- CREATE OR REPLACE FUNCTION public.get_psychologist_alerts()
-- RETURNS JSONB
-- LANGUAGE sql
-- STABLE
-- SECURITY DEFINER
-- SET search_path = public
-- AS $$
--   WITH missing_checkins AS (
--     SELECT
--       p.id        AS patient_id,
--       p.full_name AS patient_name,
--       CASE
--         WHEN MAX(ci.checked_in_at) IS NULL
--           THEN 999
--         ELSE EXTRACT(DAY FROM now() - MAX(ci.checked_in_at))::int
--       END AS days_since_checkin
--     FROM patients p
--     LEFT JOIN patient_check_ins ci ON ci.patient_id = p.id
--     WHERE p.responsible_psychologist_id = auth.uid()
--       AND p.is_active  = true
--       AND p.profile_id IS NOT NULL
--     GROUP BY p.id, p.full_name
--     HAVING MAX(ci.checked_in_at) IS NULL
--         OR MAX(ci.checked_in_at) < now() - interval '7 days'
--     ORDER BY days_since_checkin DESC
--     LIMIT 3
--   ),
--   expiring_invitations AS (
--     SELECT
--       id                              AS invitation_id,
--       COALESCE(full_name, email)      AS patient_name,
--       GREATEST(
--         0,
--         EXTRACT(DAY FROM expires_at - now())::int
--       )                               AS days_until_expiry
--     FROM patient_invitations
--     WHERE responsible_psychologist_id = auth.uid()
--       AND status     = 'pending'
--       AND expires_at >  now()
--       AND expires_at <= now() + interval '3 days'
--     ORDER BY expires_at ASC
--     LIMIT 3
--   ),
--   stale_questionnaires AS (
--     SELECT
--       p.id        AS patient_id,
--       p.full_name AS patient_name,
--       EXTRACT(DAY FROM now() - MIN(qr.created_at))::int AS days_waiting
--     FROM questionnaire_responses qr
--     JOIN patients p ON p.id = qr.patient_id
--     WHERE p.responsible_psychologist_id = auth.uid()
--       AND qr.status     = 'draft'
--       AND qr.created_at < now() - interval '7 days'
--     GROUP BY p.id, p.full_name
--     ORDER BY days_waiting DESC
--     LIMIT 3
--   ),
--   recent_checkins AS (
--     SELECT
--       p.id        AS patient_id,
--       p.full_name AS patient_name,
--       (EXTRACT(EPOCH FROM (now() - MAX(ci.checked_in_at))) / 3600)::int
--                   AS hours_ago
--     FROM patients p
--     JOIN patient_check_ins ci ON ci.patient_id = p.id
--     WHERE p.responsible_psychologist_id = auth.uid()
--       AND p.is_active = true
--       AND ci.checked_in_at >= now() - interval '24 hours'
--     GROUP BY p.id, p.full_name
--     ORDER BY MAX(ci.checked_in_at) DESC
--     LIMIT 5
--   )
--   SELECT jsonb_build_object(
--     'missing_checkins',
--       COALESCE(
--         (SELECT jsonb_agg(to_jsonb(mc)) FROM missing_checkins mc),
--         '[]'::jsonb
--       ),
--     'expiring_invitations',
--       COALESCE(
--         (SELECT jsonb_agg(to_jsonb(ei)) FROM expiring_invitations ei),
--         '[]'::jsonb
--       ),
--     'stale_questionnaires',
--       COALESCE(
--         (SELECT jsonb_agg(to_jsonb(sq)) FROM stale_questionnaires sq),
--         '[]'::jsonb
--       ),
--     'recent_checkins',
--       COALESCE(
--         (SELECT jsonb_agg(to_jsonb(rc)) FROM recent_checkins rc),
--         '[]'::jsonb
--       )
--   );
-- $$;
--
-- REVOKE ALL   ON FUNCTION public.get_psychologist_alerts() FROM PUBLIC, anon;
-- GRANT  EXECUTE ON FUNCTION public.get_psychologist_alerts() TO authenticated;
--
-- === get_patient_vitals(uuid) (20260812120000_patient_vitals_rpc.sql) ===
-- CREATE OR REPLACE FUNCTION public.get_patient_vitals(p_patient_id UUID)
-- RETURNS JSONB
-- LANGUAGE sql
-- STABLE
-- SECURITY DEFINER
-- SET search_path = public
-- AS $$
--   SELECT
--     CASE WHEN NOT public.user_can_access_patient(p_patient_id)
--     THEN jsonb_build_object('access', false)
--     ELSE jsonb_build_object(
--       'access', true,
--       'last_checkin_days',
--         (SELECT
--           CASE
--             WHEN MAX(checked_in_at) IS NULL THEN NULL
--             ELSE EXTRACT(DAY FROM now() - MAX(checked_in_at))::int
--           END
--          FROM patient_check_ins
--          WHERE patient_id = p_patient_id),
--       'active_goals',
--         (SELECT COUNT(*)::int
--          FROM therapy_goals
--          WHERE patient_id = p_patient_id
--            AND status = 'active'),
--       'pending_questionnaires',
--         (SELECT COUNT(*)::int
--          FROM questionnaire_responses
--          WHERE patient_id = p_patient_id
--            AND status = 'draft')
--     )
--     END;
-- $$;
--
-- REVOKE ALL   ON FUNCTION public.get_patient_vitals(UUID) FROM PUBLIC, anon;
-- GRANT  EXECUTE ON FUNCTION public.get_patient_vitals(UUID) TO authenticated;
