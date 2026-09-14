-- Lote A / N02. Run locally with psql -X -v ON_ERROR_STOP=1 as supabase_admin.
-- All fixtures, probe triggers and temporary grants roll back. No seed dependency.
-- SET ROLE models the database role established by PostgREST; claims are simulated.
BEGIN;
-- MUTATION_INJECTION_POINT: runner may insert historical helper here, in memory.
SET LOCAL statement_timeout = '30s';

CREATE FUNCTION pg_temp.assert_true(ok boolean, label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %', label; END IF;
  RAISE NOTICE 'PASS: %', label;
END;
$$;

INSERT INTO public.clinics(id,name) VALUES ('d1000000-0000-0000-0000-000000000001','Lote A clinic A'),('d1000000-0000-0000-0000-000000000002','Lote A clinic B');
INSERT INTO auth.users(id,email) SELECT
 ('d2000000-0000-0000-0000-' || lpad(n::text,12,'0'))::uuid,
 'lote-a-' || n || '@example.test' FROM generate_series(1,9) n;
-- 1 has no profile; 2/3/4 inactive admin/patient/psychologist;
-- 5 patient; 6 psychologist; 7/8 global admins in distinct clinics; 9 legacy admin.
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
SELECT id, CASE WHEN id='d2000000-0000-0000-0000-000000000008' THEN 'd1000000-0000-0000-0000-000000000002'::uuid ELSE 'd1000000-0000-0000-0000-000000000001'::uuid END,
 'Lote A fixture',email,
 CASE right(id::text,1) WHEN '2' THEN 'platform_admin' WHEN '4' THEN 'psychologist'
 WHEN '6' THEN 'psychologist' WHEN '7' THEN 'platform_admin' WHEN '8' THEN 'platform_admin'
 WHEN '9' THEN 'admin' ELSE 'patient' END::public.profile_role,
 right(id::text,1) NOT IN ('2','3','4')
FROM auth.users WHERE id::text LIKE 'd2000000-%' AND id<>'d2000000-0000-0000-0000-000000000001';

INSERT INTO public.questionnaires(id,code,name,is_active,clinical_status)
VALUES ('d3000000-0000-0000-0000-000000000001','LOTE_A_ACTIVE','Lote A active',true,'approved'),
 ('d3000000-0000-0000-0000-000000000002','LOTE_A_DRAFT','Lote A draft',false,'draft');
INSERT INTO public.questionnaire_versions(id,questionnaire_id,version,status,scoring_method,scale_min,scale_max,published_at)
VALUES ('d4000000-0000-0000-0000-000000000001','d3000000-0000-0000-0000-000000000001','v1','active','weighted_sum',1,5,now()),
 ('d4000000-0000-0000-0000-000000000002','d3000000-0000-0000-0000-000000000002','v1','draft','weighted_sum',1,5,NULL);
INSERT INTO public.questions(id,questionnaire_id,questionnaire_version_id,code,text,order_index,answer_type,scale_min,scale_max)
VALUES ('d5000000-0000-0000-0000-000000000001','d3000000-0000-0000-0000-000000000001','d4000000-0000-0000-0000-000000000001','ACTIVE_Q','Active question',0,'likert_scale',1,5),
 ('d5000000-0000-0000-0000-000000000002','d3000000-0000-0000-0000-000000000002','d4000000-0000-0000-0000-000000000002','DRAFT_Q','Draft question',0,'likert_scale',1,5);
INSERT INTO public.question_scoring_rules(questionnaire_version_id,question_id,weight,min_value,max_value)
VALUES ('d4000000-0000-0000-0000-000000000001','d5000000-0000-0000-0000-000000000001',1,1,5),('d4000000-0000-0000-0000-000000000002','d5000000-0000-0000-0000-000000000002',1,1,5);
INSERT INTO public.questionnaire_professional_access(clinic_id,questionnaire_id,professional_id,granted_by,is_enabled)
VALUES ('d1000000-0000-0000-0000-000000000001','d3000000-0000-0000-0000-000000000001','d2000000-0000-0000-0000-000000000006','d2000000-0000-0000-0000-000000000007',true);

CREATE TEMP TABLE lote_cases(label text PRIMARY KEY, statement text, postcondition text);
INSERT INTO lote_cases VALUES
 ('assert_platform_admin',$stmt$SELECT public.assert_platform_admin()::text$stmt$,$check$SELECT true$check$),
 ('admin_archive_questionnaire',$stmt$SELECT public.admin_archive_questionnaire('d3000000-0000-0000-0000-000000000001')::text$stmt$,$check$SELECT NOT is_active AND clinical_status='suspended' AND EXISTS(SELECT 1 FROM public.questionnaire_versions WHERE id='d4000000-0000-0000-0000-000000000001' AND status='archived') AND EXISTS(SELECT 1 FROM public.audit_events WHERE entity_id='d3000000-0000-0000-0000-000000000001' AND action='archive' AND actor_profile_id=$2::uuid) FROM public.questionnaires WHERE id='d3000000-0000-0000-0000-000000000001'$check$),
 ('admin_create_draft_version',$stmt$SELECT public.admin_create_draft_version('d3000000-0000-0000-0000-000000000001')::text$stmt$,$check$SELECT EXISTS(SELECT 1 FROM public.questionnaire_versions WHERE id=$1::uuid AND questionnaire_id='d3000000-0000-0000-0000-000000000001' AND status='draft') AND EXISTS(SELECT 1 FROM public.questions WHERE questionnaire_version_id=$1::uuid) AND EXISTS(SELECT 1 FROM public.question_scoring_rules WHERE questionnaire_version_id=$1::uuid)$check$),
 ('admin_delete_question',$stmt$SELECT public.admin_delete_question('d3000000-0000-0000-0000-000000000002','d5000000-0000-0000-0000-000000000002')::text$stmt$,$check$SELECT NOT EXISTS(SELECT 1 FROM public.questions WHERE id='d5000000-0000-0000-0000-000000000002') AND NOT EXISTS(SELECT 1 FROM public.question_scoring_rules WHERE question_id='d5000000-0000-0000-0000-000000000002')$check$),
 ('admin_delete_questionnaire_draft',$stmt$SELECT public.admin_delete_questionnaire_draft('d3000000-0000-0000-0000-000000000002')::text$stmt$,$check$SELECT NOT EXISTS(SELECT 1 FROM public.questionnaires WHERE id='d3000000-0000-0000-0000-000000000002') AND NOT EXISTS(SELECT 1 FROM public.questionnaire_versions WHERE id='d4000000-0000-0000-0000-000000000002') AND NOT EXISTS(SELECT 1 FROM public.questions WHERE id='d5000000-0000-0000-0000-000000000002')$check$),
 ('admin_discard_draft_version',$stmt$SELECT public.admin_discard_draft_version('d3000000-0000-0000-0000-000000000002')::text$stmt$,$check$SELECT EXISTS(SELECT 1 FROM public.questionnaires WHERE id='d3000000-0000-0000-0000-000000000002') AND NOT EXISTS(SELECT 1 FROM public.questionnaire_versions WHERE id='d4000000-0000-0000-0000-000000000002') AND EXISTS(SELECT 1 FROM public.audit_events WHERE entity_id='d3000000-0000-0000-0000-000000000002' AND action='discard_draft_version' AND actor_profile_id=$2::uuid)$check$),
 ('admin_duplicate_questionnaire_as_draft',$stmt$SELECT public.admin_duplicate_questionnaire_as_draft('d3000000-0000-0000-0000-000000000001','LOTE_A_COPY','copy-v1')::text$stmt$,$check$SELECT EXISTS(SELECT 1 FROM public.questionnaires WHERE id=$1::uuid AND code='LOTE_A_COPY' AND NOT is_active) AND EXISTS(SELECT 1 FROM public.questions WHERE questionnaire_id=$1::uuid) AND EXISTS(SELECT 1 FROM public.questionnaire_versions WHERE questionnaire_id=$1::uuid AND status='draft')$check$),
 ('admin_get_questionnaire',$stmt$SELECT public.admin_get_questionnaire('d3000000-0000-0000-0000-000000000002')::text$stmt$,$check$SELECT ($1::jsonb->'questionnaire'->>'id')='d3000000-0000-0000-0000-000000000002' AND jsonb_array_length($1::jsonb->'questions')=1$check$),
 ('admin_list_questionnaires',$stmt$SELECT count(*)::text FROM public.admin_list_questionnaires() WHERE id IN ('d3000000-0000-0000-0000-000000000001','d3000000-0000-0000-0000-000000000002')$stmt$,$check$SELECT $1::integer=2$check$),
 ('admin_publish_questionnaire',$stmt$SELECT public.admin_publish_questionnaire('d3000000-0000-0000-0000-000000000002')::text$stmt$,$check$SELECT is_active AND clinical_status='approved' AND clinically_approved_by=$2::uuid AND EXISTS(SELECT 1 FROM public.questionnaire_versions WHERE id='d4000000-0000-0000-0000-000000000002' AND status='active' AND published_at IS NOT NULL) AND EXISTS(SELECT 1 FROM public.audit_events WHERE entity_id='d3000000-0000-0000-0000-000000000002' AND action='publish' AND actor_profile_id=$2::uuid) FROM public.questionnaires WHERE id='d3000000-0000-0000-0000-000000000002'$check$),
 ('admin_save_question',$stmt$SELECT public.admin_save_question('d3000000-0000-0000-0000-000000000002','d5000000-0000-0000-0000-000000000002','DRAFT_Q','Edited question',0,'likert_scale',1,5,2,false)::text$stmt$,$check$SELECT text='Edited question' AND EXISTS(SELECT 1 FROM public.question_scoring_rules WHERE question_id='d5000000-0000-0000-0000-000000000002' AND weight=2) FROM public.questions WHERE id='d5000000-0000-0000-0000-000000000002'$check$),
 ('admin_save_questionnaire_draft',$stmt$SELECT public.admin_save_questionnaire_draft(NULL,'LOTE_A_NEW','New draft')::text$stmt$,$check$SELECT EXISTS(SELECT 1 FROM public.questionnaires WHERE id=$1::uuid AND code='LOTE_A_NEW' AND clinical_status='draft') AND EXISTS(SELECT 1 FROM public.questionnaire_versions WHERE questionnaire_id=$1::uuid AND status='draft') AND EXISTS(SELECT 1 FROM public.audit_events WHERE entity_id=$1::uuid AND actor_profile_id=$2::uuid AND action='create_draft')$check$),
 ('admin_save_question_insert',$stmt$SELECT public.admin_save_question('d3000000-0000-0000-0000-000000000002',NULL,'NEW_Q','New question',1)::text$stmt$,$check$SELECT EXISTS(SELECT 1 FROM public.questions WHERE id=$1::uuid AND questionnaire_version_id='d4000000-0000-0000-0000-000000000002') AND EXISTS(SELECT 1 FROM public.question_scoring_rules WHERE question_id=$1::uuid)$check$),
 ('admin_save_questionnaire_draft_update',$stmt$SELECT public.admin_save_questionnaire_draft('d3000000-0000-0000-0000-000000000002','LOTE_A_DRAFT','Edited draft')::text$stmt$,$check$SELECT name='Edited draft' AND EXISTS(SELECT 1 FROM public.audit_events WHERE entity_id='d3000000-0000-0000-0000-000000000002' AND actor_profile_id=$2::uuid AND action='update_draft') FROM public.questionnaires WHERE id='d3000000-0000-0000-0000-000000000002'$check$);
CREATE TEMP TABLE lote_identities(label text, dbrole text, uid uuid);
INSERT INTO lote_identities VALUES
 ('no_profile','authenticated','d2000000-0000-0000-0000-000000000001'),
 ('inactive_admin','authenticated','d2000000-0000-0000-0000-000000000002'),
 ('inactive_patient','authenticated','d2000000-0000-0000-0000-000000000003'),
 ('inactive_psychologist','authenticated','d2000000-0000-0000-0000-000000000004'),
 ('patient','authenticated','d2000000-0000-0000-0000-000000000005'),
 ('psychologist','authenticated','d2000000-0000-0000-0000-000000000006'),
 ('legacy_admin','authenticated','d2000000-0000-0000-0000-000000000009'),
 ('missing_uid','authenticated',NULL),
 ('anon','anon',NULL),
 ('anon_admin_uid','anon','d2000000-0000-0000-0000-000000000007'),
 ('service_role','service_role',NULL),
 ('service_admin_uid','service_role','d2000000-0000-0000-0000-000000000007');

-- Whole affected-table snapshots include dependent catalog rows and audit events.
CREATE FUNCTION pg_temp.catalog_snapshot() RETURNS jsonb LANGUAGE sql AS $$
SELECT jsonb_build_object(
 'questionnaires',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.questionnaires t),
 'questionnaire_versions',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.questionnaire_versions t),
 'questions',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.questions t),
 'question_categories',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.question_categories t),
 'question_category_items',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.question_category_items t),
 'question_scoring_rules',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.question_scoring_rules t),
 'severity_ranges',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.severity_ranges t),
 'questionnaire_professional_access',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.questionnaire_professional_access t),
 'audit_events',(SELECT COALESCE(jsonb_agg(to_jsonb(t) ORDER BY id),'[]') FROM public.audit_events t)
);
$$;

-- A rollback alone cannot prove the guard ran before DML. These statement-level
-- tripwires raise a DIFFERENT SQLSTATE before ANY write, even a zero-row UPDATE.
CREATE FUNCTION pg_temp.reject_early_write() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF current_setting('lote_a.expect_deny',true)='on' THEN
   RAISE EXCEPTION USING ERRCODE='ZA001',MESSAGE='FAIL: DML reached before authorization';
 END IF;
 RETURN NULL;
END;
$$;
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.questionnaires
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.questionnaire_versions
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.questions
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.question_categories
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.question_category_items
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.question_scoring_rules
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.severity_ranges
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.questionnaire_professional_access
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();
CREATE TRIGGER lote_a_write_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.audit_events
 FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.reject_early_write();

-- Validate the effective grants BEFORE granting anon temporary execution below.
DO $$
DECLARE f record;
BEGIN
 PERFORM pg_temp.assert_true((SELECT count(*)=11 FROM pg_proc
  WHERE pronamespace='public'::regnamespace AND prosrc LIKE '%public.assert_platform_admin()%'),
  'exactly 11 final consumers');
 FOR f IN SELECT p.oid,p.proname FROM pg_proc p WHERE p.pronamespace='public'::regnamespace
  AND (p.proname='assert_platform_admin' OR p.prosrc LIKE '%public.assert_platform_admin()%') LOOP
  PERFORM pg_temp.assert_true(
   NOT EXISTS(SELECT 1 FROM aclexplode(COALESCE((SELECT proacl FROM pg_proc WHERE oid=f.oid),acldefault('f',(SELECT proowner FROM pg_proc WHERE oid=f.oid)))) a
    WHERE a.grantee=0 AND a.privilege_type='EXECUTE')
   AND NOT has_function_privilege('anon',f.oid,'EXECUTE')
   AND has_function_privilege('authenticated',f.oid,'EXECUTE')
   AND has_function_privilege('service_role',f.oid,'EXECUTE')
   AND has_function_privilege('postgres',f.oid,'EXECUTE')
   AND has_function_privilege('supabase_admin',f.oid,'EXECUTE'), 'effective grants: '||f.proname);
 END LOOP;
END;
$$;

-- Prove anon is denied by the GUARD too, even if EXECUTE is accidentally restored.
-- These grants exist only in this rollback-only suite.
GRANT EXECUTE ON FUNCTION public.admin_archive_questionnaire(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_create_draft_version(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_delete_question(uuid,uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_delete_questionnaire_draft(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_discard_draft_version(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_duplicate_questionnaire_as_draft(uuid,text,text) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_get_questionnaire(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_list_questionnaires() TO anon;
GRANT EXECUTE ON FUNCTION public.admin_publish_questionnaire(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_save_question(uuid,uuid,text,text,integer,public.question_answer_type,integer,integer,numeric,boolean) TO anon;
GRANT EXECUTE ON FUNCTION public.admin_save_questionnaire_draft(uuid,text,text,text,text,text,text,text,text,integer,integer) TO anon;
GRANT EXECUTE ON FUNCTION public.assert_platform_admin() TO anon;

DO $$
DECLARE i record; c record; before_state jsonb; denial text;
BEGIN
 FOR i IN SELECT * FROM lote_identities ORDER BY label='no_profile' DESC,label LOOP
  FOR c IN SELECT * FROM lote_cases ORDER BY label='assert_platform_admin' DESC,label LOOP
   before_state:=pg_temp.catalog_snapshot();
   BEGIN
    PERFORM set_config('request.jwt.claim.sub','',true);
    PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',i.uid,'role','authenticated',
      'user_metadata',jsonb_build_object('role','platform_admin'),
      'app_metadata',jsonb_build_object('role','platform_admin'))::text,true);
    PERFORM set_config('lote_a.expect_deny','on',true);
    EXECUTE format('SET LOCAL ROLE %I',i.dbrole);
    EXECUTE c.statement;
    RAISE EXCEPTION 'FAIL: % allowed %',c.label,i.label;
   EXCEPTION WHEN insufficient_privilege THEN
    GET STACKED DIAGNOSTICS denial=MESSAGE_TEXT;
   END;
   PERFORM pg_temp.assert_true(denial='Active platform administrator required',
    'guard DENY: '||c.label||' / '||i.label);
   PERFORM pg_temp.assert_true(before_state=pg_temp.catalog_snapshot(),
    'no catalog/audit effects: '||c.label||' / '||i.label);
  END LOOP;
 END LOOP;
END;
$$;

-- Each positive operation is checked before rollback of its subtransaction.
-- Admin B is in another clinic; both must manage the same GLOBAL catalog.
DO $$
DECLARE administrator uuid; c record; answer text; ok boolean;
BEGIN
 FOREACH administrator IN ARRAY ARRAY['d2000000-0000-0000-0000-000000000007'::uuid,'d2000000-0000-0000-0000-000000000008'::uuid] LOOP
  FOR c IN SELECT * FROM lote_cases ORDER BY label LOOP
   BEGIN
    PERFORM set_config('lote_a.expect_deny','off',true);
    PERFORM set_config('request.jwt.claim.sub','',true);
    PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',administrator,'role','authenticated')::text,true);
    SET LOCAL ROLE authenticated;
    EXECUTE c.statement INTO answer;
    RESET ROLE;
    EXECUTE c.postcondition INTO ok USING answer,administrator::text;
    PERFORM pg_temp.assert_true(ok,'admin ALLOW + postcondition: '||c.label||' / '||administrator);
    RAISE EXCEPTION USING ERRCODE='ZP001',MESSAGE='positive case rollback';
   EXCEPTION WHEN SQLSTATE 'ZP001' THEN NULL;
   END;
  END LOOP;
 END LOOP;
END;
$$;

-- Also prove atomicity when a legitimate call fails AFTER its first DML:
-- force a late audit failure, then verify every catalog row is unchanged.
CREATE FUNCTION pg_temp.reject_late_audit() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION USING ERRCODE='ZA002',MESSAGE='injected audit failure'; END;
$$;
CREATE TRIGGER lote_a_late_failure BEFORE INSERT ON public.audit_events
 FOR EACH ROW EXECUTE FUNCTION pg_temp.reject_late_audit();
DO $$
DECLARE before_state jsonb;
BEGIN
 before_state:=pg_temp.catalog_snapshot();
 BEGIN
  PERFORM set_config('request.jwt.claims','{"sub":"d2000000-0000-0000-0000-000000000007","role":"authenticated"}',true);
  SET LOCAL ROLE authenticated;
  PERFORM public.admin_archive_questionnaire('d3000000-0000-0000-0000-000000000001');
  RAISE EXCEPTION 'FAIL: late failure was not reached';
 EXCEPTION WHEN SQLSTATE 'ZA002' THEN NULL;
 END;
 PERFORM pg_temp.assert_true(before_state=pg_temp.catalog_snapshot(),'late failure has no partial catalog/audit effects');
END;
$$;
ROLLBACK;
