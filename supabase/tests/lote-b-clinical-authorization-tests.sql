-- Lote B: local, rollback-only fixtures. Execute with psql -X -v ON_ERROR_STOP=1.
BEGIN;
-- MUTATION_INJECTION_POINT
SET LOCAL statement_timeout='30s';
CREATE FUNCTION pg_temp.check_true(ok boolean,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END;
$$;
INSERT INTO public.clinics(id,name) VALUES ('e1000000-0000-0000-0000-000000000001','Lote B A'),('e1000000-0000-0000-0000-000000000002','Lote B B');
INSERT INTO auth.users(id,email)
SELECT ('e2000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,'lote-b-'||n||'@example.test'
FROM generate_series(1,15) n;
-- 1 admin; 2 owning psychologist; 3 non-owning psychologist; 4 inactive psychologist;
-- 5 patient; 6 inactive patient; 7 missing profile; 8/9 psychologist/patient clinic B;
-- 10 inactive admin; 11 unlinked patient; 12 legacy admin; 13 reserved patient;
-- 14 psychologist with a patient link (wrong role); 15 active profile/inactive patient.
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
SELECT id, CASE WHEN right(id::text,2) IN ('08','09') THEN 'e1000000-0000-0000-0000-000000000002'::uuid ELSE 'e1000000-0000-0000-0000-000000000001'::uuid END,
 'Lote B fixture',email,
 CASE right(id::text,2) WHEN '01' THEN 'platform_admin' WHEN '10' THEN 'platform_admin'
 WHEN '02' THEN 'psychologist' WHEN '03' THEN 'psychologist' WHEN '04' THEN 'psychologist'
 WHEN '08' THEN 'psychologist' WHEN '14' THEN 'psychologist' WHEN '12' THEN 'admin'
 ELSE 'patient' END::public.profile_role,
 right(id::text,2) NOT IN ('04','06','10')
FROM auth.users WHERE id::text LIKE 'e2000000-%' AND id<>'e2000000-0000-0000-0000-000000000007';

INSERT INTO public.patients(id,clinic_id,profile_id,responsible_psychologist_id,full_name,birth_date)
VALUES
 ('e3000000-0000-0000-0000-000000000001','e1000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000005','e2000000-0000-0000-0000-000000000002','Lote B own','1990-01-01'),
 ('e3000000-0000-0000-0000-000000000002','e1000000-0000-0000-0000-000000000001',NULL,'e2000000-0000-0000-0000-000000000002','Lote B no login',NULL),
 ('e3000000-0000-0000-0000-000000000003','e1000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000006','e2000000-0000-0000-0000-000000000004','Lote B inactive profiles','1990-01-01'),
 ('e3000000-0000-0000-0000-000000000004','e1000000-0000-0000-0000-000000000002','e2000000-0000-0000-0000-000000000009','e2000000-0000-0000-0000-000000000008','Lote B other clinic','1990-01-01'),
 ('e3000000-0000-0000-0000-000000000007','e1000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000014','e2000000-0000-0000-0000-000000000002','Lote B wrong linked role',NULL),
 ('e3000000-0000-0000-0000-000000000008','e1000000-0000-0000-0000-000000000001',NULL,NULL,'Lote B no owner',NULL),
 ('e3000000-0000-0000-0000-000000000009','e1000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000015','e2000000-0000-0000-0000-000000000002','Lote B inactive record',NULL);
UPDATE public.patients SET is_active=false,inactivated_at=now(),inactivated_by='e2000000-0000-0000-0000-000000000001' WHERE id='e3000000-0000-0000-0000-000000000009';

INSERT INTO public.questionnaires(id,code,name,is_active) VALUES ('e4000000-0000-0000-0000-000000000001','LOTE_B','Lote B questionnaire',true);
INSERT INTO public.questionnaire_versions(id,questionnaire_id,version,status,published_at)
VALUES ('e4000000-0000-0000-0000-000000000002','e4000000-0000-0000-0000-000000000001','v1','active',now());
INSERT INTO public.questionnaire_responses(clinic_id,patient_id,questionnaire_id,questionnaire_version_id,status,created_at,completed_at)
SELECT clinic_id,id,'e4000000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000002',
 'completed',now()-interval '10 days',now()-interval '9 days'
FROM public.patients WHERE id IN ('e3000000-0000-0000-0000-000000000001','e3000000-0000-0000-0000-000000000003','e3000000-0000-0000-0000-000000000004');
INSERT INTO public.questionnaire_responses(clinic_id,patient_id,questionnaire_id,questionnaire_version_id,status,created_at)
SELECT clinic_id,id,'e4000000-0000-0000-0000-000000000001','e4000000-0000-0000-0000-000000000002',
 'draft',now()-interval '10 days'
FROM public.patients WHERE id IN ('e3000000-0000-0000-0000-000000000001','e3000000-0000-0000-0000-000000000003','e3000000-0000-0000-0000-000000000004');
INSERT INTO public.patient_invitations(clinic_id,invited_by,responsible_psychologist_id,email,token_hash,expires_at)
SELECT clinic_id,id,id,'lote-b-invite-'||right(id::text,2)||'@example.test','lote-b-'||id,now()+interval '2 days'
FROM public.profiles WHERE id IN ('e2000000-0000-0000-0000-000000000002','e2000000-0000-0000-0000-000000000004','e2000000-0000-0000-0000-000000000008');

INSERT INTO public.library_works(id,display_title,work_type,patient_layer,psychologist_layer)
VALUES ('e5000000-0000-0000-0000-000000000001','Lote B work','film','{"safe":"patient"}','{"secret":"staff"}');
INSERT INTO public.library_indications(clinic_id,patient_id,work_id,psychologist_id,patient_responses)
SELECT clinic_id,id,'e5000000-0000-0000-0000-000000000001',responsible_psychologist_id,'{"answer":"private"}'
FROM public.patients WHERE id IN ('e3000000-0000-0000-0000-000000000001','e3000000-0000-0000-0000-000000000003','e3000000-0000-0000-0000-000000000004');
INSERT INTO public.personality_assessments(clinic_id,patient_id,shared_with_patient,results)
SELECT clinic_id,id,true,'{"domains":{"A":{"score":80,"classification":"high","facets":{"A1":{"score":70,"classification":"high"}}}}}'
FROM public.patients WHERE id IN ('e3000000-0000-0000-0000-000000000001','e3000000-0000-0000-0000-000000000003','e3000000-0000-0000-0000-000000000004');
INSERT INTO public.personality_assessments(clinic_id,patient_id,shared_with_patient)
VALUES ('e1000000-0000-0000-0000-000000000001','e3000000-0000-0000-0000-000000000001',false);

CREATE FUNCTION pg_temp.snapshot() RETURNS jsonb LANGUAGE sql AS $$
SELECT jsonb_build_array(
 (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.patients t),
 (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.profiles t),
 (SELECT jsonb_agg(to_jsonb(t) ORDER BY id) FROM public.audit_events t));
$$;
CREATE FUNCTION pg_temp.no_early_write() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF current_setting('lote_b.deny',true)='on' THEN
   RAISE EXCEPTION USING ERRCODE='ZB001',MESSAGE='FAIL: write before authorization';
 END IF;
 RETURN NULL;
END;
$$;
CREATE TRIGGER lote_b_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.patients FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.no_early_write();
CREATE TRIGGER lote_b_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.profiles FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.no_early_write();
CREATE TRIGGER lote_b_probe BEFORE INSERT OR UPDATE OR DELETE OR TRUNCATE ON public.audit_events FOR EACH STATEMENT EXECUTE FUNCTION pg_temp.no_early_write();

-- Verify real ACLs, then temporarily allow anon to exercise the guards themselves.
DO $$
DECLARE f record;
BEGIN
 FOR f IN SELECT oid,proname FROM pg_proc WHERE pronamespace='public'::regnamespace
 AND proname IN ('set_patient_active_status','get_patients_data_completion',
 'get_patients_with_pending_results_release','get_psychologist_alerts','get_my_library','current_patient_id') LOOP
  PERFORM pg_temp.check_true(
   NOT EXISTS(SELECT 1 FROM aclexplode(coalesce((SELECT proacl FROM pg_proc WHERE oid=f.oid),acldefault('f',(SELECT proowner FROM pg_proc WHERE oid=f.oid)))) a WHERE grantee=0 AND privilege_type='EXECUTE')
   AND NOT has_function_privilege('anon',f.oid,'EXECUTE')
   AND has_function_privilege('authenticated',f.oid,'EXECUTE')
   AND has_function_privilege('service_role',f.oid,'EXECUTE')
   AND has_function_privilege('postgres',f.oid,'EXECUTE')
   AND has_function_privilege('supabase_admin',f.oid,'EXECUTE'),
   'grants '||f.proname);
  EXECUTE format('GRANT EXECUTE ON FUNCTION %s TO anon',f.oid::regprocedure);
 END LOOP;
 PERFORM pg_temp.check_true(NOT has_table_privilege('anon','public.patient_shared_personality','SELECT')
  AND has_table_privilege('authenticated','public.patient_shared_personality','SELECT')
  AND NOT has_table_privilege('authenticated','public.patient_shared_personality','INSERT')
  AND NOT has_table_privilege('authenticated','public.patient_shared_personality','UPDATE')
  AND NOT has_table_privilege('authenticated','public.patient_shared_personality','DELETE'),'view SELECT only');
 GRANT SELECT ON public.patient_shared_personality TO anon;
END;
$$;

-- A successful case returns boolean true. Every subtransaction rolls back changes.
CREATE FUNCTION pg_temp.run_case(label text,actor uuid,dbrole text,statement text,denial text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE result text; caught text; before_state jsonb;
BEGIN
 before_state:=pg_temp.snapshot();
 BEGIN
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role','authenticated',
    'user_metadata',jsonb_build_object('role','platform_admin'),
    'app_metadata',jsonb_build_object('role','platform_admin'))::text,true);
  PERFORM set_config('lote_b.deny',CASE WHEN denial IS NULL THEN 'off' ELSE 'on' END,true);
  EXECUTE format('SET LOCAL ROLE %I',dbrole);
  IF denial IS NOT NULL THEN
   BEGIN
    EXECUTE statement;
    RAISE EXCEPTION 'FAIL: % allowed forbidden caller',label;
   EXCEPTION WHEN insufficient_privilege THEN
    GET STACKED DIAGNOSTICS caught=MESSAGE_TEXT;
   END;
   RESET ROLE;
   PERFORM pg_temp.check_true(caught=denial OR denial='ANY_42501','DENY '||label);
   PERFORM pg_temp.check_true(before_state=pg_temp.snapshot(),'no writes/audit '||label);
  ELSE
   EXECUTE statement INTO result;
   RESET ROLE;
   PERFORM pg_temp.check_true(result::boolean,label);
  END IF;
  RAISE EXCEPTION USING ERRCODE='ZB002',MESSAGE='case rollback';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
 END;
END;
$$;

CREATE TEMP TABLE callers(label text,actor uuid,dbrole text);
INSERT INTO callers VALUES
 ('anon',NULL,'anon'),('missing UID',NULL,'authenticated'),
 ('missing profile','e2000000-0000-0000-0000-000000000007','authenticated'),
 ('inactive patient','e2000000-0000-0000-0000-000000000006','authenticated'),('inactive psychologist','e2000000-0000-0000-0000-000000000004','authenticated'),
 ('patient','e2000000-0000-0000-0000-000000000005','authenticated'),('psychologist','e2000000-0000-0000-0000-000000000002','authenticated'),
 ('non-owner','e2000000-0000-0000-0000-000000000003','authenticated'),('admin','e2000000-0000-0000-0000-000000000001','authenticated'),
 ('other clinic psychologist','e2000000-0000-0000-0000-000000000008','authenticated'),('other clinic patient','e2000000-0000-0000-0000-000000000009','authenticated'),
 ('inactive admin','e2000000-0000-0000-0000-000000000010','authenticated'),('unlinked patient','e2000000-0000-0000-0000-000000000011','authenticated'),
 ('legacy admin','e2000000-0000-0000-0000-000000000012','authenticated'),('wrong linked role','e2000000-0000-0000-0000-000000000014','authenticated'),
 ('inactive patient record','e2000000-0000-0000-0000-000000000015','authenticated'),
 ('service role',NULL,'service_role'),('service admin UID','e2000000-0000-0000-0000-000000000001','service_role'),
 ('service patient UID','e2000000-0000-0000-0000-000000000005','service_role'),('anon patient UID','e2000000-0000-0000-0000-000000000005','anon');

DO $$
DECLARE c record; desired boolean; fn text; own_patient uuid;
BEGIN
 FOR c IN SELECT * FROM callers ORDER BY label='missing profile' DESC,label LOOP
  IF c.actor IS DISTINCT FROM 'e2000000-0000-0000-0000-000000000001'::uuid AND c.actor IS DISTINCT FROM 'e2000000-0000-0000-0000-000000000002'::uuid
     OR c.dbrole<>'authenticated' THEN
   FOREACH desired IN ARRAY ARRAY[true,false] LOOP
    PERFORM pg_temp.run_case('N01 unlinked target status='||desired||' / '||c.label,c.actor,c.dbrole,
     format('SELECT public.set_patient_active_status(%L,%L)','e3000000-0000-0000-0000-000000000002',desired),'Clinical lifecycle access denied');
    PERFORM pg_temp.run_case('N01 linked target status='||desired||' / '||c.label,c.actor,c.dbrole,
     format('SELECT public.set_patient_active_status(%L,%L)','e3000000-0000-0000-0000-000000000001',desired),'Clinical lifecycle access denied');
   END LOOP;
  END IF;
 END LOOP;
END;
$$;

DO $$
DECLARE c record; fn text;
BEGIN
 FOR c IN SELECT * FROM callers ORDER BY label='inactive psychologist' DESC,label LOOP
  IF c.dbrole<>'authenticated' OR c.actor IS NULL OR c.actor NOT IN ('e2000000-0000-0000-0000-000000000002','e2000000-0000-0000-0000-000000000003','e2000000-0000-0000-0000-000000000008','e2000000-0000-0000-0000-000000000014') THEN
   FOREACH fn IN ARRAY ARRAY['get_patients_data_completion','get_patients_with_pending_results_release','get_psychologist_alerts'] LOOP
    PERFORM pg_temp.run_case(fn||' / '||c.label,c.actor,c.dbrole,format('SELECT public.%I()',fn),'Active psychologist required');
   END LOOP;
  END IF;
 END LOOP;
END;
$$;

DO $$
DECLARE c record;
BEGIN
 FOR c IN SELECT * FROM callers ORDER BY label='inactive patient' DESC,label LOOP
  IF c.dbrole<>'authenticated' OR c.actor IS NULL OR c.actor NOT IN ('e2000000-0000-0000-0000-000000000005','e2000000-0000-0000-0000-000000000009') THEN
   PERFORM pg_temp.run_case('helper NULL / '||c.label,c.actor,c.dbrole,'SELECT public.current_patient_id() IS NULL');
   PERFORM pg_temp.run_case('view empty / '||c.label,c.actor,c.dbrole,'SELECT count(*)=0 FROM public.patient_shared_personality');
   PERFORM pg_temp.run_case('library / '||c.label,c.actor,c.dbrole,'SELECT public.get_my_library()','Active linked patient required');
  END IF;
 END LOOP;
END;
$$;

-- Positive patients see only their own published, shared resources.
SELECT pg_temp.run_case('helper own 5','e2000000-0000-0000-0000-000000000005','authenticated',$stmt$SELECT public.current_patient_id()='e3000000-0000-0000-0000-000000000001'::uuid$stmt$);
SELECT pg_temp.run_case('library own 5','e2000000-0000-0000-0000-000000000005','authenticated',$stmt$SELECT jsonb_array_length(public.get_my_library())=1 AND (public.get_my_library()->0->'work'->'patient_layer'->>'safe')='patient' AND NOT ((public.get_my_library()->0->'work') ? 'psychologist_layer')$stmt$);
SELECT pg_temp.run_case('view own sanitized 5','e2000000-0000-0000-0000-000000000005','authenticated',$stmt$SELECT count(*)=1 AND bool_and(patient_id='e3000000-0000-0000-0000-000000000001'::uuid AND NOT (results->'domains'->'A' ? 'score') AND NOT (results->'domains'->'A'->'facets'->'A1' ? 'score')) FROM public.patient_shared_personality$stmt$);
SELECT pg_temp.run_case('base table protected 5','e2000000-0000-0000-0000-000000000005','authenticated',$stmt$SELECT count(*)=0 FROM public.personality_assessments$stmt$);
SELECT pg_temp.run_case('view rejects UPDATE 5','e2000000-0000-0000-0000-000000000005','authenticated',$stmt$UPDATE public.patient_shared_personality SET instrument='changed'$stmt$,'ANY_42501');
SELECT pg_temp.run_case('view rejects DELETE 5','e2000000-0000-0000-0000-000000000005','authenticated',$stmt$DELETE FROM public.patient_shared_personality$stmt$,'ANY_42501');
SELECT pg_temp.run_case('view rejects INSERT 5','e2000000-0000-0000-0000-000000000005','authenticated',$stmt$INSERT INTO public.patient_shared_personality(patient_id,instrument) VALUES ('e3000000-0000-0000-0000-000000000001','changed')$stmt$,'ANY_42501');
SELECT pg_temp.run_case('helper own 9','e2000000-0000-0000-0000-000000000009','authenticated',$stmt$SELECT public.current_patient_id()='e3000000-0000-0000-0000-000000000004'::uuid$stmt$);
SELECT pg_temp.run_case('library own 9','e2000000-0000-0000-0000-000000000009','authenticated',$stmt$SELECT jsonb_array_length(public.get_my_library())=1 AND (public.get_my_library()->0->'work'->'patient_layer'->>'safe')='patient' AND NOT ((public.get_my_library()->0->'work') ? 'psychologist_layer')$stmt$);
SELECT pg_temp.run_case('view own sanitized 9','e2000000-0000-0000-0000-000000000009','authenticated',$stmt$SELECT count(*)=1 AND bool_and(patient_id='e3000000-0000-0000-0000-000000000004'::uuid AND NOT (results->'domains'->'A' ? 'score') AND NOT (results->'domains'->'A'->'facets'->'A1' ? 'score')) FROM public.patient_shared_personality$stmt$);
SELECT pg_temp.run_case('base table protected 9','e2000000-0000-0000-0000-000000000009','authenticated',$stmt$SELECT count(*)=0 FROM public.personality_assessments$stmt$);
SELECT pg_temp.run_case('view rejects UPDATE 9','e2000000-0000-0000-0000-000000000009','authenticated',$stmt$UPDATE public.patient_shared_personality SET instrument='changed'$stmt$,'ANY_42501');
SELECT pg_temp.run_case('view rejects DELETE 9','e2000000-0000-0000-0000-000000000009','authenticated',$stmt$DELETE FROM public.patient_shared_personality$stmt$,'ANY_42501');
SELECT pg_temp.run_case('view rejects INSERT 9','e2000000-0000-0000-0000-000000000009','authenticated',$stmt$INSERT INTO public.patient_shared_personality(patient_id,instrument) VALUES ('e3000000-0000-0000-0000-000000000004','changed')$stmt$,'ANY_42501');
SELECT pg_temp.run_case('completion own 2','e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT count(*)>=1 AND bool_or(patient_id='e3000000-0000-0000-0000-000000000001'::uuid AND perfil AND questionarios) AND NOT bool_or(patient_id='e3000000-0000-0000-0000-000000000004'::uuid) FROM public.get_patients_data_completion()$stmt$);
SELECT pg_temp.run_case('pending own 2','e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT count(*)=1 AND bool_and(patient_id='e3000000-0000-0000-0000-000000000001'::uuid) FROM public.get_patients_with_pending_results_release()$stmt$);
SELECT pg_temp.run_case('alerts own 2','e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT jsonb_array_length(a->'missing_checkins')>=1 AND (a->'pending_results_release'->0->>'patient_id')='e3000000-0000-0000-0000-000000000001' AND jsonb_array_length(a->'stale_questionnaires')=1 AND jsonb_array_length(a->'expiring_invitations')=1 FROM (SELECT public.get_psychologist_alerts() a) q$stmt$);
SELECT pg_temp.run_case('completion own 8','e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT count(*)>=1 AND bool_or(patient_id='e3000000-0000-0000-0000-000000000004'::uuid AND perfil AND questionarios) AND NOT bool_or(patient_id='e3000000-0000-0000-0000-000000000001'::uuid) FROM public.get_patients_data_completion()$stmt$);
SELECT pg_temp.run_case('pending own 8','e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT count(*)=1 AND bool_and(patient_id='e3000000-0000-0000-0000-000000000004'::uuid) FROM public.get_patients_with_pending_results_release()$stmt$);
SELECT pg_temp.run_case('alerts own 8','e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT jsonb_array_length(a->'missing_checkins')>=1 AND (a->'pending_results_release'->0->>'patient_id')='e3000000-0000-0000-0000-000000000004' AND jsonb_array_length(a->'stale_questionnaires')=1 AND jsonb_array_length(a->'expiring_invitations')=1 FROM (SELECT public.get_psychologist_alerts() a) q$stmt$);
SELECT pg_temp.run_case('non-owner empty get_patients_data_completion 3','e2000000-0000-0000-0000-000000000003','authenticated',$stmt$SELECT count(*)=0 FROM public.get_patients_data_completion()$stmt$);
SELECT pg_temp.run_case('non-owner empty get_patients_with_pending_results_release 3','e2000000-0000-0000-0000-000000000003','authenticated',$stmt$SELECT count(*)=0 FROM public.get_patients_with_pending_results_release()$stmt$);
SELECT pg_temp.run_case('non-owner alerts empty 3','e2000000-0000-0000-0000-000000000003','authenticated',$stmt$SELECT public.get_psychologist_alerts()='{"missing_checkins":[],"expiring_invitations":[],"stale_questionnaires":[],"pending_results_release":[]}'::jsonb$stmt$);
SELECT pg_temp.run_case('non-owner empty get_patients_data_completion 14','e2000000-0000-0000-0000-000000000014','authenticated',$stmt$SELECT count(*)=0 FROM public.get_patients_data_completion()$stmt$);
SELECT pg_temp.run_case('non-owner empty get_patients_with_pending_results_release 14','e2000000-0000-0000-0000-000000000014','authenticated',$stmt$SELECT count(*)=0 FROM public.get_patients_with_pending_results_release()$stmt$);
SELECT pg_temp.run_case('non-owner alerts empty 14','e2000000-0000-0000-0000-000000000014','authenticated',$stmt$SELECT public.get_psychologist_alerts()='{"missing_checkins":[],"expiring_invitations":[],"stale_questionnaires":[],"pending_results_release":[]}'::jsonb$stmt$);

-- Real lifecycle transitions; check linked login, audit and idempotent status.
DO $$
DECLARE pair record; row_after public.patients; audits bigint;
BEGIN
 FOR pair IN SELECT * FROM (VALUES
 ('e2000000-0000-0000-0000-000000000002'::uuid,'e3000000-0000-0000-0000-000000000001'::uuid),
 ('e2000000-0000-0000-0000-000000000002'::uuid,'e3000000-0000-0000-0000-000000000002'::uuid),
 ('e2000000-0000-0000-0000-000000000008'::uuid,'e3000000-0000-0000-0000-000000000004'::uuid),
 ('e2000000-0000-0000-0000-000000000001'::uuid,'e3000000-0000-0000-0000-000000000004'::uuid),
 ('e2000000-0000-0000-0000-000000000001'::uuid,'e3000000-0000-0000-0000-000000000008'::uuid)) pairs(actor,patient) LOOP
  BEGIN
   PERFORM set_config('request.jwt.claim.sub','',true);
   PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',pair.actor,'role','authenticated')::text,true);
   PERFORM set_config('lote_b.deny','off',true);
   SET LOCAL ROLE authenticated;
   SELECT * INTO row_after FROM public.set_patient_active_status(pair.patient,false);
   RESET ROLE;
   PERFORM pg_temp.check_true(NOT row_after.is_active AND row_after.inactivated_by=pair.actor
    AND (row_after.profile_id IS NULL OR EXISTS(SELECT 1 FROM public.profiles WHERE id=row_after.profile_id AND NOT is_active)),
    'lifecycle inactivate/profile '||pair.actor||' / '||pair.patient);
   SET LOCAL ROLE authenticated;
   SELECT * INTO row_after FROM public.set_patient_active_status(pair.patient,true);
   RESET ROLE;
   PERFORM pg_temp.check_true(row_after.is_active AND row_after.inactivated_at IS NULL AND row_after.inactivated_by IS NULL
    AND (row_after.profile_id IS NULL OR EXISTS(SELECT 1 FROM public.profiles WHERE id=row_after.profile_id AND is_active)),
    'lifecycle reactivate/profile '||pair.actor||' / '||pair.patient);
   SELECT count(*) INTO audits FROM public.audit_events WHERE patient_id=pair.patient
    AND action IN ('patient_inactivated','patient_reactivated') AND actor_profile_id=pair.actor;
   PERFORM pg_temp.check_true(audits=2,'lifecycle audit actor/actions '||pair.actor||' / '||pair.patient);
   SET LOCAL ROLE authenticated;
   PERFORM public.set_patient_active_status(pair.patient,true);
   RESET ROLE;
   PERFORM pg_temp.check_true((SELECT count(*)=audits FROM public.audit_events WHERE patient_id=pair.patient
    AND action IN ('patient_inactivated','patient_reactivated') AND actor_profile_id=pair.actor),
    'lifecycle no-op has no false status audit '||pair.actor||' / '||pair.patient);
   RAISE EXCEPTION USING ERRCODE='ZB002';
  EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
  END;
 END LOOP;
END;
$$;

-- Mutate relationships/profile state WITHOUT disabling constraints or triggers.
DO $$
DECLARE scenario text;
BEGIN
 FOREACH scenario IN ARRAY ARRAY['deleted profile','removed link','duplicate link','other clinic','inactive profile'] LOOP
  BEGIN
   IF scenario='deleted profile' THEN DELETE FROM public.profiles WHERE id='e2000000-0000-0000-0000-000000000005';
   ELSIF scenario='removed link' THEN UPDATE public.patients SET profile_id=NULL WHERE id='e3000000-0000-0000-0000-000000000001';
   ELSIF scenario='duplicate link' THEN
    INSERT INTO public.patients(id,clinic_id,profile_id,full_name)
    VALUES ('e3000000-0000-0000-0000-000000000005','e1000000-0000-0000-0000-000000000001','e2000000-0000-0000-0000-000000000005','Lote B ambiguous link');
   ELSIF scenario='other clinic' THEN UPDATE public.profiles SET clinic_id='e1000000-0000-0000-0000-000000000002' WHERE id='e2000000-0000-0000-0000-000000000005';
   ELSE UPDATE public.profiles SET is_active=false WHERE id='e2000000-0000-0000-0000-000000000005';
   END IF;
   PERFORM pg_temp.run_case('helper '||scenario,'e2000000-0000-0000-0000-000000000005','authenticated','SELECT public.current_patient_id() IS NULL');
   PERFORM pg_temp.run_case('view '||scenario,'e2000000-0000-0000-0000-000000000005','authenticated','SELECT count(*)=0 FROM public.patient_shared_personality');
   PERFORM pg_temp.run_case('library '||scenario,'e2000000-0000-0000-0000-000000000005','authenticated','SELECT public.get_my_library()','Active linked patient required');
   RAISE EXCEPTION USING ERRCODE='ZB002';
  EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
  END;
 END LOOP;
END;
$$;

DO $$
BEGIN
 BEGIN
  -- Existing relations can outlive a profile's clinic reassignment.
  UPDATE public.profiles SET clinic_id='e1000000-0000-0000-0000-000000000002' WHERE id='e2000000-0000-0000-0000-000000000002';
  PERFORM pg_temp.run_case('psych clinic mismatch completion','e2000000-0000-0000-0000-000000000002','authenticated','SELECT count(*)=0 FROM public.get_patients_data_completion()');
  PERFORM pg_temp.run_case('psych clinic mismatch pending','e2000000-0000-0000-0000-000000000002','authenticated','SELECT count(*)=0 FROM public.get_patients_with_pending_results_release()');
  PERFORM pg_temp.run_case('psych clinic mismatch alerts','e2000000-0000-0000-0000-000000000002','authenticated',
   $stmt$SELECT public.get_psychologist_alerts()='{"missing_checkins":[],"expiring_invitations":[],"stale_questionnaires":[],"pending_results_release":[]}'::jsonb$stmt$);
  PERFORM pg_temp.run_case('lifecycle clinic mismatch','e2000000-0000-0000-0000-000000000002','authenticated',
   $stmt$SELECT public.set_patient_active_status('e3000000-0000-0000-0000-000000000001',true)$stmt$,'Clinical lifecycle access denied');
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
 END;
 BEGIN
  UPDATE public.patients SET responsible_psychologist_id=NULL WHERE id='e3000000-0000-0000-0000-000000000001';
  PERFORM pg_temp.run_case('removed owner completion','e2000000-0000-0000-0000-000000000002','authenticated',
   $stmt$SELECT NOT EXISTS(SELECT 1 FROM public.get_patients_data_completion() WHERE patient_id='e3000000-0000-0000-0000-000000000001')$stmt$);
  PERFORM pg_temp.run_case('removed owner pending','e2000000-0000-0000-0000-000000000002','authenticated',
   $stmt$SELECT count(*)=0 FROM public.get_patients_with_pending_results_release()$stmt$);
  PERFORM pg_temp.run_case('removed owner lifecycle','e2000000-0000-0000-0000-000000000002','authenticated',
   $stmt$SELECT public.set_patient_active_status('e3000000-0000-0000-0000-000000000001',true)$stmt$,'Clinical lifecycle access denied');
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
 END;
END;
$$;


-- Distinguish legitimate empty library from unauthorized access; isolate indication clinic.
DO $$
BEGIN
 BEGIN
  DELETE FROM public.library_indications WHERE patient_id='e3000000-0000-0000-0000-000000000001';
  PERFORM pg_temp.run_case('valid patient empty library','e2000000-0000-0000-0000-000000000005','authenticated',
   $stmt$SELECT public.get_my_library()='[]'::jsonb$stmt$);
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
 END;
 BEGIN
  UPDATE public.library_indications SET clinic_id='e1000000-0000-0000-0000-000000000002'
  WHERE patient_id='e3000000-0000-0000-0000-000000000001';
  PERFORM pg_temp.run_case('library rejects inconsistent indication clinic','e2000000-0000-0000-0000-000000000005','authenticated',
   $stmt$SELECT jsonb_array_length(public.get_my_library())=0$stmt$);
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
 END;
 BEGIN
  UPDATE public.library_works SET is_published=false WHERE id='e5000000-0000-0000-0000-000000000001';
  PERFORM pg_temp.run_case('library unpublished work hidden','e2000000-0000-0000-0000-000000000005','authenticated',
   $stmt$SELECT public.get_my_library()='[]'::jsonb$stmt$);
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
 END;
END;
$$;

-- Cross-clinic regression: valid A responses survive a schema-valid transfer to B.
-- Both old (40 days) and newer (8 days) A responses must be ignored; B draft is 12 days old.
DO $$
DECLARE old_days integer;
BEGIN
 FOREACH old_days IN ARRAY ARRAY[40,8] LOOP
  BEGIN
   INSERT INTO public.questionnaire_responses(
    clinic_id,patient_id,questionnaire_id,questionnaire_version_id,status,created_at,completed_at)
   SELECT 'e1000000-0000-0000-0000-000000000001','e3000000-0000-0000-0000-000000000002',questionnaire_id,questionnaire_version_id,status,
    now()-make_interval(days=>old_days),
    CASE WHEN status='completed' THEN now()-make_interval(days=>old_days-1) ELSE NULL END
   FROM public.questionnaire_responses
   WHERE patient_id='e3000000-0000-0000-0000-000000000001';
   PERFORM pg_temp.run_case('cross-clinic A legitimate pending / A age='||old_days,'e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT EXISTS(SELECT 1 FROM public.get_patients_with_pending_results_release() WHERE patient_id='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic A legitimate stale / A age='||old_days,'e2000000-0000-0000-0000-000000000002','authenticated',
    format($stmt$SELECT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'stale_questionnaires') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002' AND (item->>'days_waiting')::integer=%s)$stmt$,old_days));
   PERFORM pg_temp.run_case('cross-clinic A legitimate release age / A age='||old_days,'e2000000-0000-0000-0000-000000000002','authenticated',
    format($stmt$SELECT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'pending_results_release') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002' AND (item->>'days_waiting')::integer=%s)$stmt$,old_days-1));
   -- This patient has no profile_id: transfer preserves all active schema constraints/triggers.
   UPDATE public.patients SET clinic_id='e1000000-0000-0000-0000-000000000002',responsible_psychologist_id='e2000000-0000-0000-0000-000000000008'
   WHERE id='e3000000-0000-0000-0000-000000000002';
   PERFORM pg_temp.run_case('cross-clinic B direct RLS denies A / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT count(*)=0 FROM public.questionnaire_responses WHERE patient_id='e3000000-0000-0000-0000-000000000002'$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B completion ignores A / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT questionarios IS FALSE FROM public.get_patients_data_completion() WHERE patient_id='e3000000-0000-0000-0000-000000000002'$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B pending ignores A / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT NOT EXISTS(SELECT 1 FROM public.get_patients_with_pending_results_release() WHERE patient_id='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B stale ignores A / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'stale_questionnaires') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B release ignores A / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'pending_results_release') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic A former owner completion / A age='||old_days,'e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT NOT EXISTS(SELECT 1 FROM public.get_patients_data_completion() WHERE patient_id='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic A former owner pending / A age='||old_days,'e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT NOT EXISTS(SELECT 1 FROM public.get_patients_with_pending_results_release() WHERE patient_id='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic A former owner stale / A age='||old_days,'e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'stale_questionnaires') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic A former owner release / A age='||old_days,'e2000000-0000-0000-0000-000000000002','authenticated',$stmt$SELECT NOT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'pending_results_release') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002')$stmt$);
   INSERT INTO public.questionnaire_responses(
    clinic_id,patient_id,questionnaire_id,questionnaire_version_id,status,created_at,completed_at)
   SELECT 'e1000000-0000-0000-0000-000000000002','e3000000-0000-0000-0000-000000000002',questionnaire_id,questionnaire_version_id,status,
    now()-interval '12 days',
    CASE WHEN status='completed' THEN now()-interval '9 days' ELSE NULL END
   FROM public.questionnaire_responses
   WHERE patient_id='e3000000-0000-0000-0000-000000000004';
   PERFORM pg_temp.run_case('cross-clinic B direct RLS only B / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT count(*)=2 AND bool_and(clinic_id='e1000000-0000-0000-0000-000000000002') FROM public.questionnaire_responses WHERE patient_id='e3000000-0000-0000-0000-000000000002'$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B completion includes B / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT questionarios IS TRUE FROM public.get_patients_data_completion() WHERE patient_id='e3000000-0000-0000-0000-000000000002'$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B pending includes B / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT EXISTS(SELECT 1 FROM public.get_patients_with_pending_results_release() WHERE patient_id='e3000000-0000-0000-0000-000000000002')$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B stale age only B / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'stale_questionnaires') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002' AND (item->>'days_waiting')::integer=12)$stmt$);
   PERFORM pg_temp.run_case('cross-clinic B release age only B / A age='||old_days,'e2000000-0000-0000-0000-000000000008','authenticated',$stmt$SELECT EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_psychologist_alerts()->'pending_results_release') item WHERE item->>'patient_id'='e3000000-0000-0000-0000-000000000002' AND (item->>'days_waiting')::integer=9)$stmt$);
   RAISE EXCEPTION USING ERRCODE='ZB002';
  EXCEPTION WHEN SQLSTATE 'ZB002' THEN NULL;
  END;
 END LOOP;
END;
$$;

-- Simulate a late error after patient DML, proving atomic rollback of login + audit.
CREATE FUNCTION pg_temp.late_failure() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN RAISE EXCEPTION USING ERRCODE='ZB003',MESSAGE='late audit failure'; END;
$$;
CREATE TRIGGER lote_b_late_failure BEFORE INSERT ON public.audit_events FOR EACH ROW EXECUTE FUNCTION pg_temp.late_failure();
DO $$
DECLARE before_state jsonb;
BEGIN
 before_state:=pg_temp.snapshot();
 BEGIN
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims','{"sub":"e2000000-0000-0000-0000-000000000002","role":"authenticated"}',true);
  SET LOCAL ROLE authenticated;
  PERFORM public.set_patient_active_status('e3000000-0000-0000-0000-000000000002',false);
  RAISE EXCEPTION 'FAIL: late audit failure not reached';
 EXCEPTION WHEN SQLSTATE 'ZB003' THEN NULL;
 END;
 PERFORM pg_temp.check_true(before_state=pg_temp.snapshot(),'late failure rolls back all patient/profile/audit effects');
END;
$$;
ROLLBACK;
