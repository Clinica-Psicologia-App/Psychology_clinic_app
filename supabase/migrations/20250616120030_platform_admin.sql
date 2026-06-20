-- =============================================================================
-- Migration 030: administrador global da plataforma
-- =============================================================================

ALTER TYPE public.profile_role ADD VALUE IF NOT EXISTS 'platform_admin';

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_role()::TEXT IN ('platform_admin', 'admin', 'psychologist');
$$;

CREATE OR REPLACE FUNCTION public.user_can_access_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE public.current_role()::TEXT
    WHEN 'platform_admin' THEN EXISTS (
      SELECT 1
      FROM public.patients AS p
      WHERE p.id = p_patient_id
    )
    WHEN 'admin' THEN EXISTS (
      SELECT 1
      FROM public.patients AS p
      WHERE p.id = p_patient_id
        AND p.clinic_id = public.current_clinic_id()
    )
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

DROP POLICY IF EXISTS clinics_select_own ON public.clinics;
CREATE POLICY clinics_select_own
  ON public.clinics
  FOR SELECT
  TO authenticated
  USING (
    public.current_role()::TEXT = 'platform_admin'
    OR id = public.current_clinic_id()
  );

DROP POLICY IF EXISTS clinics_update_admin ON public.clinics;
CREATE POLICY clinics_update_admin
  ON public.clinics
  FOR UPDATE
  TO authenticated
  USING (
    public.current_role()::TEXT = 'platform_admin'
    OR (
      id = public.current_clinic_id()
      AND public.current_role() = 'admin'
    )
  )
  WITH CHECK (
    public.current_role()::TEXT = 'platform_admin'
    OR (
      id = public.current_clinic_id()
      AND public.current_role() = 'admin'
    )
  );

DROP POLICY IF EXISTS profiles_select_clinic_or_self ON public.profiles;
CREATE POLICY profiles_select_clinic_or_self
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    public.current_role()::TEXT = 'platform_admin'
    OR clinic_id = public.current_clinic_id()
    OR id = auth.uid()
  );

DROP POLICY IF EXISTS profiles_update_self_or_admin ON public.profiles;
CREATE POLICY profiles_update_self_or_admin
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR public.current_role()::TEXT = 'platform_admin'
    OR (
      clinic_id = public.current_clinic_id()
      AND public.current_role() = 'admin'
    )
  )
  WITH CHECK (
    id = auth.uid()
    OR public.current_role()::TEXT = 'platform_admin'
    OR (
      clinic_id = public.current_clinic_id()
      AND public.current_role() = 'admin'
    )
  );

DROP POLICY IF EXISTS profiles_insert_admin ON public.profiles;
CREATE POLICY profiles_insert_admin
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    (
      public.current_role()::TEXT = 'platform_admin'
      OR (
        clinic_id = public.current_clinic_id()
        AND public.current_role() = 'admin'
      )
    )
    AND EXISTS (SELECT 1 FROM auth.users AS u WHERE u.id = profiles.id)
  );
