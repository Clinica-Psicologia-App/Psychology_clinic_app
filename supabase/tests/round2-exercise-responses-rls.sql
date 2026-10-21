-- Local only, rollback-only. psql -U postgres -X -v ON_ERROR_STOP=1
BEGIN;
SET LOCAL statement_timeout = '30s';
INSERT INTO public.clinics(id,name) VALUES
 ('a9100000-0000-0000-0000-000000000001','Round2 synthetic A'),
 ('a9100000-0000-0000-0000-000000000002','Round2 synthetic B');
INSERT INTO auth.users(id,email)
 SELECT ('a9200000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,
 'round2-'||n||'@example.test' FROM generate_series(1,6) n;
-- 1 owner A, 2 other psychologist A, 3 psychologist B, 4 patient A,
-- 5 patient B, 6 platform admin A. Profile IDs deliberately differ from patients.id.
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
 SELECT id, CASE WHEN right(id::text,2) IN ('03','05')
 THEN 'a9100000-0000-0000-0000-000000000002'::uuid
 ELSE 'a9100000-0000-0000-0000-000000000001'::uuid END,
 'Round2 synthetic', email,
 CASE WHEN right(id::text,2) IN ('04','05') THEN 'patient'
 WHEN right(id::text,2)='06' THEN 'platform_admin' ELSE 'psychologist' END::public.profile_role,
 true FROM auth.users WHERE id::text LIKE 'a9200000-%';
INSERT INTO public.patients(id,clinic_id,profile_id,responsible_psychologist_id,full_name)
 VALUES
 ('a9300000-0000-0000-0000-000000000001','a9100000-0000-0000-0000-000000000001','a9200000-0000-0000-0000-000000000004','a9200000-0000-0000-0000-000000000001','Round2 patient A'),
 ('a9300000-0000-0000-0000-000000000002','a9100000-0000-0000-0000-000000000002','a9200000-0000-0000-0000-000000000005','a9200000-0000-0000-0000-000000000003','Round2 patient B');
INSERT INTO public.psychoeducation_modules(id,number,stage,title,cards,is_published)
 VALUES ('a9400000-0000-0000-0000-000000000001',99001,'Praticar','Round2 synthetic','[]',true);
INSERT INTO public.psychoeducation_exercise_responses(patient_id,module_id,responses)
 SELECT profile_id,'a9400000-0000-0000-0000-000000000001','{"answer":"synthetic"}'
 FROM public.patients WHERE id::text LIKE 'a9300000-%';

CREATE FUNCTION pg_temp.check_actor(actor integer,expected integer,label text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE actual integer; changed integer;
BEGIN
 PERFORM set_config('request.jwt.claim.sub', '', true);
 PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',
   'a9200000-0000-0000-0000-'||lpad(actor::text,12,'0'),'role','authenticated')::text,true);
 SET LOCAL ROLE authenticated;
 SELECT count(*) INTO actual FROM public.psychoeducation_exercise_responses
 WHERE module_id='a9400000-0000-0000-0000-000000000001';
 IF actor IN (1,2,3,6) THEN
   UPDATE public.psychoeducation_exercise_responses SET responses='{"forged":true}'
   WHERE module_id='a9400000-0000-0000-0000-000000000001';
   GET DIAGNOSTICS changed = ROW_COUNT;
   IF changed <> 0 THEN RAISE EXCEPTION 'FAIL staff write: %',label; END IF;
 END IF;
 RESET ROLE;
 IF actual <> expected THEN RAISE EXCEPTION 'FAIL % expected %, got %',label,expected,actual; END IF;
 RAISE NOTICE 'PASS: % read %, staff writes denied',label,actual;
END;
$$;
SELECT pg_temp.check_actor(1,1,'responsible psychologist A');
SELECT pg_temp.check_actor(2,0,'other psychologist same clinic');
SELECT pg_temp.check_actor(3,1,'psychologist B sees only B');
SELECT pg_temp.check_actor(4,1,'patient A own response only');
SELECT pg_temp.check_actor(5,1,'patient B own response only');
SELECT pg_temp.check_actor(6,0,'platform admin denied');
-- Verify exactly which row is visible, not just the total.
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"a9200000-0000-0000-0000-000000000001","role":"authenticated"}',true);
DO $$ BEGIN
 IF EXISTS (SELECT 1 FROM public.psychoeducation_exercise_responses
 WHERE patient_id='a9200000-0000-0000-0000-000000000005') THEN
 RAISE EXCEPTION 'FAIL cross-clinic response visible'; END IF;
END $$;
RESET ROLE;
ROLLBACK;
