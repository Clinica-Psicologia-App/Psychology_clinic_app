-- Local rollback-only tests. psql -U supabase_admin -X -v ON_ERROR_STOP=1.
BEGIN;
SET LOCAL statement_timeout='30s';
CREATE FUNCTION pg_temp.check_true(ok boolean,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END;
$$;
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_proc p,
 aclexplode(coalesce(proacl,acldefault('f',proowner))) a
 WHERE p.oid='public.get_psychoeducation_journey()'::regprocedure AND grantee=0 AND privilege_type='EXECUTE'),'PUBLIC denied');
SELECT pg_temp.check_true(NOT has_function_privilege('anon','public.get_psychoeducation_journey()','EXECUTE'),'anon denied');
SELECT pg_temp.check_true(NOT has_function_privilege('service_role','public.get_psychoeducation_journey()','EXECUTE'),'service denied');
SELECT pg_temp.check_true(has_function_privilege('authenticated','public.get_psychoeducation_journey()','EXECUTE'),'authenticated allowed');
SELECT pg_temp.check_true(pg_get_userbyid(proowner)='postgres' AND prosecdef AND proconfig=ARRAY['search_path=pg_catalog']
 AND has_function_privilege('postgres',oid,'EXECUTE') AND has_function_privilege('supabase_admin',oid,'EXECUTE'),'owner and safe path')
 FROM pg_proc WHERE oid='public.get_psychoeducation_journey()'::regprocedure;

INSERT INTO public.clinics(id,name) VALUES ('d7100000-0000-0000-0000-000000000001','D A'),('d7100000-0000-0000-0000-000000000002','D B');
INSERT INTO auth.users(id,email) SELECT ('d7200000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,'lote-d-'||n||'@example.test' FROM generate_series(1,7) n;
-- 1 missing; 2 patient A; 3 psychologist B; 4/5 inactive patient/psych; 6 platform; 7 legacy.
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
SELECT id,CASE WHEN right(id::text,2)='03' THEN 'd7100000-0000-0000-0000-000000000002'::uuid ELSE 'd7100000-0000-0000-0000-000000000001'::uuid END,
 'D fixture',email,CASE right(id::text,2) WHEN '03' THEN 'psychologist' WHEN '05' THEN 'psychologist'
 WHEN '06' THEN 'platform_admin' WHEN '07' THEN 'admin' ELSE 'patient' END::public.profile_role,
 right(id::text,2) NOT IN ('04','05') FROM auth.users WHERE id::text LIKE 'd7200000-%' AND right(id::text,2)<>'01';
-- Deliberately insert out of order; preserve module ordering and all legitimate fields.
INSERT INTO public.psychoeducation_modules(id,number,stage,title,presentation,closing,accent_color,cover_url,cards,is_published) VALUES
 ('d7300000-0000-0000-0000-000000000002',98002,'Compreender','Second',NULL,NULL,NULL,NULL,'[]',true),
 ('d7300000-0000-0000-0000-000000000001',98001,'Conhecer','First','Intro','End','#123456','https://example.test/cover',
 '[{"title":"Card","image_url":"https://example.test/card","patient_text":"Public text","reflection":"Reflect","exercise":"Exercise","therapist_text":"PRIVATE_SENTINEL","patient_id":"PRIVATE_SENTINEL","clinic_id":"PRIVATE_SENTINEL","progress":"PRIVATE_SENTINEL","private_note":"PRIVATE_SENTINEL","arbitrary_extra":"PRIVATE_SENTINEL"}]',true),
 ('d7300000-0000-0000-0000-000000000003',98003,'Transformar','PRIVATE_UNPUBLISHED',NULL,NULL,NULL,NULL,'[]',false);

CREATE FUNCTION pg_temp.call_journey(label text,actor uuid,dbrole text,allowed boolean DEFAULT false,claimrole text DEFAULT 'patient',acl boolean DEFAULT false)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE result jsonb; caught text; projected jsonb;
BEGIN
 PERFORM set_config('request.jwt.claim.sub','',true);
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role','authenticated',
 'app_metadata',jsonb_build_object('role',claimrole),'user_metadata',jsonb_build_object('role',claimrole,'is_active',true))::text,true);
 EXECUTE format('SET LOCAL ROLE %I',dbrole);
 BEGIN
  result:=public.get_psychoeducation_journey();
 EXCEPTION WHEN SQLSTATE '42501' THEN GET STACKED DIAGNOSTICS caught=MESSAGE_TEXT;
 END;
 RESET ROLE;
 IF NOT allowed THEN
  PERFORM pg_temp.check_true(result IS NULL AND caught IS NOT NULL AND
   caught=CASE WHEN acl THEN 'permission denied for function get_psychoeducation_journey' ELSE 'Psychoeducation access denied' END,
   label||' denied before content');
 ELSE
  SELECT jsonb_agg(m ORDER BY ord) INTO projected FROM jsonb_array_elements(result) WITH ORDINALITY a(m,ord)
  WHERE m->>'id' LIKE 'd7300000-%';
  PERFORM pg_temp.check_true(caught IS NULL AND projected=
  '[{"id":"d7300000-0000-0000-0000-000000000001","number":98001,"stage":"Conhecer","title":"First","presentation":"Intro","closing":"End","accent_color":"#123456","cover_url":"https://example.test/cover","cards":[{"title":"Card","image_url":"https://example.test/card","patient_text":"Public text","reflection":"Reflect","exercise":"Exercise"}]},
    {"id":"d7300000-0000-0000-0000-000000000002","number":98002,"stage":"Compreender","title":"Second","presentation":null,"closing":null,"accent_color":null,"cover_url":null,"cards":[]}]'::jsonb,
    label||' exact published projection and ordering');
  PERFORM pg_temp.check_true(result::text NOT LIKE '%PRIVATE_%',label||' no unpublished or private sentinels');
  IF current_setting('lote_d.baseline',true) IS NULL OR current_setting('lote_d.baseline',true)='' THEN
   PERFORM set_config('lote_d.baseline',result::text,true);
  ELSE
   PERFORM pg_temp.check_true(result=current_setting('lote_d.baseline')::jsonb,label||' same global catalogue');
  END IF;
 END IF;
END;
$$;
-- Real ACL checks precede mutation; the first body check detects historic anon content.
SELECT pg_temp.call_journey('anon ACL',NULL,'anon',false,'patient',true);
SELECT pg_temp.call_journey('service ACL',NULL,'service_role',false,'patient',true);
GRANT EXECUTE ON FUNCTION public.get_psychoeducation_journey() TO anon,service_role;
-- MUTATION_INJECTION_POINT
SELECT pg_temp.call_journey('anon historical bypass',NULL,'anon');
SELECT pg_temp.call_journey('anon valid patient UID','d7200000-0000-0000-0000-000000000002','anon');
SELECT pg_temp.call_journey('missing UID',NULL,'authenticated');
SELECT pg_temp.call_journey('missing profile forged patient','d7200000-0000-0000-0000-000000000001','authenticated');
SELECT pg_temp.call_journey('missing profile forged psychologist','d7200000-0000-0000-0000-000000000001','authenticated',false,'psychologist');
SELECT pg_temp.call_journey('unknown UID','d7299999-0000-0000-0000-000000000099','authenticated');
SELECT pg_temp.call_journey('inactive patient','d7200000-0000-0000-0000-000000000004','authenticated');
SELECT pg_temp.call_journey('inactive psychologist','d7200000-0000-0000-0000-000000000005','authenticated');
SELECT pg_temp.call_journey('platform admin','d7200000-0000-0000-0000-000000000006','authenticated');
SELECT pg_temp.call_journey('legacy admin','d7200000-0000-0000-0000-000000000007','authenticated');
SELECT pg_temp.call_journey('service guard',NULL,'service_role');
SELECT pg_temp.call_journey('service patient UID','d7200000-0000-0000-0000-000000000002','service_role');
SELECT pg_temp.call_journey('owner patient UID','d7200000-0000-0000-0000-000000000002','postgres');
SELECT pg_temp.call_journey('patient A','d7200000-0000-0000-0000-000000000002','authenticated',true);
SELECT pg_temp.call_journey('psychologist B','d7200000-0000-0000-0000-000000000003','authenticated',true);
SAVEPOINT changed_profile;
DELETE FROM public.profiles WHERE id='d7200000-0000-0000-0000-000000000002';
SELECT pg_temp.call_journey('removed profile','d7200000-0000-0000-0000-000000000002','authenticated');
ROLLBACK TO changed_profile;
-- Impossible production NULL states: relax only inside this reverted savepoint.
SAVEPOINT null_states;
ALTER TABLE public.profiles ALTER COLUMN role DROP NOT NULL;
UPDATE public.profiles SET role=NULL WHERE id='d7200000-0000-0000-0000-000000000002';
SELECT pg_temp.call_journey('NULL role','d7200000-0000-0000-0000-000000000002','authenticated');
UPDATE public.profiles SET role='patient' WHERE id='d7200000-0000-0000-0000-000000000002';
ALTER TABLE public.profiles ALTER COLUMN clinic_id DROP NOT NULL;
UPDATE public.profiles SET clinic_id=NULL WHERE id='d7200000-0000-0000-0000-000000000002';
SELECT pg_temp.call_journey('patient NULL clinic','d7200000-0000-0000-0000-000000000002','authenticated',true);
ROLLBACK TO null_states;
-- Malformed content ensures unauthorized calls stop BEFORE the JSON query.
SAVEPOINT broken_content;
UPDATE public.psychoeducation_modules SET cards='{}' WHERE id='d7300000-0000-0000-0000-000000000001';
SELECT pg_temp.call_journey('guard before malformed content','d7200000-0000-0000-0000-000000000001','authenticated');
ROLLBACK TO broken_content;
ROLLBACK;
