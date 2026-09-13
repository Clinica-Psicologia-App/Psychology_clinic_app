-- Local psql as supabase_admin (needed to simulate the GoTrue connection).
-- No seed dependency. Every fixture/temporary trigger rolls back.
BEGIN;

INSERT INTO public.clinics (id, name) VALUES
  ('b1000000-0000-0000-0000-000000000001', 'F03 target clinic');

CREATE FUNCTION pg_temp.assert_true(p_ok boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %', p_label; END IF;
  RAISE NOTICE 'PASS: %', p_label;
END;
$$;

CREATE TEMP TABLE f03_cases (n integer, label text, metadata jsonb);
INSERT INTO f03_cases VALUES
  (1, 'platform_admin', '{"role":"platform_admin","clinic_id":"b1000000-0000-0000-0000-000000000001"}'),
  (2, 'psychologist', '{"role":"psychologist","clinic_id":"b1000000-0000-0000-0000-000000000001"}'),
  (3, 'arbitrary clinic', '{"role":"patient","clinic_id":"b1000000-0000-0000-0000-000000000001"}'),
  (4, 'explicit activation', '{"role":"patient","clinic_id":"b1000000-0000-0000-0000-000000000001","is_active":true}'),
  (5, 'combined privileges and extras', '{"role":"platform_admin","clinic_id":"b1000000-0000-0000-0000-000000000001","is_active":true,"can_receive_patients":true,"patient_assignment_limit":999999,"billing_admin":true,"owner_id":"forged","app_metadata":{"role":"platform_admin"}}'),
  (6, 'no privileged metadata', '{"full_name":"Public user","phone":"123"}'),
  (7, 'empty object', '{}'),
  (8, 'SQL NULL', NULL),
  (9, 'malformed field types', '{"role":["platform_admin"],"clinic_id":{},"is_active":"not-a-boolean"}'),
  (10, 'JSON array', '["platform_admin"]'),
  (11, 'JSON scalar', 'true'),
  (12, 'JSON null', 'null'),
  (13, 'missing clinic', '{"role":"platform_admin","is_active":true}'),
  (14, 'missing role', '{"clinic_id":"b1000000-0000-0000-0000-000000000001","is_active":true}'),
  (15, 'invalid UUID', '{"role":"platform_admin","clinic_id":"not-a-uuid"}'),
  (16, 'legacy admin', '{"role":"admin","clinic_id":"b1000000-0000-0000-0000-000000000001"}'),
  (17, 'nonexistent clinic', '{"role":"patient","clinic_id":"b1000000-0000-0000-0000-000000000099"}');
GRANT SELECT ON f03_cases TO supabase_auth_admin;

-- Simulate exactly the role used to INSERT by GoTrue, not service_role.
-- Check the valid hostile payload first, so restoring the historical trigger
-- fails on unauthorized provisioning, not on a later malformed-data fixture.
SET LOCAL SESSION AUTHORIZATION supabase_auth_admin;
INSERT INTO auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
SELECT ('b2000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  'f03-' || n || '@example.test', metadata,
  '{"role":"platform_admin","clinic_id":"b1000000-0000-0000-0000-000000000001","is_active":true}'::jsonb
FROM pg_temp.f03_cases WHERE n = 1;
RESET SESSION AUTHORIZATION;
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM public.profiles
  WHERE id = 'b2000000-0000-0000-0000-000000000001'), 'signup cannot provision platform_admin');

SET LOCAL SESSION AUTHORIZATION supabase_auth_admin;
INSERT INTO auth.users (id, email, raw_user_meta_data, raw_app_meta_data)
SELECT ('b2000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  'f03-' || n || '@example.test', metadata,
  '{"role":"platform_admin","clinic_id":"b1000000-0000-0000-0000-000000000001","is_active":true}'::jsonb
FROM pg_temp.f03_cases WHERE n > 1 ORDER BY n;
RESET SESSION AUTHORIZATION;

DO $$
DECLARE c record; uid uuid;
BEGIN
  FOR c IN SELECT * FROM pg_temp.f03_cases ORDER BY n LOOP
    uid := ('b2000000-0000-0000-0000-' || lpad(c.n::text, 12, '0'))::uuid;
    PERFORM pg_temp.assert_true(EXISTS (SELECT 1 FROM auth.users WHERE id = uid),
      'Auth account created: ' || c.label);
    PERFORM pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = uid),
      'no profile/tenant/privileges: ' || c.label);
  END LOOP;
END;
$$;

-- A valid authenticated account cannot fill the provisioning gap itself.
SELECT set_config('request.jwt.claims', '{"sub":"b2000000-0000-0000-0000-000000000001","role":"authenticated","user_metadata":{"role":"platform_admin"}}', true);
SET LOCAL ROLE authenticated;
DO $$
BEGIN
  IF public.current_role() IS NOT NULL OR public.current_clinic_id() IS NOT NULL THEN
    RAISE EXCEPTION 'FAIL: claims granted a role or clinic without a profile';
  END IF;
  BEGIN
    INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
    VALUES ('b2000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001',
      'Forged', 'f03-1@example.test', 'platform_admin', true);
    RAISE EXCEPTION 'FAIL: account self-provisioned';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'PASS: authenticated account cannot self-provision';
  END;
END;
$$;
RESET ROLE;

-- Trusted provisioning uses explicit database values, never the stored metadata.
SET LOCAL ROLE service_role;
INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
VALUES
  ('b2000000-0000-0000-0000-000000000001', 'b1000000-0000-0000-0000-000000000001', 'Patient', 'f03-1@example.test', 'patient', true),
  ('b2000000-0000-0000-0000-000000000002', 'b1000000-0000-0000-0000-000000000001', 'Staff', 'f03-2@example.test', 'psychologist', true),
  ('b2000000-0000-0000-0000-000000000003', 'b1000000-0000-0000-0000-000000000001', 'Admin', 'f03-3@example.test', 'platform_admin', true);
RESET ROLE;
SELECT pg_temp.assert_true((SELECT role::text = 'patient' AND is_active FROM public.profiles
  WHERE id = 'b2000000-0000-0000-0000-000000000001'), 'trusted patient overrides hostile metadata');
SELECT pg_temp.assert_true((SELECT role::text = 'psychologist' AND is_active FROM public.profiles
  WHERE id = 'b2000000-0000-0000-0000-000000000002'), 'trusted staff provisioning');
SELECT pg_temp.assert_true((SELECT role::text = 'platform_admin' AND is_active FROM public.profiles
  WHERE id = 'b2000000-0000-0000-0000-000000000003'), 'trusted administrator provisioning');

-- Existing profiles and updates of Auth metadata must not be overwritten.
CREATE TEMP TABLE f03_before AS SELECT id, to_jsonb(p) AS snapshot FROM public.profiles p
  WHERE id::text LIKE 'b2000000-%';
SET LOCAL SESSION AUTHORIZATION supabase_auth_admin;
UPDATE auth.users SET raw_user_meta_data = '{"role":"platform_admin","clinic_id":"b1000000-0000-0000-0000-000000000099","is_active":false,"patient_assignment_limit":999999}'
  WHERE id::text LIKE 'b2000000-%';
RESET SESSION AUTHORIZATION;
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM f03_before b
  JOIN public.profiles p USING (id) WHERE b.snapshot IS DISTINCT FROM to_jsonb(p)),
  'existing profiles unchanged by metadata update');
SELECT pg_temp.assert_true((SELECT count(*) = 3 FROM public.profiles WHERE id::text LIKE 'b2000000-%'),
  'metadata update does not provision missing profiles');

-- Deliberately attach the same trigger function to UPDATE in this rollback-only
-- test: even an accidental reattachment cannot overwrite a provisioned profile.
CREATE TRIGGER f03_test_reentry AFTER UPDATE OF raw_user_meta_data ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
SET LOCAL SESSION AUTHORIZATION supabase_auth_admin;
UPDATE auth.users SET raw_user_meta_data = '{"role":"psychologist","clinic_id":"b1000000-0000-0000-0000-000000000001","is_active":true}'
  WHERE id = 'b2000000-0000-0000-0000-000000000001';
RESET SESSION AUTHORIZATION;
SELECT pg_temp.assert_true((SELECT b.snapshot = to_jsonb(p) FROM f03_before b
  JOIN public.profiles p USING (id) WHERE p.id = 'b2000000-0000-0000-0000-000000000001'),
  'trigger reentry cannot overwrite an existing profile');
DROP TRIGGER f03_test_reentry ON auth.users;

-- Existing email synchronization must still work after trusted provisioning.
SET LOCAL SESSION AUTHORIZATION supabase_auth_admin;
UPDATE auth.users SET email = 'f03-updated@example.test'
  WHERE id = 'b2000000-0000-0000-0000-000000000001';
RESET SESSION AUTHORIZATION;
SELECT pg_temp.assert_true((SELECT email = 'f03-updated@example.test' AND role::text = 'patient'
  FROM public.profiles WHERE id = 'b2000000-0000-0000-0000-000000000001'), 'Auth email sync preserves authorization');

-- Duplicate identity cannot be used to replace an existing profile.
DO $$
BEGIN
  BEGIN
    INSERT INTO auth.users (id, email, raw_user_meta_data)
    VALUES ('b2000000-0000-0000-0000-000000000001', 'f03-duplicate@example.test',
      '{"role":"platform_admin","clinic_id":"b1000000-0000-0000-0000-000000000001"}');
    RAISE EXCEPTION 'FAIL: duplicate identity accepted';
  EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'PASS: duplicate Auth identity rejected';
  END;
END;
$$;

SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM pg_proc WHERE oid = 'public.handle_new_user()'::regprocedure
  AND prosecdef), 'signup trigger does not execute as owner');
SELECT pg_temp.assert_true(NOT has_function_privilege('anon', 'public.handle_new_user()', 'EXECUTE')
  AND NOT has_function_privilege('authenticated', 'public.handle_new_user()', 'EXECUTE'),
  'no public provisioning RPC');
ROLLBACK;
