-- Harden Storage policies for library covers.
--
-- Storage requests can evaluate RLS before helper functions that depend on
-- profile lookups behave consistently across every request path. Keep the
-- database profile as the source of truth, but allow the authenticated JWT role
-- metadata as a fallback for platform admins uploading covers.

CREATE OR REPLACE FUNCTION public.is_library_cover_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    public.current_role()::TEXT IN ('platform_admin', 'admin'),
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('platform_admin', 'admin'),
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('platform_admin', 'admin'),
    false
  );
$$;

REVOKE ALL ON FUNCTION public.is_library_cover_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_library_cover_admin() TO authenticated;

DROP POLICY IF EXISTS library_covers_admin_insert ON storage.objects;
CREATE POLICY library_covers_admin_insert
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'library-covers'
    AND public.is_library_cover_admin()
  );

DROP POLICY IF EXISTS library_covers_admin_update ON storage.objects;
CREATE POLICY library_covers_admin_update
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'library-covers'
    AND public.is_library_cover_admin()
  )
  WITH CHECK (
    bucket_id = 'library-covers'
    AND public.is_library_cover_admin()
  );

DROP POLICY IF EXISTS library_covers_admin_delete ON storage.objects;
CREATE POLICY library_covers_admin_delete
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'library-covers'
    AND public.is_library_cover_admin()
  );
