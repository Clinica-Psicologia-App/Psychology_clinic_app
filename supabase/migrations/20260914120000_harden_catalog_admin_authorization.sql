-- Lote A / N02: only an authenticated, active platform administrator.
BEGIN;

CREATE OR REPLACE FUNCTION public.assert_platform_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
BEGIN
  -- SET ROLE is established by PostgREST, not by editable user metadata.
  -- current_user would be this SECURITY DEFINER function's owner.
  IF current_setting('role', true) IS DISTINCT FROM 'authenticated'
    OR v_actor_id IS NULL
    OR NOT EXISTS (
      SELECT 1
      FROM public.profiles AS actor
      WHERE actor.id = v_actor_id
        AND actor.is_active IS TRUE
        AND actor.role::text = 'platform_admin'
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501',
      MESSAGE = 'Active platform administrator required';
  END IF;
  -- Global catalog administration deliberately has no clinic restriction.
END;
$$;

COMMENT ON FUNCTION public.assert_platform_admin() IS
  'Requires authenticated database role and an existing active platform_admin profile; NULL/missing identity denies before catalog operations.';

-- Only these catalog entry points are affected. Keep existing service_role
-- EXECUTE grants, but the guard still rejects that application database role.
-- Authenticated callers need both EXECUTE and the active-admin guard.
REVOKE EXECUTE ON FUNCTION public.admin_archive_questionnaire(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_archive_questionnaire(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_create_draft_version(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_create_draft_version(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_delete_question(uuid,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_delete_question(uuid,uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_delete_questionnaire_draft(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_delete_questionnaire_draft(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_discard_draft_version(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_discard_draft_version(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_duplicate_questionnaire_as_draft(uuid,text,text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_duplicate_questionnaire_as_draft(uuid,text,text) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_get_questionnaire(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_get_questionnaire(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_list_questionnaires() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_list_questionnaires() TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_publish_questionnaire(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_publish_questionnaire(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_save_question(uuid,uuid,text,text,integer,public.question_answer_type,integer,integer,numeric,boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_question(uuid,uuid,text,text,integer,public.question_answer_type,integer,integer,numeric,boolean) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_save_questionnaire_draft(uuid,text,text,text,text,text,text,text,text,integer,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_save_questionnaire_draft(uuid,text,text,text,text,text,text,text,text,integer,integer) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.assert_platform_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.assert_platform_admin() TO authenticated;

COMMIT;
