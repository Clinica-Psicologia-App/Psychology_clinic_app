-- =============================================================================
-- RLS smoke tests — Plataforma Terapia do Esquema
-- Executar após: supabase db reset
--
-- Local:
--   supabase db query --local -f supabase/tests/rls-smoke-tests.sql
--
-- Não altera migrations nem policies. Usa BEGIN…ROLLBACK.
-- =============================================================================

-- IDs da seed (docs/rls-test-plan.md)
-- Admin:     11111111-1111-1111-1111-111111111102
-- Psicólogo: 11111111-1111-1111-1111-111111111103
-- Paciente:  11111111-1111-1111-1111-111111111104
-- Clínica:   11111111-1111-1111-1111-111111111101
-- Patient:   11111111-1111-1111-1111-111111111201
-- Response:  11111111-1111-1111-1111-111111111701
-- Category:  11111111-1111-1111-1111-111111111401
-- Question:  11111111-1111-1111-1111-111111111501

BEGIN;

-- -----------------------------------------------------------------------------
-- SETUP (role postgres — visível dentro da transação)
-- Dados extras para therapy_resources e daily_monitors
-- -----------------------------------------------------------------------------
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
VALUES
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111102',
    'authenticated',
    'authenticated',
    'rls-admin@esquemacore.test',
    crypt('RlsTest2026!', gen_salt('bf')),
    timezone('utc', now()),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"RLS Admin","clinic_id":"11111111-1111-1111-1111-111111111101","role":"platform_admin"}',
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111103',
    'authenticated',
    'authenticated',
    'rls-psychologist@esquemacore.test',
    crypt('RlsTest2026!', gen_salt('bf')),
    timezone('utc', now()),
    '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"RLS Psychologist","clinic_id":"11111111-1111-1111-1111-111111111101","role":"psychologist"}',
    timezone('utc', now()),
    timezone('utc', now())
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
VALUES
  (
    '11111111-1111-1111-1111-111111111102',
    '11111111-1111-1111-1111-111111111101',
    'RLS Admin',
    'rls-admin@esquemacore.test',
    'platform_admin',
    true
  ),
  (
    '11111111-1111-1111-1111-111111111103',
    '11111111-1111-1111-1111-111111111101',
    'RLS Psychologist',
    'rls-psychologist@esquemacore.test',
    'psychologist',
    true
  )
ON CONFLICT (id) DO UPDATE SET
  clinic_id = EXCLUDED.clinic_id,
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active;

UPDATE public.patients
SET responsible_psychologist_id = '11111111-1111-1111-1111-111111111103'
WHERE id = '11111111-1111-1111-1111-111111111201';

INSERT INTO public.therapy_resources (id, clinic_id, title, type, is_active)
VALUES
  (
    '33333333-3333-3333-3333-333333333301',
    '11111111-1111-1111-1111-111111111101',
    'Recurso liberado (teste RLS)',
    'article',
    true
  ),
  (
    '33333333-3333-3333-3333-333333333302',
    '11111111-1111-1111-1111-111111111101',
    'Recurso NAO liberado (teste RLS)',
    'article',
    true
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.patient_resource_access (
  id, patient_id, resource_id, released_by_profile_id, is_active
)
VALUES (
  '33333333-3333-3333-3333-333333333401',
  '11111111-1111-1111-1111-111111111201',
  '33333333-3333-3333-3333-333333333301',
  '11111111-1111-1111-1111-111111111103',
  true
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.daily_monitors (id, clinic_id, patient_id, mood_notes)
VALUES (
  '33333333-3333-3333-3333-333333333501',
  '11111111-1111-1111-1111-111111111101',
  '11111111-1111-1111-1111-111111111201',
  'Monitor seed smoke test'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.questionnaire_responses (
  id, clinic_id, patient_id, questionnaire_id, status
)
VALUES
  (
    '33333333-3333-3333-3333-333333335901',
    '11111111-1111-1111-1111-111111111101',
    '11111111-1111-1111-1111-111111111201',
    '11111111-1111-1111-1111-111111111301',
    'draft'
  ),
  (
    '33333333-3333-3333-3333-333333335902',
    '11111111-1111-1111-1111-111111111101',
    '11111111-1111-1111-1111-111111111201',
    '11111111-1111-1111-1111-111111111301',
    'draft'
  )
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- Helper: retorna contagem como authenticated user
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp._rls_count_as(p_user_id UUID, p_sql TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
  v_count BIGINT;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user_id::TEXT, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE 'SELECT count(*)::bigint FROM (' || p_sql || ') AS _q' INTO v_count;
  RESET ROLE;
  RETURN v_count;
END;
$$;

CREATE OR REPLACE FUNCTION pg_temp._rls_exec_as(p_user_id UUID, p_sql TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user_id::TEXT, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql;
  RESET ROLE;
  RETURN true;
EXCEPTION
  WHEN OTHERS THEN
    RESET ROLE;
    RETURN false;
END;
$$;

CREATE OR REPLACE FUNCTION pg_temp._rls_rows_as(p_user_id UUID, p_sql TEXT)
RETURNS BIGINT
LANGUAGE plpgsql
AS $$
DECLARE
  v_rows BIGINT;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', p_user_id::TEXT, true);
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  EXECUTE 'SET LOCAL ROLE authenticated';
  EXECUTE p_sql;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  RESET ROLE;
  RETURN v_rows;
EXCEPTION
  WHEN OTHERS THEN
    RESET ROLE;
    RETURN -1;
END;
$$;

DO $$
DECLARE
  v_admin   UUID := '11111111-1111-1111-1111-111111111102';
  v_psych   UUID := '11111111-1111-1111-1111-111111111103';
  v_patient UUID := '11111111-1111-1111-1111-111111111104';
  v_clinic  UUID := '11111111-1111-1111-1111-111111111101';
  v_pat     UUID := '11111111-1111-1111-1111-111111111201';
  v_resp    UUID := '11111111-1111-1111-1111-111111111701';
  v_resp_insert_psych UUID := '33333333-3333-3333-3333-333333335901';
  v_resp_insert_patient UUID := '33333333-3333-3333-3333-333333335902';
  v_quest   UUID := '11111111-1111-1111-1111-111111111301';
  v_cat     UUID := '11111111-1111-1111-1111-111111111401';
  v_nobody  UUID := '99999999-9999-9999-9999-999999999901';
  v_res_ok  UUID := '33333333-3333-3333-3333-333333333301';
  v_res_no  UUID := '33333333-3333-3333-3333-333333333302';
  v_c       BIGINT;
  v_ok      BOOLEAN;
  v_rows    BIGINT;
BEGIN
  RAISE NOTICE '=== RLS SMOKE TESTS (esperado: todos [OK], bloqueios [OK_BLOCKED]) ===';

  -- -------------------------------------------------------------------------
  -- SELECT permitido
  -- -------------------------------------------------------------------------
  v_c := pg_temp._rls_count_as(v_admin, 'SELECT 1 FROM public.clinics');
  RAISE NOTICE 'platform admin SELECT clinics: % [%]', v_c, CASE WHEN v_c >= 1 THEN 'OK' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_admin, 'SELECT 1 FROM public.patients');
  RAISE NOTICE 'platform admin SELECT patients: % [%]', v_c, CASE WHEN v_c = 0 THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_psych, 'SELECT 1 FROM public.patients WHERE id = ''' || v_pat || '''');
  RAISE NOTICE 'psych SELECT own patient: % [%]', v_c, CASE WHEN v_c = 1 THEN 'OK' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_patient, 'SELECT 1 FROM public.patients');
  RAISE NOTICE 'patient SELECT patients: % [%]', v_c, CASE WHEN v_c = 1 THEN 'OK' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_patient, 'SELECT 1 FROM public.questionnaires');
  RAISE NOTICE 'patient SELECT questionnaires: % [%]', v_c, CASE WHEN v_c >= 1 THEN 'OK' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_patient, 'SELECT 1 FROM public.questionnaire_answers WHERE response_id = ''' || v_resp || '''');
  RAISE NOTICE 'patient SELECT answers (5): % [%]', v_c, CASE WHEN v_c = 5 THEN 'OK' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_patient, 'SELECT 1 FROM public.therapy_resources WHERE id = ''' || v_res_ok || '''');
  RAISE NOTICE 'patient SELECT released resource: % [%]', v_c, CASE WHEN v_c = 1 THEN 'OK' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_patient, 'SELECT 1 FROM public.daily_monitors WHERE patient_id = ''' || v_pat || '''');
  RAISE NOTICE 'patient SELECT daily_monitors: % [%]', v_c, CASE WHEN v_c >= 1 THEN 'OK' ELSE 'FAIL' END;

  -- -------------------------------------------------------------------------
  -- SELECT bloqueado
  -- -------------------------------------------------------------------------
  v_c := pg_temp._rls_count_as(v_nobody, 'SELECT 1 FROM public.clinics');
  RAISE NOTICE 'nobody SELECT clinics: % [%]', v_c, CASE WHEN v_c = 0 THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_patient, 'SELECT 1 FROM public.therapy_resources WHERE id = ''' || v_res_no || '''');
  RAISE NOTICE 'patient SELECT unreleased resource: % [%]', v_c, CASE WHEN v_c = 0 THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  v_c := pg_temp._rls_count_as(v_nobody, 'SELECT 1 FROM public.questionnaires');
  RAISE NOTICE 'nobody SELECT questionnaires: % [%]', v_c, CASE WHEN v_c = 0 THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  -- -------------------------------------------------------------------------
  -- INSERT permitido
  -- -------------------------------------------------------------------------
  v_ok := pg_temp._rls_exec_as(
    v_patient,
    'INSERT INTO public.daily_monitors (id, clinic_id, patient_id, mood_notes) VALUES (' ||
    quote_literal('33333333-3333-3333-3333-333333333502') || ', ' ||
    quote_literal(v_clinic) || ', ' || quote_literal(v_pat) || ', ''smoke insert ok'')'
  );
  RAISE NOTICE 'patient INSERT daily_monitor: [%]', CASE WHEN v_ok THEN 'OK' ELSE 'FAIL' END;

  v_ok := pg_temp._rls_exec_as(
    v_psych,
    'INSERT INTO public.therapy_resources (id, clinic_id, title, type) VALUES (' ||
    quote_literal('33333333-3333-3333-3333-333333333903') || ', ' ||
    quote_literal(v_clinic) || ', ''Smoke psych resource'', ''article'')'
  );
  RAISE NOTICE 'psych INSERT therapy_resource: [%]', CASE WHEN v_ok THEN 'OK' ELSE 'FAIL' END;

  v_ok := pg_temp._rls_exec_as(
    v_psych,
    'INSERT INTO public.questionnaire_results (id, response_id, questionnaire_id, category_id, total_score) VALUES (' ||
    quote_literal('33333333-3333-3333-3333-333333333601') || ', ' ||
    quote_literal(v_resp_insert_psych) || ', ' || quote_literal(v_quest) || ', ' ||
    quote_literal(v_cat) || ', 20)'
  );
  RAISE NOTICE 'psych INSERT questionnaire_results: [%]', CASE WHEN v_ok THEN 'OK' ELSE 'FAIL' END;

  -- -------------------------------------------------------------------------
  -- INSERT bloqueado
  -- -------------------------------------------------------------------------
  v_ok := pg_temp._rls_exec_as(
    v_patient,
    'INSERT INTO public.questionnaire_results (id, response_id, questionnaire_id, category_id, total_score) VALUES (' ||
    quote_literal('33333333-3333-3333-3333-333333333602') || ', ' ||
    quote_literal(v_resp_insert_patient) || ', ' || quote_literal(v_quest) || ', ' ||
    quote_literal(v_cat) || ', 99)'
  );
  RAISE NOTICE 'patient INSERT questionnaire_results: [%]', CASE WHEN NOT v_ok THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  v_ok := pg_temp._rls_exec_as(
    v_patient,
    'INSERT INTO public.therapy_resources (id, clinic_id, title, type) VALUES (' ||
    quote_literal('33333333-3333-3333-3333-333333333304') || ', ' ||
    quote_literal(v_clinic) || ', ''Hack'', ''article'')'
  );
  RAISE NOTICE 'patient INSERT therapy_resource: [%]', CASE WHEN NOT v_ok THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  v_ok := pg_temp._rls_exec_as(
    v_patient,
    'INSERT INTO public.patients (id, clinic_id, full_name) VALUES (' ||
    quote_literal('33333333-3333-3333-3333-333333333701') || ', ' ||
    quote_literal(v_clinic) || ', ''Hack patient'')'
  );
  RAISE NOTICE 'patient INSERT patients: [%]', CASE WHEN NOT v_ok THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  v_ok := pg_temp._rls_exec_as(
    v_admin,
    'INSERT INTO public.questionnaires (id, code, name) VALUES (' ||
    quote_literal('33333333-3333-3333-3333-333333333801') || ', ''SMOKE_HACK'', ''Hack'')'
  );
  RAISE NOTICE 'platform admin INSERT questionnaires: [%]', CASE WHEN NOT v_ok THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  -- -------------------------------------------------------------------------
  -- UPDATE permitido
  -- -------------------------------------------------------------------------
  v_ok := pg_temp._rls_exec_as(
    v_admin,
    'UPDATE public.clinics SET phone = phone WHERE id = ' || quote_literal(v_clinic)
  );
  RAISE NOTICE 'platform admin UPDATE clinics: [%]', CASE WHEN v_ok THEN 'OK' ELSE 'FAIL' END;

  v_ok := pg_temp._rls_exec_as(
    v_patient,
    'UPDATE public.questionnaire_answers SET answer_value = answer_value WHERE id = ''11111111-1111-1111-1111-111111111801'''
  );
  RAISE NOTICE 'patient UPDATE questionnaire_answers: [%]', CASE WHEN v_ok THEN 'OK' ELSE 'FAIL' END;

  -- -------------------------------------------------------------------------
  -- UPDATE bloqueado (RLS costuma retornar 0 linhas, sem erro)
  -- -------------------------------------------------------------------------
  v_rows := pg_temp._rls_rows_as(
    v_psych,
    'UPDATE public.clinics SET name = ''Hack'' WHERE id = ' || quote_literal(v_clinic)
  );
  RAISE NOTICE 'psych UPDATE clinics (rows=%): [%]', v_rows, CASE WHEN v_rows = 0 THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  v_rows := pg_temp._rls_rows_as(
    v_patient,
    'UPDATE public.profiles SET full_name = ''Hack'' WHERE id = ''' || v_psych || ''''
  );
  RAISE NOTICE 'patient UPDATE other profile (rows=%): [%]', v_rows, CASE WHEN v_rows = 0 THEN 'OK_BLOCKED' ELSE 'FAIL' END;

  RAISE NOTICE '=== FIM — revisar NOTICE acima; transação será revertida ===';
END;
$$;

ROLLBACK;
