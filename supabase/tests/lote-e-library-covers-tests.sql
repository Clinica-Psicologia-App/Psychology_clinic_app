-- Local psql -U supabase_admin -X -v ON_ERROR_STOP=1. Rollback-only metadata.
-- DELETE effects are tested through Storage HTTP; never bypass protect_delete.
BEGIN;
SET LOCAL statement_timeout='30s';
CREATE FUNCTION pg_temp.check_true(ok boolean,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END;
$$;
SELECT pg_temp.check_true(NOT has_function_privilege('anon','public.is_library_cover_admin()','EXECUTE')
 AND NOT EXISTS(SELECT 1 FROM pg_proc p,aclexplode(coalesce(proacl,acldefault('f',proowner))) a
 WHERE p.oid='public.is_library_cover_admin()'::regprocedure AND grantee=0),'PUBLIC and anon ACL');
SELECT pg_temp.check_true(prosecdef AND provolatile='s' AND proconfig=ARRAY['search_path=pg_catalog']
 AND pg_get_userbyid(proowner)='postgres','helper configuration') FROM pg_proc WHERE oid='public.is_library_cover_admin()'::regprocedure;
SELECT pg_temp.check_true(has_function_privilege('authenticated','public.is_library_cover_admin()','EXECUTE')
 AND has_function_privilege('service_role','public.is_library_cover_admin()','EXECUTE'),'trusted ACLs preserved');
SELECT pg_temp.check_true((SELECT public FROM storage.buckets WHERE id='library-covers'),'bucket still public');
SELECT pg_temp.check_true((SELECT count(*)=4 AND bool_and(roles=ARRAY['authenticated']::name[])
 FROM pg_policies WHERE schemaname='storage' AND tablename='objects' AND policyname LIKE 'library_covers_admin_%'),'four authenticated policies');

INSERT INTO public.clinics(id,name) VALUES ('e7100000-0000-0000-0000-000000000001','E A'),('e7100000-0000-0000-0000-000000000002','E B');
INSERT INTO auth.users(id,email) SELECT ('e7200000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,'lote-e-'||n||'@example.test' FROM generate_series(1,7) n;
-- 1 missing; 2 inactive admin; 3 patient; 4 psychologist; 5 admin A; 6 legacy; 7 admin B.
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
SELECT id,CASE WHEN right(id::text,2)='07' THEN 'e7100000-0000-0000-0000-000000000002'::uuid ELSE 'e7100000-0000-0000-0000-000000000001'::uuid END,
 'E fixture',email,CASE right(id::text,2) WHEN '03' THEN 'patient' WHEN '04' THEN 'psychologist' WHEN '06' THEN 'admin' ELSE 'platform_admin' END::public.profile_role,
 right(id::text,2)<>'02' FROM auth.users WHERE id::text LIKE 'e7200000-%' AND right(id::text,2)<>'01';
INSERT INTO storage.objects(bucket_id,name,metadata) VALUES ('library-covers','lote-e-sql/existing.png','{"fixture":"original"}');
INSERT INTO storage.objects(bucket_id,name,metadata) VALUES ('avatars','lote-e-sql/foreign.png','{"fixture":"original"}');

CREATE FUNCTION pg_temp.probe(label text,actor uuid,dbrole text,expected_helper boolean,allowed boolean,claim text DEFAULT 'platform_admin') RETURNS void LANGUAGE plpgsql AS $$
DECLARE caught text; result boolean; n integer;
BEGIN
 PERFORM set_config('request.jwt.claim.sub','',true);
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role','authenticated',
 'app_metadata',jsonb_build_object('role',claim),'user_metadata',jsonb_build_object('role','platform_admin'))::text,true);
 EXECUTE format('SET LOCAL ROLE %I',dbrole);
 BEGIN
  INSERT INTO storage.objects(bucket_id,name) VALUES ('library-covers','lote-e-sql/'||label||'.png');
 EXCEPTION WHEN insufficient_privilege THEN GET STACKED DIAGNOSTICS caught=MESSAGE_TEXT;
 END;
 RESET ROLE;
 -- First assertion deliberately proves an actual historical INSERT bypass.
 PERFORM pg_temp.check_true(CASE WHEN allowed THEN caught IS NULL ELSE caught IS NOT NULL END,label||' INSERT '||CASE WHEN allowed THEN 'allowed' ELSE 'denied' END);
 EXECUTE format('SET LOCAL ROLE %I',dbrole);
 result:=public.is_library_cover_admin();
 SELECT count(*) INTO n FROM storage.objects WHERE bucket_id='library-covers' AND name='lote-e-sql/existing.png';
 RESET ROLE;
 PERFORM pg_temp.check_true(result IS NOT DISTINCT FROM expected_helper,label||' helper');
 PERFORM pg_temp.check_true(n=CASE WHEN allowed THEN 1 ELSE 0 END,label||' SELECT metadata');
 EXECUTE format('SET LOCAL ROLE %I',dbrole);
 UPDATE storage.objects SET metadata='{"fixture":"updated"}' WHERE bucket_id='library-covers' AND name='lote-e-sql/existing.png';
 GET DIAGNOSTICS n=ROW_COUNT;
 RESET ROLE;
 PERFORM pg_temp.check_true(n=CASE WHEN allowed THEN 1 ELSE 0 END,label||' UPDATE effect');
END;
$$;
-- Exercise the body even if EXECUTE is reopened accidentally; rolls back.
GRANT EXECUTE ON FUNCTION public.is_library_cover_admin() TO anon;
-- MUTATION_INJECTION_POINT
SELECT pg_temp.probe('inactive claim','e7200000-0000-0000-0000-000000000002','authenticated',false,false);
SELECT pg_temp.probe('missing claim','e7200000-0000-0000-0000-000000000001','authenticated',false,false);
SELECT pg_temp.probe('missing no claim','e7200000-0000-0000-0000-000000000001','authenticated',false,false,NULL);
SELECT pg_temp.probe('anon',NULL,'anon',false,false);
SELECT pg_temp.probe('anon valid UID','e7200000-0000-0000-0000-000000000005','anon',false,false);
SELECT pg_temp.probe('no UID',NULL,'authenticated',false,false);
SELECT pg_temp.probe('patient claim','e7200000-0000-0000-0000-000000000003','authenticated',false,false);
SELECT pg_temp.probe('psychologist','e7200000-0000-0000-0000-000000000004','authenticated',false,false);
SELECT pg_temp.probe('legacy admin','e7200000-0000-0000-0000-000000000006','authenticated',false,false);
SELECT pg_temp.probe('admin no claim','e7200000-0000-0000-0000-000000000005','authenticated',true,true,NULL);
SELECT pg_temp.probe('admin B','e7200000-0000-0000-0000-000000000007','authenticated',true,true);
SELECT pg_temp.probe('service',NULL,'service_role',false,true);
UPDATE public.profiles SET role='patient' WHERE id='e7200000-0000-0000-0000-000000000005';
SELECT pg_temp.probe('demoted','e7200000-0000-0000-0000-000000000005','authenticated',false,false);
UPDATE public.profiles SET is_active=false WHERE id='e7200000-0000-0000-0000-000000000005';
SELECT pg_temp.probe('demoted inactive','e7200000-0000-0000-0000-000000000005','authenticated',false,false);
DELETE FROM public.profiles WHERE id='e7200000-0000-0000-0000-000000000005';
SELECT pg_temp.probe('removed','e7200000-0000-0000-0000-000000000005','authenticated',false,false);
SAVEPOINT null_role;
ALTER TABLE public.profiles ALTER COLUMN role DROP NOT NULL;
UPDATE public.profiles SET role=NULL WHERE id='e7200000-0000-0000-0000-000000000007';
SELECT pg_temp.probe('NULL role','e7200000-0000-0000-0000-000000000007','authenticated',false,false);
ROLLBACK TO null_role;
-- Another bucket retains its own policy; global cover admin cannot change it.
SELECT set_config('request.jwt.claims','{"sub":"e7200000-0000-0000-0000-000000000007","role":"authenticated"}',true);
SET LOCAL ROLE authenticated;
DO $$ DECLARE n integer; BEGIN
 UPDATE storage.objects SET metadata='{}' WHERE bucket_id='avatars' AND name='lote-e-sql/foreign.png';
 GET DIAGNOSTICS n=ROW_COUNT;
 PERFORM pg_temp.check_true(n=0,'no new UPDATE on foreign avatar');
 BEGIN
  INSERT INTO storage.objects(bucket_id,name) VALUES ('avatars','lote-e-sql/forbidden.png');
  RAISE EXCEPTION 'FAIL: foreign bucket INSERT allowed';
 EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS: no new INSERT on foreign avatar'; END;
 BEGIN
  UPDATE storage.objects SET bucket_id='avatars' WHERE bucket_id='library-covers' AND name='lote-e-sql/existing.png';
  RAISE EXCEPTION 'FAIL: UPDATE escaped bucket WITH CHECK';
 EXCEPTION WHEN insufficient_privilege THEN RAISE NOTICE 'PASS: UPDATE WITH CHECK prevents bucket escape'; END;
END; $$;
RESET ROLE;
ROLLBACK;
