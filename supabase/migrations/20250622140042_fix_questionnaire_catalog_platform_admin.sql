-- Catalog administration follows the current platform_admin role model.

CREATE OR REPLACE FUNCTION public.assert_platform_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL
     OR public.current_role()::text NOT IN ('platform_admin', 'admin') THEN
    RAISE EXCEPTION 'Only platform administrators can manage questionnaires'
      USING ERRCODE = '42501';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.assert_platform_admin() FROM PUBLIC;
