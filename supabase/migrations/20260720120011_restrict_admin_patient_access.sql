-- Migration: restrict admin from reading individual patient rows.
-- Admins see only aggregate counts via the new RPC below.

-- 1. Remove admin from user_can_access_patient — admin returns false.
CREATE OR REPLACE FUNCTION public.user_can_access_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE public.current_role()
    WHEN 'psychologist' THEN EXISTS (
      SELECT 1
      FROM public.patients AS p
      WHERE p.id = p_patient_id
        AND p.clinic_id = public.current_clinic_id()
        AND p.responsible_psychologist_id = auth.uid()
    )
    WHEN 'patient' THEN EXISTS (
      SELECT 1
      FROM public.patients AS p
      WHERE p.id = p_patient_id
        AND p.profile_id = auth.uid()
    )
    ELSE false
  END;
$$;

-- 2. RPC for admin: returns patient + pending-invitation counts per psychologist.
--    Runs as SECURITY DEFINER so it can read patients even though admin's RLS is blocked.
--    Validates the caller is admin before returning data.
CREATE OR REPLACE FUNCTION public.get_patient_counts_by_psychologist()
RETURNS TABLE(
  psychologist_id   UUID,
  active_count      BIGINT,
  pending_invites   BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.current_role() <> 'admin' THEN
    RAISE EXCEPTION 'Acesso restrito a administradores.';
  END IF;

  RETURN QUERY
  SELECT
    prof.id AS psychologist_id,
    (
      SELECT COUNT(*)
      FROM public.patients p
      WHERE p.responsible_psychologist_id = prof.id
        AND p.clinic_id = public.current_clinic_id()
        AND p.is_active = true
    ) AS active_count,
    (
      SELECT COUNT(*)
      FROM public.patient_invitations pi
      WHERE pi.responsible_psychologist_id = prof.id
        AND pi.status = 'pending'
    ) AS pending_invites
  FROM public.profiles prof
  WHERE prof.clinic_id = public.current_clinic_id()
    AND prof.role = 'psychologist';
END;
$$;
