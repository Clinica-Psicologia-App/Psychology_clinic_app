-- Run with psql -X -v ON_ERROR_STOP=1 as local supabase_admin (superuser).
-- SET SESSION AUTHORIZATION tests the real Auth login; all fixtures roll back.
-- Independent of seed users. SET ROLE simulates the PostgREST database role;
-- request.jwt.claims simulates verified claims, not client-editable metadata.
BEGIN;

INSERT INTO public.clinics (id, name) VALUES
  ('a1000000-0000-0000-0000-000000000001', 'F01/F02 clinic A'),
  ('a1000000-0000-0000-0000-000000000002', 'F01/F02 clinic B');

INSERT INTO auth.users (id, email, raw_user_meta_data)
SELECT ('a2000000-0000-0000-0000-' || lpad(n::text, 12, '0'))::uuid,
  'f01-f02-' || n || '@example.test', '{}'::jsonb
FROM generate_series(1, 8) AS n;

-- 1 patient; 2 psychologist; 3 global admin; 4 inactive patient;
-- 5 inactive admin; 6 has no profile; 7 used for NULL-role regression;
-- 8 psychologist in the other clinic.
INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
SELECT id,
  CASE WHEN id = 'a2000000-0000-0000-0000-000000000008' THEN
    'a1000000-0000-0000-0000-000000000002'::uuid ELSE
    'a1000000-0000-0000-0000-000000000001'::uuid END,
  'F01/F02 fixture', email,
  CASE right(id::text, 1) WHEN '2' THEN 'psychologist' WHEN '8' THEN 'psychologist'
    WHEN '3' THEN 'platform_admin' WHEN '5' THEN 'platform_admin'
    ELSE 'patient' END::public.profile_role,
  right(id::text, 1) NOT IN ('4', '5')
FROM auth.users WHERE id::text LIKE 'a2000000-%' AND right(id::text, 1) <> '6';

INSERT INTO public.patients (id, clinic_id, profile_id, responsible_psychologist_id, full_name)
VALUES
  ('a3000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001',
   'a2000000-0000-0000-0000-000000000001', 'a2000000-0000-0000-0000-000000000002', 'F01/F02 patient A'),
  ('a3000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000002',
   NULL, 'a2000000-0000-0000-0000-000000000008', 'F01/F02 patient B');

INSERT INTO public.daily_monitors (id, clinic_id, patient_id, mood_notes) VALUES (
  'a4000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001',
  'a3000000-0000-0000-0000-000000000001', 'F02 cascade fixture');

CREATE FUNCTION pg_temp.assert_true(p_ok boolean, p_label text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  IF p_ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %', p_label; END IF;
  RAISE NOTICE 'PASS: %', p_label;
END;
$$;

CREATE FUNCTION pg_temp.run_as(p_actor integer, p_sql text, p_state text DEFAULT NULL,
  p_role text DEFAULT 'authenticated') RETURNS void
LANGUAGE plpgsql AS $$
DECLARE v_state text; v_message text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claim.role', '', true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object(
    'sub', CASE WHEN p_actor IS NULL THEN NULL ELSE
      'a2000000-0000-0000-0000-' || lpad(p_actor::text, 12, '0') END,
    'role', p_role, 'user_metadata', jsonb_build_object('role', 'platform_admin')
  )::text, true);
  EXECUTE format('SET LOCAL ROLE %I', p_role);
  BEGIN
    EXECUTE p_sql;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_state = RETURNED_SQLSTATE, v_message = MESSAGE_TEXT;
  END;
  RESET ROLE;
  IF v_state IS DISTINCT FROM p_state THEN
    RAISE EXCEPTION 'FAIL actor %, expected SQLSTATE %, got % (%): %',
      p_actor, p_state, v_state, v_message, p_sql;
  END IF;
  RAISE NOTICE 'PASS actor %, SQLSTATE %: %', p_actor, coalesce(v_state, 'success'), p_sql;
END;
$$;

-- Test-only privileged trampoline to prove the trigger still checks the real
-- caller even when a SECURITY DEFINER operation bypasses table RLS.
CREATE FUNCTION pg_temp.definer_update(p_id uuid, p_patch jsonb) RETURNS void
LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $$
DECLARE v_profile public.profiles;
BEGIN
  SELECT (jsonb_populate_record(p, p_patch)).* INTO v_profile
  FROM public.profiles p WHERE id = p_id;
  UPDATE public.profiles SET role = v_profile.role, clinic_id = v_profile.clinic_id,
    is_active = v_profile.is_active, patient_assignment_limit = v_profile.patient_assignment_limit,
    can_receive_patients = v_profile.can_receive_patients, full_name = v_profile.full_name
  WHERE id = p_id;
END;
$$;

-- F01: every protected field, both common roles, direct table access.
DO $$
DECLARE a integer; assignment text;
BEGIN
  FOREACH a IN ARRAY ARRAY[1, 2] LOOP
    FOREACH assignment IN ARRAY ARRAY[
      'role = ''platform_admin''',
      'clinic_id = ''a1000000-0000-0000-0000-000000000002''',
      'is_active = false', 'patient_assignment_limit = 1000000',
      'can_receive_patients = false', 'email = ''forged@example.test''',
      'crp = ''forged''', 'created_at = ''2000-01-01''',
      'id = ''a2000000-0000-0000-0000-000000000006'''
    ] LOOP
      PERFORM pg_temp.run_as(a, format(
        'UPDATE public.profiles SET %s WHERE id = %L', assignment,
        'a2000000-0000-0000-0000-' || lpad(a::text, 12, '0')), '42501');
    END LOOP;
  END LOOP;
END;
$$;

-- Own personal fields and every existing avatar field remain writable.
SELECT pg_temp.run_as(1, $q$UPDATE public.profiles SET full_name = 'Allowed name',
  phone = '123', avatar_type = 'custom', avatar_config = '{"version":1}',
  avatar_path = NULL, avatar_url = NULL, avatar_updated_at = now()
  WHERE id = 'a2000000-0000-0000-0000-000000000001'$q$);
SELECT pg_temp.assert_true((SELECT full_name = 'Allowed name' AND phone = '123'
  FROM public.profiles WHERE id = 'a2000000-0000-0000-0000-000000000001'), 'self-service persists');

-- RLS filters another profile; check that no write silently succeeded.
SELECT pg_temp.run_as(1, $q$UPDATE public.profiles SET role = 'platform_admin'
  WHERE id = 'a2000000-0000-0000-0000-000000000002'$q$);
SELECT pg_temp.assert_true((SELECT role::text = 'psychologist' FROM public.profiles
  WHERE id = 'a2000000-0000-0000-0000-000000000002'), 'another profile unchanged by direct UPDATE');

DO $$
DECLARE a integer;
BEGIN
  -- Even an upstream definer cannot turn its owner into an authorized caller.
  FOREACH a IN ARRAY ARRAY[1, 2, 4, 5, 6, 8] LOOP
    PERFORM pg_temp.run_as(a, $q$SELECT pg_temp.definer_update(
      'a2000000-0000-0000-0000-000000000001', '{"role":"platform_admin"}')$q$, '42501');
  END LOOP;
END;
$$;
SELECT pg_temp.run_as(4, $q$UPDATE public.profiles SET is_active = true
  WHERE id = 'a2000000-0000-0000-0000-000000000004'$q$, '42501');
SELECT pg_temp.run_as(4, $q$UPDATE public.profiles SET full_name = 'Inactive change'
  WHERE id = 'a2000000-0000-0000-0000-000000000004'$q$, '42501');
SELECT pg_temp.run_as(NULL, $q$SELECT pg_temp.definer_update(
  'a2000000-0000-0000-0000-000000000001', '{"role":"platform_admin"}')$q$, '42501');

-- Valid admin and real service_role preserve access/quota management.
SELECT pg_temp.run_as(3, $q$UPDATE public.profiles SET patient_assignment_limit = 20,
  can_receive_patients = false WHERE id = 'a2000000-0000-0000-0000-000000000002'$q$);
SELECT pg_temp.assert_true((SELECT patient_assignment_limit = 20 AND NOT can_receive_patients
  FROM public.profiles WHERE id = 'a2000000-0000-0000-0000-000000000002'), 'admin quota update persists');
SELECT pg_temp.run_as(NULL, $q$UPDATE public.profiles SET patient_assignment_limit = 30,
  can_receive_patients = true WHERE id = 'a2000000-0000-0000-0000-000000000002'$q$, NULL, 'service_role');
SELECT pg_temp.assert_true((SELECT patient_assignment_limit = 30 AND can_receive_patients
  FROM public.profiles WHERE id = 'a2000000-0000-0000-0000-000000000002'), 'service quota update persists');

-- Real Auth database connection identity, not a spoofed claim or definer owner.
SET LOCAL SESSION AUTHORIZATION supabase_auth_admin;
UPDATE auth.users SET email = 'f01-f02-confirmed@example.test'
  WHERE id = 'a2000000-0000-0000-0000-000000000001';
RESET SESSION AUTHORIZATION;
SELECT pg_temp.assert_true((SELECT email = 'f01-f02-confirmed@example.test'
  FROM public.profiles WHERE id = 'a2000000-0000-0000-0000-000000000001'), 'Auth email synchronization preserved');

-- Forging only a JWT role cannot grant the database service role.
SELECT pg_temp.run_as(1, $q$DO $body$ BEGIN
  PERFORM set_config('request.jwt.claim.role', 'service_role', true);
  UPDATE public.profiles SET role = 'platform_admin'
    WHERE id = 'a2000000-0000-0000-0000-000000000001';
END $body$$q$, '42501');

-- Legitimate lifecycle and rollback of an unauthorized nested write.
SELECT pg_temp.run_as(2, $q$SELECT public.set_patient_active_status(
  'a3000000-0000-0000-0000-000000000001', false)$q$);
SELECT pg_temp.assert_true((SELECT NOT is_active FROM public.profiles
  WHERE id = 'a2000000-0000-0000-0000-000000000001'), 'owned patient login inactivated');
SELECT pg_temp.run_as(1, $q$SELECT public.set_patient_active_status(
  'a3000000-0000-0000-0000-000000000001', true)$q$, '42501');
SELECT pg_temp.assert_true((SELECT NOT is_active FROM public.patients
  WHERE id = 'a3000000-0000-0000-0000-000000000001'), 'unauthorized lifecycle rolls back patient update');
SELECT pg_temp.run_as(8, $q$SELECT pg_temp.definer_update(
  'a2000000-0000-0000-0000-000000000001', '{"is_active":true}')$q$, '42501');
SELECT pg_temp.run_as(2, $q$SELECT public.set_patient_active_status(
  'a3000000-0000-0000-0000-000000000001', true)$q$);
SELECT pg_temp.assert_true((SELECT is_active FROM public.profiles
  WHERE id = 'a2000000-0000-0000-0000-000000000001'), 'owned patient login reactivated');

-- F02: ACL contract, including grants inherited from PUBLIC.
SELECT pg_temp.assert_true(NOT has_function_privilege('anon',
  'public.delete_patient_as_admin(uuid)', 'EXECUTE'), 'anon has no effective EXECUTE');
SELECT pg_temp.assert_true(NOT has_function_privilege('service_role',
  'public.delete_patient_as_admin(uuid)', 'EXECUTE'), 'service_role has no RPC EXECUTE');
SELECT pg_temp.assert_true(has_function_privilege('authenticated',
  'public.delete_patient_as_admin(uuid)', 'EXECUTE'), 'authenticated can reach authorization guard');
SELECT pg_temp.assert_true(NOT EXISTS (
  SELECT 1 FROM pg_proc p, LATERAL aclexplode(p.proacl) acl
  WHERE p.oid = 'public.delete_patient_as_admin(uuid)'::regprocedure AND acl.grantee = 0
), 'no PUBLIC grant');
SELECT pg_temp.run_as(NULL, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000001')$q$, '42501', 'anon');

DO $$
DECLARE a integer; target text;
BEGIN
  FOREACH a IN ARRAY ARRAY[1, 2, 4, 5, 6, 8] LOOP
    FOREACH target IN ARRAY ARRAY[
      'a3000000-0000-0000-0000-000000000001', -- own clinic
      'a3000000-0000-0000-0000-000000000002', -- other clinic
      'a3000000-0000-0000-0000-000000000099'  -- no existence disclosure
    ] LOOP
      PERFORM pg_temp.run_as(a, format('SELECT public.delete_patient_as_admin(%L)', target), '42501');
    END LOOP;
  END LOOP;
END;
$$;
SELECT pg_temp.run_as(NULL, 'SELECT public.delete_patient_as_admin(NULL)', '42501');

-- Deliberately grant anon in this rollback-only test to reach the body guard.
GRANT EXECUTE ON FUNCTION public.delete_patient_as_admin(uuid) TO anon;
SELECT pg_temp.run_as(3, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000001')$q$, '42501', 'anon');
REVOKE EXECUTE ON FUNCTION public.delete_patient_as_admin(uuid) FROM anon;

-- The versioned schema rejects NULL roles. Also exercise the function guards
-- against that invalid state by relaxing only this fixture, inside ROLLBACK.
SELECT pg_temp.run_as(3, $q$UPDATE public.profiles SET role = NULL
  WHERE id = 'a2000000-0000-0000-0000-000000000007'$q$, '23502');
ALTER TABLE public.profiles ALTER COLUMN role DROP NOT NULL;
UPDATE public.profiles SET role = NULL WHERE id = 'a2000000-0000-0000-0000-000000000007';
SELECT pg_temp.run_as(7, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000001')$q$, '42501');
SELECT pg_temp.run_as(7, $q$UPDATE public.profiles SET role = 'platform_admin'
  WHERE id = 'a2000000-0000-0000-0000-000000000007'$q$, '42501');
UPDATE public.profiles SET role = 'patient' WHERE id = 'a2000000-0000-0000-0000-000000000007';
ALTER TABLE public.profiles ALTER COLUMN role SET NOT NULL;

-- Temporary objects/search_path cannot shadow fully qualified authorization.
CREATE TEMP TABLE profiles (id uuid, role text, is_active boolean);
INSERT INTO profiles VALUES ('a2000000-0000-0000-0000-000000000006', 'platform_admin', true);
SET LOCAL search_path = pg_temp, public, pg_catalog;
SELECT pg_temp.run_as(6, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000001')$q$, '42501');
SET LOCAL search_path = public, extensions;

SELECT pg_temp.assert_true((SELECT count(*) = 2 FROM public.patients
  WHERE id::text LIKE 'a3000000-%'), 'negative deletes preserved both patients');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM public.audit_events
  WHERE entity_id::text LIKE 'a3000000-%' AND action = 'patient_deleted_permanently'),
  'negative deletes did not produce success audits');
SELECT pg_temp.run_as(3, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000099')$q$, 'P0002');
SELECT pg_temp.run_as(3, 'SELECT public.delete_patient_as_admin(NULL)', 'P0002');

-- A failed success-audit must roll back deletion and its cascades atomically.
ALTER TABLE public.audit_events ADD CONSTRAINT f02_test_reject_success_audit
  CHECK (action <> 'patient_deleted_permanently') NOT VALID;
SELECT pg_temp.run_as(3, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000001')$q$, '23514');
SELECT pg_temp.assert_true(EXISTS (SELECT 1 FROM public.patients
  WHERE id = 'a3000000-0000-0000-0000-000000000001') AND EXISTS (
  SELECT 1 FROM public.daily_monitors WHERE id = 'a4000000-0000-0000-0000-000000000001'),
  'audit failure rolls back deletion and cascade');
ALTER TABLE public.audit_events DROP CONSTRAINT f02_test_reject_success_audit;

SELECT pg_temp.run_as(3, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000001')$q$);
-- Platform administrator remains global: cross-clinic deletion is legitimate.
SELECT pg_temp.run_as(3, $q$SELECT public.delete_patient_as_admin(
  'a3000000-0000-0000-0000-000000000002')$q$);
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM public.patients
  WHERE id::text LIKE 'a3000000-%'), 'admin deleted both targets');
SELECT pg_temp.assert_true(NOT EXISTS (SELECT 1 FROM public.daily_monitors
  WHERE id = 'a4000000-0000-0000-0000-000000000001'), 'dependent record deleted by cascade');
SELECT pg_temp.assert_true((SELECT count(*) = 2 FROM public.audit_events
  WHERE entity_id::text LIKE 'a3000000-%' AND action = 'patient_deleted_permanently'
    AND actor_profile_id = 'a2000000-0000-0000-0000-000000000003'), 'admin deletes audited');

ROLLBACK;
