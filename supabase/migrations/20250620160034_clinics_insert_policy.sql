-- =============================================================================
-- Migration 034: política INSERT de clínicas para platform_admin
-- =============================================================================

CREATE POLICY clinics_insert_platform_admin
  ON public.clinics
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');
