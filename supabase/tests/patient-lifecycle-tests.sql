-- Reversible patient inactivation must preserve records and enforce ownership.
BEGIN;

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
VALUES (
  '00000000-0000-0000-0000-000000000000',
  '11111111-1111-1111-1111-111111111103',
  'authenticated',
  'authenticated',
  'lifecycle-psychologist@esquemacore.test',
  crypt('LifecycleTest2026!', gen_salt('bf')),
  timezone('utc', now()),
  '', '', '', '',
  '{"provider":"email","providers":["email"]}',
  '{"full_name":"Lifecycle Psychologist","clinic_id":"11111111-1111-1111-1111-111111111101","role":"psychologist"}',
  timezone('utc', now()),
  timezone('utc', now())
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (
  id, clinic_id, full_name, email, role, is_active
)
VALUES (
  '11111111-1111-1111-1111-111111111103',
  '11111111-1111-1111-1111-111111111101',
  'Lifecycle Psychologist',
  'lifecycle-psychologist@esquemacore.test',
  'psychologist',
  true
)
ON CONFLICT (id) DO UPDATE SET
  clinic_id = EXCLUDED.clinic_id,
  full_name = EXCLUDED.full_name,
  email = EXCLUDED.email,
  role = EXCLUDED.role,
  is_active = EXCLUDED.is_active;

UPDATE public.profiles
SET is_active = true
WHERE id = '11111111-1111-1111-1111-111111111104';

UPDATE public.patients
SET
  responsible_psychologist_id = '11111111-1111-1111-1111-111111111103',
  is_active = true,
  inactivated_at = NULL,
  inactivated_by = NULL
WHERE id = '11111111-1111-1111-1111-111111111201';

DO $$
DECLARE
  v_patient public.patients%ROWTYPE;
  v_profile_active BOOLEAN;
  v_audit_count INTEGER;
  v_blocked BOOLEAN := false;
BEGIN
  PERFORM set_config(
    'request.jwt.claim.sub',
    '11111111-1111-1111-1111-111111111103',
    true
  );
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  SET LOCAL ROLE authenticated;

  SELECT * INTO v_patient
  FROM public.set_patient_active_status(
    '11111111-1111-1111-1111-111111111201',
    false
  );

  IF v_patient.is_active OR v_patient.inactivated_at IS NULL THEN
    RAISE EXCEPTION 'Patient was not inactivated';
  END IF;

  RESET ROLE;

  SELECT is_active INTO v_profile_active
  FROM public.profiles
  WHERE id = v_patient.profile_id;

  IF v_patient.profile_id IS NOT NULL AND v_profile_active THEN
    RAISE EXCEPTION 'Patient login was not blocked';
  END IF;

  SELECT count(*) INTO v_audit_count
  FROM public.audit_events
  WHERE patient_id = v_patient.id
    AND action = 'patient_inactivated';

  IF v_audit_count < 1 THEN
    RAISE EXCEPTION 'Patient inactivation was not audited';
  END IF;

  PERFORM set_config(
    'request.jwt.claim.sub',
    '11111111-1111-1111-1111-111111111104',
    true
  );
  SET LOCAL ROLE authenticated;

  BEGIN
    PERFORM public.set_patient_active_status(v_patient.id, true);
  EXCEPTION WHEN insufficient_privilege THEN
    v_blocked := true;
  END;

  IF NOT v_blocked THEN
    RAISE EXCEPTION 'Patient was able to reactivate the clinical record';
  END IF;

  RESET ROLE;
  PERFORM set_config(
    'request.jwt.claim.sub',
    '11111111-1111-1111-1111-111111111103',
    true
  );
  SET LOCAL ROLE authenticated;

  SELECT * INTO v_patient
  FROM public.set_patient_active_status(v_patient.id, true);

  IF NOT v_patient.is_active OR v_patient.inactivated_at IS NOT NULL THEN
    RAISE EXCEPTION 'Patient was not reactivated';
  END IF;

  RAISE NOTICE 'Patient lifecycle tests: OK';
END;
$$;

ROLLBACK;
