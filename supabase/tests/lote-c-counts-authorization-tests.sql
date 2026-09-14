-- Local only, psql -U supabase_admin -X -v ON_ERROR_STOP=1. All changes roll back.
BEGIN;
SET LOCAL statement_timeout='30s';
CREATE FUNCTION pg_temp.check_true(ok boolean,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END;
$$;

-- Check effective ACLs before the mutation injection and before probe grants.
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_proc p,
 aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
 WHERE p.oid='public.get_patient_counts_by_psychologist()'::regprocedure
 AND a.grantee=0 AND a.privilege_type='EXECUTE'),'PUBLIC has no EXECUTE');
SELECT pg_temp.check_true(NOT has_function_privilege('anon','public.get_patient_counts_by_psychologist()','EXECUTE'),'anon effective denial');
SELECT pg_temp.check_true(has_function_privilege('authenticated','public.get_patient_counts_by_psychologist()','EXECUTE'),'authenticated EXECUTE');
SELECT pg_temp.check_true(has_function_privilege('service_role','public.get_patient_counts_by_psychologist()','EXECUTE'),'service ACL preserved');
SELECT pg_temp.check_true(prosecdef AND provolatile='s' AND proconfig=ARRAY['search_path=pg_catalog']
 AND pg_get_userbyid(proowner)='postgres','owner stable definer and safe path')
 FROM pg_proc WHERE oid='public.get_patient_counts_by_psychologist()'::regprocedure;

INSERT INTO public.clinics(id,name) VALUES
 ('c1000000-0000-0000-0000-000000000001','Lote C A'),('c1000000-0000-0000-0000-000000000002','Lote C B');
INSERT INTO auth.users(id,email) SELECT ('c2000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,
 'lote-c-'||n||'@example.test' FROM generate_series(1,10) n;
-- 1 missing profile; 2 inactive admin; 3 patient; 4 psychologist A; 5 admin A;
-- 6 admin B; 7 legacy admin; 8 psychologist B; 9 inactive psychologist; 10 inactive patient.
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
SELECT id, CASE WHEN right(id::text,2) IN ('06','08') THEN 'c1000000-0000-0000-0000-000000000002'::uuid
 ELSE 'c1000000-0000-0000-0000-000000000001'::uuid END,'Lote C',email,
 CASE right(id::text,2) WHEN '02' THEN 'platform_admin' WHEN '05' THEN 'platform_admin'
 WHEN '06' THEN 'platform_admin' WHEN '07' THEN 'admin' WHEN '04' THEN 'psychologist'
 WHEN '08' THEN 'psychologist' WHEN '09' THEN 'psychologist' ELSE 'patient' END::public.profile_role,
 right(id::text,2) NOT IN ('02','09','10')
FROM auth.users WHERE id::text LIKE 'c2000000-%' AND right(id::text,2)<>'01';
INSERT INTO public.patients(id,clinic_id,responsible_psychologist_id,full_name)
SELECT ('c3000000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,
 CASE WHEN n=4 THEN 'c1000000-0000-0000-0000-000000000002'::uuid ELSE 'c1000000-0000-0000-0000-000000000001'::uuid END,
 CASE WHEN n=4 THEN 'c2000000-0000-0000-0000-000000000008'::uuid ELSE 'c2000000-0000-0000-0000-000000000004'::uuid END,
 'Lote C patient' FROM generate_series(1,4) n;
UPDATE public.patients SET is_active=false,inactivated_at=now(),inactivated_by='c2000000-0000-0000-0000-000000000005'
 WHERE id='c3000000-0000-0000-0000-000000000003';
INSERT INTO public.patient_invitations(clinic_id,invited_by,responsible_psychologist_id,email,token_hash,status,expires_at)
SELECT CASE WHEN n>2 THEN 'c1000000-0000-0000-0000-000000000002'::uuid ELSE 'c1000000-0000-0000-0000-000000000001'::uuid END,
 CASE WHEN n>2 THEN 'c2000000-0000-0000-0000-000000000008'::uuid ELSE 'c2000000-0000-0000-0000-000000000004'::uuid END,
 CASE WHEN n>2 THEN 'c2000000-0000-0000-0000-000000000008'::uuid ELSE 'c2000000-0000-0000-0000-000000000004'::uuid END,
 'lote-c-invite-'||n||'@example.test','lote-c-token-'||n,
 CASE WHEN n=2 THEN 'revoked' ELSE 'pending' END,now()+interval '2 days' FROM generate_series(1,4) n;

CREATE FUNCTION pg_temp.call_counts(label text,actor uuid,dbrole text,allowed boolean DEFAULT false,acl_denial boolean DEFAULT false)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE result jsonb; caught text;
BEGIN
 PERFORM set_config('request.jwt.claim.sub','',true);
 -- Hostile claims cannot replace the DB role or an active profile.
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role','authenticated',
 'app_metadata',jsonb_build_object('role','platform_admin'),
 'user_metadata',jsonb_build_object('role','platform_admin','is_active',true))::text,true);
 EXECUTE format('SET LOCAL ROLE %I',dbrole);
 BEGIN
  SELECT jsonb_agg(to_jsonb(t) ORDER BY psychologist_id) INTO result
  FROM public.get_patient_counts_by_psychologist() t;
 EXCEPTION WHEN SQLSTATE '42501' THEN GET STACKED DIAGNOSTICS caught=MESSAGE_TEXT;
 END;
 RESET ROLE;
 IF allowed THEN
  PERFORM pg_temp.check_true(caught IS NULL AND
   (SELECT jsonb_agg(t ORDER BY t->>'psychologist_id') FROM jsonb_array_elements(result) t
    WHERE t->>'psychologist_id' LIKE 'c2000000-%') =
   '[{"psychologist_id":"c2000000-0000-0000-0000-000000000004","active_count":2,"pending_invites":1},
     {"psychologist_id":"c2000000-0000-0000-0000-000000000008","active_count":1,"pending_invites":2},
     {"psychologist_id":"c2000000-0000-0000-0000-000000000009","active_count":0,"pending_invites":0}]'::jsonb,
   label||' exact global counts including zero-count psychologist');
 ELSE
  PERFORM pg_temp.check_true(caught IS NOT NULL AND result IS NULL AND
   (CASE WHEN acl_denial THEN caught='permission denied for function get_patient_counts_by_psychologist'
    ELSE caught='Administrative counts access denied' END),label||' denied before any metrics');
 END IF;
END;
$$;
SELECT pg_temp.call_counts('anon ACL',NULL,'anon',false,true);
-- Test the body even if a future explicit/inherited grant reopens execution.
GRANT EXECUTE ON FUNCTION public.get_patient_counts_by_psychologist() TO anon;
-- MUTATION_INJECTION_POINT
SELECT pg_temp.call_counts('missing profile','c2000000-0000-0000-0000-000000000001','authenticated');
SELECT pg_temp.call_counts('anon guard',NULL,'anon');
SELECT pg_temp.call_counts('anon forged admin UID','c2000000-0000-0000-0000-000000000005','anon');
SELECT pg_temp.call_counts('missing UID',NULL,'authenticated');
SELECT pg_temp.call_counts('inactive admin','c2000000-0000-0000-0000-000000000002','authenticated');
SELECT pg_temp.call_counts('patient','c2000000-0000-0000-0000-000000000003','authenticated');
SELECT pg_temp.call_counts('psychologist A','c2000000-0000-0000-0000-000000000004','authenticated');
SELECT pg_temp.call_counts('legacy admin','c2000000-0000-0000-0000-000000000007','authenticated');
SELECT pg_temp.call_counts('psychologist B','c2000000-0000-0000-0000-000000000008','authenticated');
SELECT pg_temp.call_counts('inactive psychologist','c2000000-0000-0000-0000-000000000009','authenticated');
SELECT pg_temp.call_counts('inactive patient','c2000000-0000-0000-0000-000000000010','authenticated');
SELECT pg_temp.call_counts('service without UID',NULL,'service_role');
SELECT pg_temp.call_counts('service missing profile','c2000000-0000-0000-0000-000000000001','service_role');
SELECT pg_temp.call_counts('service admin UID','c2000000-0000-0000-0000-000000000005','service_role');
SELECT pg_temp.call_counts('owner context admin UID','c2000000-0000-0000-0000-000000000005','postgres');
SELECT pg_temp.call_counts('admin A','c2000000-0000-0000-0000-000000000005','authenticated',true);
SELECT pg_temp.call_counts('admin B','c2000000-0000-0000-0000-000000000006','authenticated',true);

-- These NULL states are impossible in the real schema. Relax NOT NULL only
-- inside a rolled-back savepoint to prove the guard does not rely on constraints.
SAVEPOINT null_states;
ALTER TABLE public.profiles ALTER COLUMN role DROP NOT NULL;
UPDATE public.profiles SET role=NULL WHERE id='c2000000-0000-0000-0000-000000000005';
SELECT pg_temp.call_counts('NULL role','c2000000-0000-0000-0000-000000000005','authenticated');
UPDATE public.profiles SET role='platform_admin' WHERE id='c2000000-0000-0000-0000-000000000005';
ALTER TABLE public.profiles ALTER COLUMN is_active DROP NOT NULL;
UPDATE public.profiles SET is_active=NULL WHERE id='c2000000-0000-0000-0000-000000000005';
SELECT pg_temp.call_counts('NULL activation','c2000000-0000-0000-0000-000000000005','authenticated');
UPDATE public.profiles SET is_active=true WHERE id='c2000000-0000-0000-0000-000000000005';
ALTER TABLE public.profiles ALTER COLUMN clinic_id DROP NOT NULL;
UPDATE public.profiles SET clinic_id=NULL WHERE id='c2000000-0000-0000-0000-000000000005';
SELECT pg_temp.call_counts('admin without clinic','c2000000-0000-0000-0000-000000000005','authenticated',true);
ROLLBACK TO null_states;
SELECT pg_temp.check_true((SELECT bool_and(attnotnull) FROM pg_attribute
 WHERE attrelid='public.profiles'::regclass AND attname IN ('role','is_active','clinic_id')),'constraints restored');
ROLLBACK;
