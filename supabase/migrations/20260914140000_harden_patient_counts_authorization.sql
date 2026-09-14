-- Lote C1 / N14: preserve global administrative counts; fail closed at entry.
BEGIN;

CREATE OR REPLACE FUNCTION public.get_patient_counts_by_psychologist()
RETURNS TABLE(psychologist_id uuid, active_count bigint, pending_invites bigint)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
BEGIN
  IF current_setting('role', true) IS DISTINCT FROM 'authenticated'
    OR v_actor_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Administrative counts access denied';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles AS actor
    WHERE actor.id = v_actor_id AND actor.is_active IS TRUE
      AND actor.role::text = 'platform_admin'
  ) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Administrative counts access denied';
  END IF;

  -- Global contract: do not filter the administrator or counts by clinic.
  RETURN QUERY
  SELECT prof.id AS psychologist_id,
    (SELECT COUNT(*) FROM public.patients p
     WHERE p.responsible_psychologist_id = prof.id AND p.is_active = true) AS active_count,
    (SELECT COUNT(*) FROM public.patient_invitations pi
     WHERE pi.responsible_psychologist_id = prof.id AND pi.status = 'pending') AS pending_invites
  FROM public.profiles prof
  WHERE prof.role = 'psychologist';
END;
$$;

-- CREATE OR REPLACE preserves the existing owner. Preserve trusted server ACLs.
REVOKE EXECUTE ON FUNCTION public.get_patient_counts_by_psychologist() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_patient_counts_by_psychologist() TO authenticated;
COMMIT;
