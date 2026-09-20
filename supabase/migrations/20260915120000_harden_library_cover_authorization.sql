-- Lote E: change authority and enable administrative SELECT atomically.
BEGIN;
CREATE OR REPLACE FUNCTION public.is_library_cover_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
  SELECT current_setting('role', true) IS NOT DISTINCT FROM 'authenticated'
    AND auth.uid() IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.profiles AS actor
      WHERE actor.id = auth.uid()
        AND actor.is_active IS TRUE
        AND actor.role::text = 'platform_admin'
    );
$$;
-- Preserve owner and existing authenticated/service ACLs; service bypasses RLS.
REVOKE ALL ON FUNCTION public.is_library_cover_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_library_cover_admin() TO authenticated;

-- Existing INSERT/UPDATE/DELETE already use this helper and bucket restriction.
DROP POLICY IF EXISTS library_covers_admin_select ON storage.objects;
CREATE POLICY library_covers_admin_select ON storage.objects
FOR SELECT TO authenticated
USING (bucket_id = 'library-covers' AND public.is_library_cover_admin());
COMMIT;
