-- Conceituação no formato ISST: cabeçalho (form_header), logo por psicóloga
-- (profiles.document_logo_path + bucket privado document-logos) e guarda de
-- UPDATE de profiles. Stack local de teste apenas; tudo termina em ROLLBACK.
-- Rodar: docker exec -i supabase_db_App_Clinica_Psicologia psql -U postgres -v ON_ERROR_STOP=1 < supabase/tests/conceituacao-formato-tests.sql
BEGIN;

INSERT INTO public.clinics (id, name) VALUES ('ff000000-0000-4000-8000-000000000001', 'Clinica Conceituacao Teste');

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
SELECT '00000000-0000-0000-0000-000000000000', v.id, 'authenticated', 'authenticated', v.email,
  crypt('ConceitTest2026!', gen_salt('bf')), timezone('utc', now()), '', '', '', '',
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, timezone('utc', now()), timezone('utc', now())
FROM (VALUES
  ('ff000000-0000-4000-8000-0000000000a1'::uuid, 'cf-psi-a@esquemacore.test'),
  ('ff000000-0000-4000-8000-0000000000a2'::uuid, 'cf-psi-b@esquemacore.test'),
  ('ff000000-0000-4000-8000-0000000000c1'::uuid, 'cf-pac@esquemacore.test')) AS v(id, email)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
VALUES
 ('ff000000-0000-4000-8000-0000000000a1', 'ff000000-0000-4000-8000-000000000001', 'Psi A', 'cf-psi-a@esquemacore.test', 'psychologist', true),
 ('ff000000-0000-4000-8000-0000000000a2', 'ff000000-0000-4000-8000-000000000001', 'Psi B', 'cf-psi-b@esquemacore.test', 'psychologist', true),
 ('ff000000-0000-4000-8000-0000000000c1', 'ff000000-0000-4000-8000-000000000001', 'Paciente Fic', 'cf-pac@esquemacore.test', 'patient', true)
ON CONFLICT (id) DO UPDATE SET clinic_id = EXCLUDED.clinic_id, role = EXCLUDED.role, is_active = true;

INSERT INTO public.clinics (id, name) VALUES ('ff000000-0000-4000-8000-000000000002', 'Outra Clinica Teste');
INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000000', 'ff000000-0000-4000-8000-0000000000d1', 'authenticated', 'authenticated',
  'cf-psi-d@esquemacore.test', crypt('ConceitTest2026!', gen_salt('bf')), timezone('utc', now()), '', '', '', '',
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, timezone('utc', now()), timezone('utc', now()))
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
VALUES ('ff000000-0000-4000-8000-0000000000d1', 'ff000000-0000-4000-8000-000000000002', 'Psi D', 'cf-psi-d@esquemacore.test', 'psychologist', true)
ON CONFLICT (id) DO UPDATE SET clinic_id = EXCLUDED.clinic_id, role = EXCLUDED.role, is_active = true;

INSERT INTO public.patients (id, clinic_id, responsible_psychologist_id, profile_id, full_name, is_active)
VALUES ('ff000000-0000-4000-8000-0000000000b1', 'ff000000-0000-4000-8000-000000000001',
  'ff000000-0000-4000-8000-0000000000a1', 'ff000000-0000-4000-8000-0000000000c1', 'Paciente Conceituacao Ficticia', true);

-- Objeto de A criado como dono do banco (para testar o que B/paciente/anon NÃO podem).
INSERT INTO storage.objects (bucket_id, name, owner) VALUES
 ('document-logos', 'ff000000-0000-4000-8000-0000000000a1/logo.png', 'ff000000-0000-4000-8000-0000000000a1');

-- Executa um comando como um papel/usuário; devolve 'OK' ou o SQLSTATE do erro.
CREATE FUNCTION pg_temp.as_run(p_uid uuid, p_role text, p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE r text;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', COALESCE(p_uid::text, ''), true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_uid, 'role', p_role)::text, true);
  EXECUTE format('SET LOCAL ROLE %I', p_role);
  BEGIN
    EXECUTE p_sql;
    r := 'OK';
  EXCEPTION WHEN OTHERS THEN
    r := SQLSTATE;
  END;
  RESET ROLE;
  RETURN r;
END $$;

-- Conta linhas visíveis/afetadas como um papel/usuário.
CREATE FUNCTION pg_temp.as_count(p_uid uuid, p_role text, p_sql text) RETURNS bigint
LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
  PERFORM set_config('request.jwt.claim.sub', COALESCE(p_uid::text, ''), true);
  PERFORM set_config('request.jwt.claims',
    jsonb_build_object('sub', p_uid, 'role', p_role)::text, true);
  EXECUTE format('SET LOCAL ROLE %I', p_role);
  EXECUTE 'WITH x AS (' || p_sql || ' RETURNING 1) SELECT count(*) FROM x' INTO n;
  RESET ROLE;
  RETURN n;
END $$;


-- 1) colunas, checks e bucket
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public'
      AND table_name='case_conceptualizations' AND column_name='form_header' AND data_type='jsonb') THEN
    RAISE EXCEPTION 'FALHA 1: form_header ausente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public'
      AND table_name='profiles' AND column_name='document_logo_path') THEN
    RAISE EXCEPTION 'FALHA 1: document_logo_path ausente';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM storage.buckets WHERE id='document-logos' AND public IS FALSE
      AND file_size_limit = 2097152
      AND allowed_mime_types @> ARRAY['image/png','image/jpeg','image/webp']
      AND cardinality(allowed_mime_types) = 3) THEN
    RAISE EXCEPTION 'FALHA 1: bucket document-logos ausente, público ou com limites errados';
  END IF;
END $$;

-- 2) form_header: default {}, aceita o contrato, recusa não-objeto e >2KB; dado antigo intacto
DO $$
DECLARE v jsonb;
BEGIN
  INSERT INTO public.case_conceptualizations (clinic_id, patient_id, therapeutic_relationship)
  VALUES ('ff000000-0000-4000-8000-000000000001', 'ff000000-0000-4000-8000-0000000000b1',
          '{"collaboration_notes":"texto antigo fictício"}'::jsonb);
  SELECT form_header INTO v FROM public.case_conceptualizations
   WHERE patient_id = 'ff000000-0000-4000-8000-0000000000b1';
  IF v <> '{}'::jsonb THEN RAISE EXCEPTION 'FALHA 2: default de form_header = %', v; END IF;

  UPDATE public.case_conceptualizations
     SET form_header = '{"therapist_name":"Psi A","form_date":"2026-11-22","sessions_count":12,"months_since_first":3}'
   WHERE patient_id = 'ff000000-0000-4000-8000-0000000000b1';

  BEGIN
    UPDATE public.case_conceptualizations SET form_header = '[1]'::jsonb
     WHERE patient_id = 'ff000000-0000-4000-8000-0000000000b1';
    RAISE EXCEPTION 'FALHA 2: form_header array aceito';
  EXCEPTION WHEN check_violation THEN NULL; END;
  BEGIN
    UPDATE public.case_conceptualizations
       SET form_header = jsonb_build_object('therapist_name', repeat('x', 3000))
     WHERE patient_id = 'ff000000-0000-4000-8000-0000000000b1';
    RAISE EXCEPTION 'FALHA 2: form_header > 2KB aceito';
  EXCEPTION WHEN check_violation THEN NULL; END;

  IF (SELECT therapeutic_relationship->>'collaboration_notes' FROM public.case_conceptualizations
       WHERE patient_id = 'ff000000-0000-4000-8000-0000000000b1') <> 'texto antigo fictício' THEN
    RAISE EXCEPTION 'FALHA 2: texto antigo da relação terapêutica mudou';
  END IF;
END $$;

-- 3) RLS da conceituação inalterada, cada condição provada separadamente
-- (is_staff / clinic_id / user_can_access_patient). A linha de A existe (teste 2).
DO $$
DECLARE a uuid := 'ff000000-0000-4000-8000-0000000000a1'; b uuid := 'ff000000-0000-4000-8000-0000000000a2';
        c uuid := 'ff000000-0000-4000-8000-0000000000c1'; d uuid := 'ff000000-0000-4000-8000-0000000000d1';
        n bigint; r text;
BEGIN
  -- controle: a responsável A alcança a linha; sem isso os 0 abaixo não provariam nada
  IF pg_temp.as_count(a,'authenticated','UPDATE public.case_conceptualizations SET updated_by = updated_by') <> 1 THEN
    RAISE EXCEPTION 'FALHA 3: controle: A não alcança a própria conceituação';
  END IF;
  -- (i) paciente: user_can_access_patient = true para o próprio registro, mas is_staff = false
  PERFORM set_config('request.jwt.claim.sub', c::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', c, 'role', 'authenticated')::text, true);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO n FROM public.case_conceptualizations;
  RESET ROLE;
  IF n <> 0 THEN RAISE EXCEPTION 'FALHA 3(i): paciente LÊ % conceituação(ões)', n; END IF;
  IF pg_temp.as_count(c,'authenticated','UPDATE public.case_conceptualizations SET additional_comments = ''x''') <> 0 THEN
    RAISE EXCEPTION 'FALHA 3(i): paciente alterou conceituação';
  END IF;
  r := pg_temp.as_run(c,'authenticated',
    'INSERT INTO public.case_conceptualizations (clinic_id, patient_id) VALUES (''ff000000-0000-4000-8000-000000000001'',''ff000000-0000-4000-8000-0000000000b1'')');
  IF r = 'OK' THEN RAISE EXCEPTION 'FALHA 3(i): paciente inseriu conceituação'; END IF;
  -- (ii) psicóloga B: staff e mesma clínica, mas SEM vínculo com o paciente
  PERFORM set_config('request.jwt.claim.sub', b::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', b, 'role', 'authenticated')::text, true);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO n FROM public.case_conceptualizations;
  RESET ROLE;
  IF n <> 0 THEN RAISE EXCEPTION 'FALHA 3(ii): psicóloga sem vínculo LÊ % linha(s)', n; END IF;
  IF pg_temp.as_count(b,'authenticated','UPDATE public.case_conceptualizations SET form_header = ''{}''::jsonb') <> 0 THEN
    RAISE EXCEPTION 'FALHA 3(ii): psicóloga sem vínculo alterou conceituação';
  END IF;
  -- (iii) psicóloga de OUTRA clínica
  PERFORM set_config('request.jwt.claim.sub', d::text, true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', d, 'role', 'authenticated')::text, true);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO n FROM public.case_conceptualizations;
  RESET ROLE;
  IF n <> 0 THEN RAISE EXCEPTION 'FALHA 3(iii): psicóloga de outra clínica LÊ % linha(s)', n; END IF;
  -- (iv) anon: sem acesso (erro 42501 ou 0 linhas; nunca linhas)
  PERFORM set_config('request.jwt.claim.sub', '', true);
  PERFORM set_config('request.jwt.claims', jsonb_build_object('role', 'anon')::text, true);
  BEGIN
    SET LOCAL ROLE anon;
    SELECT count(*) INTO n FROM public.case_conceptualizations;
    RESET ROLE;
    IF n <> 0 THEN RAISE EXCEPTION 'FALHA 3(iv): anon LÊ % linha(s)', n; END IF;
  EXCEPTION WHEN insufficient_privilege THEN
    RESET ROLE;
  END;
END $$;

-- 4) profiles: A grava a própria logo (e o carimbo muda); path de outro perfil é recusado
DO $$
DECLARE a uuid := 'ff000000-0000-4000-8000-0000000000a1'; b uuid := 'ff000000-0000-4000-8000-0000000000a2'; r text;
BEGIN
  r := pg_temp.as_run(a,'authenticated',
    format('UPDATE public.profiles SET document_logo_path = %L WHERE id = %L', a||'/logo.png', a));
  IF r <> 'OK' THEN RAISE EXCEPTION 'FALHA 4: A não gravou a própria logo (%)', r; END IF;
  IF (SELECT document_logo_updated_at FROM public.profiles WHERE id = a) IS NULL THEN
    RAISE EXCEPTION 'FALHA 4: document_logo_updated_at não foi carimbado';
  END IF;
  -- path da pasta de B no perfil de A: CHECK barra (23514)
  r := pg_temp.as_run(a,'authenticated',
    format('UPDATE public.profiles SET document_logo_path = %L WHERE id = %L', b||'/logo.png', a));
  IF r <> '23514' THEN RAISE EXCEPTION 'FALHA 4: path de outro perfil: esperado 23514, veio %', r; END IF;
  -- path fora do padrão
  r := pg_temp.as_run(a,'authenticated',
    format('UPDATE public.profiles SET document_logo_path = %L WHERE id = %L', a||'/qualquer.png', a));
  IF r <> '23514' THEN RAISE EXCEPTION 'FALHA 4: path fora do padrão: esperado 23514, veio %', r; END IF;
  -- A tenta mexer na logo de B: guarda recusa (42501) ou RLS não afeta linha
  r := pg_temp.as_run(a,'authenticated',
    format('UPDATE public.profiles SET document_logo_path = %L WHERE id = %L', b||'/logo.png', b));
  IF r = 'OK' AND (SELECT document_logo_path FROM public.profiles WHERE id = b) IS NOT NULL THEN
    RAISE EXCEPTION 'FALHA 4: A alterou a logo de B';
  END IF;
  -- limpar a própria logo funciona
  r := pg_temp.as_run(a,'authenticated',
    format('UPDATE public.profiles SET document_logo_path = NULL WHERE id = %L', a));
  IF r <> 'OK' THEN RAISE EXCEPTION 'FALHA 4: A não removeu a logo (%)', r; END IF;
END $$;

-- 5) guarda: role / clinic_id / is_active continuam bloqueados (42501), mesmo junto da logo
DO $$
DECLARE a uuid := 'ff000000-0000-4000-8000-0000000000a1'; r text; col text; val text;
BEGIN
  FOREACH col IN ARRAY ARRAY['role','is_active','clinic_id'] LOOP
    val := CASE col WHEN 'role' THEN '''platform_admin''' WHEN 'is_active' THEN 'false'
                    ELSE '''ff000000-0000-4000-8000-000000000999''::uuid' END;
    r := pg_temp.as_run(a,'authenticated',
      format('UPDATE public.profiles SET %I = %s WHERE id = %L', col, val, a));
    IF r NOT IN ('42501') THEN RAISE EXCEPTION 'FALHA 5: % sozinho: esperado 42501, veio %', col, r; END IF;
    r := pg_temp.as_run(a,'authenticated',
      format('UPDATE public.profiles SET %I = %s, document_logo_path = %L WHERE id = %L',
             col, val, a||'/logo.png', a));
    IF r NOT IN ('42501') THEN RAISE EXCEPTION 'FALHA 5: % com logo: esperado 42501, veio %', col, r; END IF;
  END LOOP;
  IF (SELECT role::text || is_active::text FROM public.profiles WHERE id = a) <> 'psychologisttrue' THEN
    RAISE EXCEPTION 'FALHA 5: perfil de A foi alterado';
  END IF;
  -- allowlist antiga segue valendo
  r := pg_temp.as_run(a,'authenticated',
    format('UPDATE public.profiles SET full_name = %L WHERE id = %L', 'Psi A Editada', a));
  IF r <> 'OK' THEN RAISE EXCEPTION 'FALHA 5: full_name (allowlist antiga) recusado (%)', r; END IF;
END $$;

-- 6) storage: dono escreve/lê/troca/apaga SÓ no próprio path
DO $$
DECLARE a uuid := 'ff000000-0000-4000-8000-0000000000a1'; b uuid := 'ff000000-0000-4000-8000-0000000000a2'; r text;
BEGIN
  r := pg_temp.as_run(b,'authenticated',
    format('INSERT INTO storage.objects (bucket_id,name,owner) VALUES (''document-logos'',%L,%L)', b||'/logo.webp', b));
  IF r <> 'OK' THEN RAISE EXCEPTION 'FALHA 6: B não gravou a própria logo (%)', r; END IF;
  IF pg_temp.as_count(b,'authenticated',
      format('UPDATE storage.objects SET metadata = ''{}''::jsonb WHERE bucket_id=''document-logos'' AND name=%L', b||'/logo.webp')) <> 1 THEN
    RAISE EXCEPTION 'FALHA 6: B não trocou a própria logo';
  END IF;
END $$;

-- 7) isolamento: B, paciente e anon não leem / escrevem / apagam o objeto de A
DO $$
DECLARE a uuid := 'ff000000-0000-4000-8000-0000000000a1'; b uuid := 'ff000000-0000-4000-8000-0000000000a2';
        c uuid := 'ff000000-0000-4000-8000-0000000000c1'; obj text := 'ff000000-0000-4000-8000-0000000000a1/logo.png';
        who record; r text;
BEGIN
  -- A lê o próprio
  IF pg_temp.as_count(a,'authenticated', 'UPDATE storage.objects SET metadata = ''{}''::jsonb WHERE bucket_id=''document-logos'' AND name='''||obj||'''') <> 1 THEN
    RAISE EXCEPTION 'FALHA 7: A não alcança o próprio objeto';
  END IF;
  FOR who IN SELECT * FROM (VALUES ('psicóloga B', b, 'authenticated'), ('paciente', c, 'authenticated'), ('anon', NULL::uuid, 'anon')) t(label, uid, rol) LOOP
    -- leitura
    IF pg_temp.as_run(who.uid, who.rol, 'SELECT 1 FROM storage.objects WHERE bucket_id=''document-logos'' AND name='''||obj||'''') = 'OK'
       AND pg_temp.as_count(who.uid, who.rol, 'UPDATE storage.objects SET name = name WHERE bucket_id=''document-logos'' AND name='''||obj||'''') <> 0 THEN
      RAISE EXCEPTION 'FALHA 7: % alterou objeto de A', who.label;
    END IF;
    -- SELECT visível?
    PERFORM set_config('request.jwt.claim.sub', COALESCE(who.uid::text,''), true);
    PERFORM set_config('request.jwt.claims', jsonb_build_object('sub', who.uid, 'role', who.rol)::text, true);
    EXECUTE format('SET LOCAL ROLE %I', who.rol);
    IF (SELECT count(*) FROM storage.objects WHERE bucket_id='document-logos' AND name=obj) <> 0 THEN
      RESET ROLE; RAISE EXCEPTION 'FALHA 7: % LÊ o objeto de A', who.label;
    END IF;
    RESET ROLE;
    -- escrita em pasta alheia
    r := pg_temp.as_run(who.uid, who.rol,
      'INSERT INTO storage.objects (bucket_id,name) VALUES (''document-logos'','''||a||'/logo.jpg'')');
    IF r = 'OK' THEN RAISE EXCEPTION 'FALHA 7: % gravou na pasta de A', who.label; END IF;
    -- apagar
    BEGIN
      IF pg_temp.as_count(who.uid, who.rol, 'DELETE FROM storage.objects WHERE bucket_id=''document-logos'' AND name='''||obj||'''') <> 0 THEN
        RAISE EXCEPTION 'FALHA 7: % apagou objeto de A', who.label;
      END IF;
    EXCEPTION WHEN insufficient_privilege THEN NULL; END;
  END LOOP;
  IF NOT EXISTS (SELECT 1 FROM storage.objects WHERE bucket_id='document-logos' AND name=obj) THEN
    RAISE EXCEPTION 'FALHA 7: objeto de A sumiu';
  END IF;
  -- paciente e anon também não gravam na PRÓPRIA pasta (não há papel para isso)
  -- (paciente autenticado tem uid próprio; a policy só valida o path, então o paciente
  --  poderia gravar em c/logo.png: o app não oferece e não há leitura por terceiros)
END $$;

-- 7b) paciente (e perfil inativo) NÃO sobe logo, nem na própria pasta: 42501
DO $$
DECLARE c uuid := 'ff000000-0000-4000-8000-0000000000c1'; a uuid := 'ff000000-0000-4000-8000-0000000000a1'; r text;
BEGIN
  r := pg_temp.as_run(c,'authenticated',
    format('INSERT INTO storage.objects (bucket_id,name,owner) VALUES (''document-logos'',%L,%L)', c||'/logo.png', c));
  IF r <> '42501' THEN RAISE EXCEPTION 'FALHA 7b: paciente subiu logo na própria pasta (%)', r; END IF;
  IF (SELECT count(*) FROM storage.objects WHERE bucket_id='document-logos' AND name = c||'/logo.png') <> 0 THEN
    RAISE EXCEPTION 'FALHA 7b: objeto de paciente existe';
  END IF;
  -- objeto de paciente criado por fora: ele não consegue trocá-lo (UPDATE: 0 linhas)
  INSERT INTO storage.objects (bucket_id,name,owner) VALUES ('document-logos', c||'/logo.png', c);
  IF pg_temp.as_count(c,'authenticated',
      format('UPDATE storage.objects SET metadata = ''{}''::jsonb WHERE bucket_id=''document-logos'' AND name=%L', c||'/logo.png')) <> 0 THEN
    RAISE EXCEPTION 'FALHA 7b: paciente trocou objeto';
  END IF;
  -- psicóloga inativa também não grava
  UPDATE public.profiles SET is_active = false WHERE id = a;
  r := pg_temp.as_run(a,'authenticated',
    format('INSERT INTO storage.objects (bucket_id,name,owner) VALUES (''document-logos'',%L,%L)', a||'/logo.jpg', a));
  UPDATE public.profiles SET is_active = true WHERE id = a;
  IF r = 'OK' THEN RAISE EXCEPTION 'FALHA 7b: perfil inativo subiu logo'; END IF;
END $$;

-- 8) path fora do padrão no bucket é recusado até para o dono
DO $$
DECLARE a uuid := 'ff000000-0000-4000-8000-0000000000a1'; r text; p text;
BEGIN
  FOREACH p IN ARRAY ARRAY[a||'/outro.png', a||'/sub/logo.png', a||'/logo.gif', 'logo.png'] LOOP
    r := pg_temp.as_run(a,'authenticated',
      format('INSERT INTO storage.objects (bucket_id,name,owner) VALUES (''document-logos'',%L,%L)', p, a));
    IF r = 'OK' THEN RAISE EXCEPTION 'FALHA 8: path % aceito', p; END IF;
  END LOOP;
END $$;

-- 9) policies do bucket: só as 4 do dono, todas TO authenticated (nada para public/anon)
DO $$
BEGIN
  IF (SELECT count(*) FROM pg_policies WHERE schemaname='storage' AND tablename='objects'
      AND policyname LIKE 'document_logos_%') <> 4 THEN
    RAISE EXCEPTION 'FALHA 9: número de policies do bucket <> 4';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='storage' AND tablename='objects'
      AND policyname LIKE 'document_logos_%' AND NOT ('authenticated' = ANY(roles) AND cardinality(roles) = 1)) THEN
    RAISE EXCEPTION 'FALHA 9: policy do bucket aberta a outro papel';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.case_conceptualizations'::regclass) THEN
    RAISE EXCEPTION 'FALHA 9: RLS desligada em case_conceptualizations';
  END IF;
END $$;

DO $$ BEGIN RAISE NOTICE 'conceituacao-formato-tests: TODOS OK'; END $$;

ROLLBACK;
