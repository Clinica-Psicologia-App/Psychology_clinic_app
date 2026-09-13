-- F03: Auth signup is not clinical profile provisioning.
BEGIN;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = pg_catalog
AS $$
BEGIN
  -- Public signup and admin.createUser both pass through GoTrue. Neither
  -- user_metadata nor app_metadata/JWT claims are provisioning instructions.
  -- Safe default: an Auth account without a profile, tenant or application role.
  -- Validated server flows insert profiles explicitly using service_role.
  -- Do not insert, upsert or modify an existing profile from this trigger.
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.handle_new_user() IS
  'Auth signup does not provision profiles. Metadata never grants clinic, role, activation or quotas; validated server flows provision profiles explicitly.';

-- Preserve the existing trigger attachment; no exposed provisioning RPC.
REVOKE ALL ON FUNCTION public.handle_new_user()
  FROM PUBLIC, anon, authenticated, service_role;

COMMIT;
