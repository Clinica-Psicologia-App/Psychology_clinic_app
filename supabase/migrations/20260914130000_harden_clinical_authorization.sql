-- Lote B: fail closed at clinical RPC boundaries; no historical migration edits.
BEGIN;

CREATE OR REPLACE FUNCTION public.set_patient_active_status(p_patient_id uuid, p_is_active boolean)
 RETURNS public.patients
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_patient public.patients%ROWTYPE;
  v_action TEXT;
  v_current_role TEXT;
  v_actor_id uuid := auth.uid();
  v_clinic_id uuid;
BEGIN
  IF current_setting('role', true) IS DISTINCT FROM 'authenticated'
    OR v_actor_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Clinical lifecycle access denied';
  END IF;
  SELECT actor.role::text, actor.clinic_id INTO v_current_role, v_clinic_id
  FROM public.profiles AS actor
  WHERE actor.id=v_actor_id AND actor.is_active IS TRUE
    AND actor.role::text IN ('psychologist','platform_admin');
  IF NOT FOUND OR (v_current_role='psychologist' AND v_clinic_id IS NULL) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Clinical lifecycle access denied';
  END IF;

  -- The authorized relation is part of the lookup, including the no-op path.
  SELECT patient.* INTO v_patient
  FROM public.patients AS patient
  WHERE patient.id=p_patient_id
    AND (v_current_role='platform_admin' OR (
      patient.clinic_id=v_clinic_id
      AND patient.responsible_psychologist_id=v_actor_id))
    AND (patient.profile_id IS NULL OR EXISTS (
      SELECT 1 FROM public.profiles AS linked
      WHERE linked.id=patient.profile_id AND linked.role::text='patient'
        AND linked.clinic_id=patient.clinic_id))
  FOR UPDATE OF patient;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Clinical lifecycle access denied';
  END IF;
  IF p_is_active IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='22023', MESSAGE='Patient status must not be NULL';
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
$function$;


CREATE OR REPLACE FUNCTION public.current_patient_id()
RETURNS uuid
LANGUAGE plpgsql
STABLE SECURITY DEFINER
SET search_path=pg_catalog
AS $function$
DECLARE
  v_actor_id uuid := auth.uid();
  v_clinic_id uuid;
  v_links uuid[];
  v_patient_id uuid;
BEGIN
  IF current_setting('role',true) IS DISTINCT FROM 'authenticated' OR v_actor_id IS NULL THEN
    RETURN NULL;
  END IF;
  SELECT actor.clinic_id INTO v_clinic_id FROM public.profiles AS actor
  WHERE actor.id=v_actor_id AND actor.is_active IS TRUE AND actor.role::text='patient';
  IF NOT FOUND OR v_clinic_id IS NULL THEN RETURN NULL; END IF;

  -- profile_id has no unique constraint: ambiguous links must not select an arbitrary patient.
  SELECT array_agg(patient.id) INTO v_links FROM public.patients AS patient
  WHERE patient.profile_id=v_actor_id;
  IF cardinality(v_links) IS DISTINCT FROM 1 THEN RETURN NULL; END IF;
  SELECT patient.id INTO v_patient_id FROM public.patients AS patient
  WHERE patient.id=v_links[1] AND patient.clinic_id=v_clinic_id AND patient.is_active IS TRUE;
  RETURN v_patient_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_patients_data_completion()
 RETURNS TABLE(patient_id uuid, perfil boolean, queixa boolean, areas boolean, historia boolean, familia boolean, questionarios boolean)
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
  RETURN QUERY
SELECT
    p.id AS patient_id,
    (
      p.birth_date IS NOT NULL
      OR NULLIF(btrim(p.occupation), '') IS NOT NULL
    ) AS perfil,
    EXISTS (
      SELECT 1 FROM public.patient_intake pi
      WHERE pi.patient_id = p.id
        AND NULLIF(btrim(pi.reason_for_seeking), '') IS NOT NULL
    ) AS queixa,
    EXISTS (
      SELECT 1 FROM public.patient_life_areas la
      WHERE la.patient_id = p.id
        AND la.score IS NOT NULL
    ) AS areas,
    EXISTS (
      SELECT 1 FROM public.patient_timeline_events te
      WHERE te.patient_id = p.id AND te.clinic_id = p.clinic_id
    ) AS historia,
    EXISTS (
      SELECT 1 FROM public.genogram_people gp
      WHERE gp.patient_id = p.id AND gp.clinic_id = p.clinic_id
        AND gp.relationship_to_patient IS NOT NULL
        AND gp.relationship_to_patient <> 'self'
    ) AS familia,
    EXISTS (
      SELECT 1 FROM public.questionnaire_responses qr
      WHERE qr.patient_id = p.id AND qr.clinic_id = p.clinic_id
        AND qr.status = 'completed'
    ) AS questionarios
  FROM public.patients p
  WHERE p.responsible_psychologist_id = v_actor_id
    AND p.clinic_id = v_clinic_id
    AND p.is_active = true;
END;
$function$;


CREATE OR REPLACE FUNCTION public.get_patients_with_pending_results_release()
 RETURNS TABLE(patient_id uuid)
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
  RETURN QUERY
SELECT DISTINCT p.id
  FROM public.questionnaire_responses qr
  JOIN public.patients p ON p.id = qr.patient_id AND qr.clinic_id = p.clinic_id
  WHERE p.responsible_psychologist_id = v_actor_id
    AND p.clinic_id = v_clinic_id
    AND p.is_active            = true
    AND qr.status               = 'completed'
    AND p.results_released_at IS NULL;
END;
$function$;


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
  )
  );
END;
$function$;


CREATE OR REPLACE FUNCTION public.get_my_library()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_patient UUID;
  v_result JSONB;
BEGIN
  v_patient := public.current_patient_id();
  IF v_patient IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Active linked patient required';
  END IF;

  SELECT COALESCE(jsonb_agg(item ORDER BY item->>'indicated_at' DESC), '[]'::jsonb)
  INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'indication_id', li.id,
      'status', li.status,
      'objective', li.objective,
      'scope', li.scope,
      'indicated_at', li.indicated_at,
      'watched_at', li.watched_at,
      'activation_0_10', li.activation_0_10,
      'share_responses', li.share_responses,
      'patient_responses', li.patient_responses,
      'work', jsonb_build_object(
        'id', w.id,
        'display_title', w.display_title,
        'work_type', w.work_type,
        'is_animation', w.is_animation,
        'year', w.year,
        'genres', w.genres,
        'duration', w.duration,
        'seasons', w.seasons,
        'rating', w.rating,
        'synopsis', w.synopsis,
        'cover_url', w.cover_url,
        'intensity', w.intensity,
        'patient_layer', w.patient_layer
      )
    ) AS item
    FROM public.library_indications li
    JOIN public.library_works w ON w.id = li.work_id
    WHERE li.patient_id = v_patient
      AND li.clinic_id = public.current_clinic_id()
      AND w.is_published
  ) sub;

  RETURN v_result;
END;
$function$;


-- This definer view is a read-only patient projection, not a clinical editing API.
CREATE OR REPLACE VIEW public.patient_shared_personality
WITH (security_invoker=false) AS
SELECT id,patient_id,instrument,applied_on,
  public.personality_results_public(results) AS results,updated_at
FROM public.personality_assessments
WHERE shared_with_patient IS TRUE
  AND patient_id=public.current_patient_id()
  AND clinic_id=public.current_clinic_id();
REVOKE ALL ON public.patient_shared_personality FROM PUBLIC, anon;
REVOKE ALL ON public.patient_shared_personality FROM authenticated;
GRANT SELECT ON public.patient_shared_personality TO authenticated;

REVOKE EXECUTE ON FUNCTION public.current_patient_id() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.current_patient_id() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_my_library() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_library() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_patients_data_completion() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_patients_data_completion() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_patients_with_pending_results_release() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_patients_with_pending_results_release() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.get_psychologist_alerts() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_psychologist_alerts() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.set_patient_active_status(uuid,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_patient_active_status(uuid,boolean) TO authenticated;

COMMIT;
