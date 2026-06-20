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
VALUES
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111102',
    'authenticated', 'authenticated',
    'governance-admin@esquemacore.test',
    crypt('GovernanceTest2026!', gen_salt('bf')),
    timezone('utc', now()), '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Governance Admin","clinic_id":"11111111-1111-1111-1111-111111111101","role":"platform_admin"}',
    timezone('utc', now()), timezone('utc', now())
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111103',
    'authenticated', 'authenticated',
    'governance-psychologist@esquemacore.test',
    crypt('GovernanceTest2026!', gen_salt('bf')),
    timezone('utc', now()), '', '', '', '',
    '{"provider":"email","providers":["email"]}',
    '{"full_name":"Governance Psychologist","clinic_id":"11111111-1111-1111-1111-111111111101","role":"psychologist"}',
    timezone('utc', now()), timezone('utc', now())
  )
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
VALUES
  (
    '11111111-1111-1111-1111-111111111102',
    '11111111-1111-1111-1111-111111111101',
    'Governance Admin', 'governance-admin@esquemacore.test',
    'platform_admin', true
  ),
  (
    '11111111-1111-1111-1111-111111111103',
    '11111111-1111-1111-1111-111111111101',
    'Governance Psychologist', 'governance-psychologist@esquemacore.test',
    'psychologist', true
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

DO $$
DECLARE
  v_consent_count INTEGER;
  v_audit_count INTEGER;
BEGIN
  PERFORM set_config(
    'request.jwt.claim.sub',
    '11111111-1111-1111-1111-111111111102',
    true
  );
  PERFORM set_config('request.jwt.claim.role', 'authenticated', true);
  SET LOCAL ROLE authenticated;

  INSERT INTO public.legal_consents (
    clinic_id,
    profile_id,
    document_type,
    document_version,
    source
  )
  VALUES (
    '11111111-1111-1111-1111-111111111101',
    '11111111-1111-1111-1111-111111111102',
    'terms',
    'governance-test',
    'sql-test'
  );

  SELECT count(*) INTO v_consent_count
  FROM public.legal_consents
  WHERE profile_id = '11111111-1111-1111-1111-111111111102'
    AND document_version = 'governance-test';

  IF v_consent_count <> 1 THEN
    RAISE EXCEPTION 'Legal consent was not persisted';
  END IF;

  RESET ROLE;
  PERFORM set_config(
    'request.jwt.claim.sub',
    '11111111-1111-1111-1111-111111111103',
    true
  );
  SET LOCAL ROLE authenticated;

  UPDATE public.patients
  SET updated_at = timezone('utc', now())
  WHERE id = '11111111-1111-1111-1111-111111111201';

  RESET ROLE;
  PERFORM set_config(
    'request.jwt.claim.sub',
    '11111111-1111-1111-1111-111111111102',
    true
  );
  SET LOCAL ROLE authenticated;

  SELECT count(*) INTO v_audit_count
  FROM public.audit_events
  WHERE entity_type = 'patients'
    AND entity_id = '11111111-1111-1111-1111-111111111201'
    AND action = 'update';

  IF v_audit_count < 1 THEN
    RAISE EXCEPTION 'Sensitive update was not audited';
  END IF;

  RAISE NOTICE 'Production governance tests: OK';
END;
$$;

ROLLBACK;
