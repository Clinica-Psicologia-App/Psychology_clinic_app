-- patient_invitations: escrita só pelo servidor (migration 20261127120000).
-- Autorização direta (anon, psicóloga, platform_admin, paciente), leitura que
-- continua, service_role e o gatilho de validação. Exige a migration aplicada.
-- Stack local de teste apenas; tudo em uma transação que termina em ROLLBACK.
-- Dados fictícios.
-- Rodar: docker exec -i supabase_db_App_Clinica_Psicologia psql -U postgres -v ON_ERROR_STOP=1 < supabase/tests/convites-so-servidor-tests.sql
BEGIN;

CREATE TEMP TABLE _r (n serial, label text, ok boolean, got text);

CREATE FUNCTION pg_temp.eq(p_label text, p_got text, p_expected text) RETURNS void
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO pg_temp._r (label, ok, got)
  VALUES (p_label, p_got IS NOT DISTINCT FROM p_expected, p_got);
END $$;

-- Roda um comando como um papel da API. Devolve 'ok:<linhas>' ou o SQLSTATE.
CREATE FUNCTION pg_temp.run_as(p_role text, p_uid uuid, p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
  PERFORM set_config('request.jwt.claims',
    json_build_object('sub', p_uid, 'role', p_role)::text, true);
  PERFORM set_config('request.jwt.claim.sub', COALESCE(p_uid::text, ''), true);
  BEGIN
    EXECUTE format('SET LOCAL ROLE %I', p_role);
    EXECUTE p_sql;
    GET DIAGNOSTICS n = ROW_COUNT;
    RESET ROLE;
    RETURN 'ok:' || n;
  EXCEPTION WHEN OTHERS THEN
    RETURN SQLSTATE;  -- o subbloco desfaz o comando e o SET ROLE
  END;
END $$;

-- Roda como dono (manutenção). Devolve 'ok:<linhas>' ou o SQLSTATE.
CREATE FUNCTION pg_temp.run_owner(p_sql text) RETURNS text
LANGUAGE plpgsql AS $$
DECLARE n bigint;
BEGIN
  PERFORM set_config('request.jwt.claims', '', true);
  PERFORM set_config('request.jwt.claim.sub', '', true);
  EXECUTE p_sql;
  GET DIAGNOSTICS n = ROW_COUNT;
  RETURN 'ok:' || n;
EXCEPTION WHEN OTHERS THEN
  RETURN SQLSTATE;
END $$;

-- ---------------------------------------------------------------------------
-- Dados fictícios
-- ---------------------------------------------------------------------------
INSERT INTO public.clinics (id, name) VALUES
  ('cc000000-0000-4000-8000-000000000001', 'Clinica Convite A'),
  ('cc000000-0000-4000-8000-000000000002', 'Clinica Convite B');

CREATE TEMP TABLE _u (k text PRIMARY KEY, id uuid, clinic uuid, role text);
INSERT INTO _u VALUES
  ('psy_a',  'cc000000-0000-4000-8000-0000000000a1', 'cc000000-0000-4000-8000-000000000001', 'psychologist'),
  ('psy_a2', 'cc000000-0000-4000-8000-0000000000a2', 'cc000000-0000-4000-8000-000000000001', 'psychologist'),
  ('psy_b',  'cc000000-0000-4000-8000-0000000000a3', 'cc000000-0000-4000-8000-000000000002', 'psychologist'),
  ('plat',   'cc000000-0000-4000-8000-0000000000a4', 'cc000000-0000-4000-8000-000000000002', 'platform_admin'),
  ('pat',    'cc000000-0000-4000-8000-0000000000a5', 'cc000000-0000-4000-8000-000000000001', 'patient');

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
SELECT '00000000-0000-0000-0000-000000000000', id, 'authenticated', 'authenticated',
  'conv-' || k || '@esquemacore.test', crypt('ConviteTeste2026!', gen_salt('bf')), now(), '', '', '', '',
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now()
FROM _u;

INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
SELECT id, clinic, 'Pessoa Ficticia ' || k, 'conv-' || k || '@esquemacore.test',
  role::public.profile_role, true
FROM _u
ON CONFLICT (id) DO UPDATE SET clinic_id = EXCLUDED.clinic_id, role = EXCLUDED.role, is_active = true;

INSERT INTO public.patients (id, clinic_id, responsible_psychologist_id, full_name, is_active)
VALUES ('cc000000-0000-4000-8000-0000000000b1', 'cc000000-0000-4000-8000-000000000001',
  'cc000000-0000-4000-8000-0000000000a1', 'Paciente Ficticia', true);

-- Cria um convite como dono. c/i/r = chaves de _u para clínica, autor e responsável.
CREATE FUNCTION pg_temp.invite_sql(p_id int, p_c text, p_i text, p_r text,
  p_status text DEFAULT 'pending', p_expires text DEFAULT $e$now() + interval '7 days'$e$)
RETURNS text LANGUAGE sql AS $$
  SELECT format($f$INSERT INTO public.patient_invitations
    (id, clinic_id, invited_by, responsible_psychologist_id, email, token_hash, status, expires_at)
    VALUES (%L, %L, %L, %L, %L, 'hash-ficticio', %L, %s)$f$,
    ('cc000000-0000-4000-8000-' || lpad(p_id::text, 12, '0'))::uuid,
    (SELECT clinic FROM pg_temp._u WHERE k = p_c),
    (SELECT id FROM pg_temp._u WHERE k = p_i),
    (SELECT id FROM pg_temp._u WHERE k = p_r),
    'convite' || p_id || '@esquemacore.test', p_status, p_expires)
$$;

CREATE FUNCTION pg_temp.inv(p_id int) RETURNS text LANGUAGE sql AS $$
  SELECT quote_literal(('cc000000-0000-4000-8000-' || lpad(p_id::text, 12, '0'))::uuid)
$$;

CREATE FUNCTION pg_temp.uid(p_k text) RETURNS uuid LANGUAGE sql AS
  $$ SELECT id FROM pg_temp._u WHERE k = p_k $$;

SELECT pg_temp.eq('fixture: convite da clínica A', pg_temp.run_owner(pg_temp.invite_sql(1, 'psy_a', 'psy_a', 'psy_a')), 'ok:1');
SELECT pg_temp.eq('fixture: convite da clínica B', pg_temp.run_owner(pg_temp.invite_sql(2, 'psy_b', 'psy_b', 'psy_b')), 'ok:1');

-- ---------------------------------------------------------------------------
-- A) Catálogo
-- ---------------------------------------------------------------------------
SELECT pg_temp.eq('policies: só as duas de SELECT',
  (SELECT string_agg(policyname || ':' || cmd, ',' ORDER BY policyname) FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'patient_invitations'),
  'patient_invitations_select_platform_admin:SELECT,patient_invitations_select_psychologist:SELECT');

SELECT pg_temp.eq('grants: anon/authenticated/PUBLIC',
  (SELECT string_agg(g || '=' || privilege_type, ',' ORDER BY g, privilege_type) FROM (
     SELECT CASE WHEN a.grantee = 0 THEN 'PUBLIC' ELSE a.grantee::regrole::text END AS g, a.privilege_type
     FROM pg_class c, aclexplode(c.relacl) a
     WHERE c.oid = 'public.patient_invitations'::regclass) x
   WHERE g IN ('anon', 'authenticated', 'PUBLIC')),
  'authenticated=SELECT');

SELECT pg_temp.eq('grants: nenhum privilégio de coluna',
  (SELECT count(*)::text FROM pg_attribute
    WHERE attrelid = 'public.patient_invitations'::regclass AND attacl IS NOT NULL), '0');

SELECT pg_temp.eq('grants: service_role ' || p,
  has_table_privilege('service_role', 'public.patient_invitations', p)::text, 'true')
FROM unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE']) p;

SELECT pg_temp.eq('gatilho: SECURITY DEFINER com search_path vazio',
  (SELECT prosecdef::text || ' ' || array_to_string(proconfig, ',') FROM pg_proc
    WHERE oid = 'public.validate_patient_invitation()'::regprocedure),
  'true search_path=""');

SELECT pg_temp.eq('gatilho: sem EXECUTE para ' || r,
  has_function_privilege(r, 'public.validate_patient_invitation()', 'EXECUTE')::text, 'false')
FROM unnest(ARRAY['anon', 'authenticated']) r;

-- ---------------------------------------------------------------------------
-- B) Acesso direto pela API
-- ---------------------------------------------------------------------------
-- SELECT continua com o mesmo alcance
SELECT pg_temp.eq('select ' || who, pg_temp.run_as('authenticated', pg_temp.uid(who),
  format('SELECT id, status, email FROM public.patient_invitations WHERE id IN (%s, %s)',
    pg_temp.inv(1), pg_temp.inv(2))), expected)
FROM (VALUES ('psy_a', 'ok:1'), ('psy_a2', 'ok:0'), ('psy_b', 'ok:1'),
             ('plat', 'ok:2'), ('pat', 'ok:0')) AS t(who, expected);

SELECT pg_temp.eq('select anon', pg_temp.run_as('anon', NULL,
  'SELECT id FROM public.patient_invitations'), '42501');

-- Nenhuma escrita, nem a que as policies antigas permitiam
CREATE TEMP TABLE _w (op text, sql text);
INSERT INTO _w VALUES
  ('insert', pg_temp.invite_sql(10, 'psy_a', 'psy_a', 'psy_a')),
  ('upsert', pg_temp.invite_sql(1, 'psy_a', 'psy_a', 'psy_a') || ' ON CONFLICT (id) DO UPDATE SET status = ''accepted'''),
  ('update status', 'UPDATE public.patient_invitations SET status = ''revoked'' WHERE id = ' || pg_temp.inv(1)),
  ('update token', 'UPDATE public.patient_invitations SET token_hash = ''outro'', email = ''x@esquemacore.test'' WHERE id = ' || pg_temp.inv(1)),
  ('delete', 'DELETE FROM public.patient_invitations WHERE id = ' || pg_temp.inv(1)),
  ('truncate', 'TRUNCATE public.patient_invitations'),
  ('select for update', 'SELECT id FROM public.patient_invitations FOR UPDATE');

SELECT pg_temp.eq(w.op || ' ' || a.who, pg_temp.run_as(a.api_role, a.uid, w.sql), '42501')
FROM _w w CROSS JOIN (
  SELECT 'psy_a' AS who, 'authenticated' AS api_role, pg_temp.uid('psy_a') AS uid
  UNION ALL SELECT 'plat', 'authenticated', pg_temp.uid('plat')
  UNION ALL SELECT 'pat', 'authenticated', pg_temp.uid('pat')
  UNION ALL SELECT 'anon', 'anon', NULL::uuid) a;

SELECT pg_temp.eq('depois das tentativas: convite intacto',
  (SELECT count(*)::text || ' ' || min(status) || ' ' || min(token_hash) FROM public.patient_invitations
    WHERE id = 'cc000000-0000-4000-8000-000000000001'), '1 pending hash-ficticio');

-- Segunda barreira: mesmo se o privilégio voltar por engano, a RLS não deixa
GRANT INSERT, UPDATE, DELETE ON public.patient_invitations TO authenticated;
SELECT pg_temp.eq('sem policy: ' || w.op || ' ' || a.who,
  pg_temp.run_as('authenticated', pg_temp.uid(a.who), w.sql),
  CASE WHEN w.op = 'insert' THEN '42501' ELSE 'ok:0' END)
FROM _w w CROSS JOIN (VALUES ('psy_a'), ('plat')) AS a(who)
WHERE w.op IN ('insert', 'update status', 'delete');
REVOKE INSERT, UPDATE, DELETE ON public.patient_invitations FROM authenticated;

-- ---------------------------------------------------------------------------
-- C) RPCs que leem convites e o caminho do servidor
-- ---------------------------------------------------------------------------
SELECT pg_temp.eq('rpc alertas (psicóloga)', pg_temp.run_as('authenticated', pg_temp.uid('psy_a'),
  'SELECT public.get_psychologist_alerts()'), 'ok:1');
SELECT pg_temp.eq('rpc contagens (platform_admin)', pg_temp.run_as('authenticated', pg_temp.uid('plat'),
  format('SELECT 1 FROM public.get_patient_counts_by_psychologist() WHERE psychologist_id = %L AND pending_invites = 1',
    pg_temp.uid('psy_a'))), 'ok:1');

SELECT pg_temp.eq('service_role insert', pg_temp.run_as('service_role', NULL,
  pg_temp.invite_sql(11, 'psy_a', 'psy_a', 'psy_a')), 'ok:1');
SELECT pg_temp.eq('service_role update', pg_temp.run_as('service_role', NULL,
  'UPDATE public.patient_invitations SET status = ''revoked'' WHERE id = ' || pg_temp.inv(11)), 'ok:1');
SELECT pg_temp.eq('service_role delete', pg_temp.run_as('service_role', NULL,
  'DELETE FROM public.patient_invitations WHERE id = ' || pg_temp.inv(11)), 'ok:1');

-- ---------------------------------------------------------------------------
-- D) Gatilho: continua recusando o que não pode
-- ---------------------------------------------------------------------------
SELECT pg_temp.eq('insert recusado: ' || label, pg_temp.run_as('service_role', NULL, sql), 'P0001')
FROM (VALUES
  ('autor paciente', pg_temp.invite_sql(20, 'psy_a', 'pat', 'psy_a')),
  ('autor de outra clínica', pg_temp.invite_sql(21, 'psy_a', 'psy_b', 'psy_a')),
  ('responsável não psicóloga', pg_temp.invite_sql(22, 'plat', 'plat', 'plat')),
  ('responsável de outra clínica', pg_temp.invite_sql(23, 'psy_a', 'psy_a', 'psy_b')),
  ('pendente vencido', pg_temp.invite_sql(24, 'psy_a', 'psy_a', 'psy_a', 'pending', $e$now() - interval '1 minute'$e$))
) AS t(label, sql);

SELECT pg_temp.eq('insert platform_admin autor', pg_temp.run_as('service_role', NULL,
  pg_temp.invite_sql(25, 'plat', 'plat', 'psy_b')), 'ok:1');

SELECT pg_temp.eq('update recusado: ' || label, pg_temp.run_as('service_role', NULL,
  'UPDATE public.patient_invitations SET ' || assignment || ' WHERE id = ' || pg_temp.inv(1)), 'P0001')
FROM (VALUES
  ('responsável inválido', format('responsible_psychologist_id = %L', pg_temp.uid('pat'))),
  ('responsável de outra clínica', format('responsible_psychologist_id = %L', pg_temp.uid('psy_b'))),
  ('autor inválido', format('invited_by = %L', pg_temp.uid('pat'))),
  ('troca de clínica', format('clinic_id = %L', (SELECT clinic FROM _u WHERE k = 'psy_b'))),
  ('prazo passado em pendente', $a$expires_at = now() - interval '1 minute'$a$)
) AS t(label, assignment);

SELECT pg_temp.eq('normaliza e-mail e vazios', pg_temp.run_as('service_role', NULL,
  'UPDATE public.patient_invitations SET email = ''  MAIUSCULA@Esquemacore.Test '', full_name = ''  '', phone = '' 1 '' WHERE id = ' || pg_temp.inv(1)), 'ok:1');
SELECT pg_temp.eq('valores normalizados',
  (SELECT email || '|' || COALESCE(full_name, 'nulo') || '|' || phone FROM public.patient_invitations
    WHERE id = 'cc000000-0000-4000-8000-000000000001'), 'maiuscula@esquemacore.test|nulo|1');

-- ---------------------------------------------------------------------------
-- E) Papel/clínica mudou depois do convite
-- ---------------------------------------------------------------------------
-- 30 cancelar, 31 expirar (pendente vencido), 32 aceito para ligar ids,
-- 33 reservar, 34 aceito para devolver, 35 aceito ligado à ficha (SET NULL),
-- 36 pendente para virar aceito enquanto tudo é válido
SELECT pg_temp.eq('fixture ' || id, pg_temp.run_owner(pg_temp.invite_sql(id, 'psy_a', 'psy_a', 'psy_a', st)), 'ok:1')
FROM (VALUES (30, 'pending'), (31, 'pending'), (32, 'accepted'), (33, 'pending'),
             (34, 'accepted'), (35, 'accepted'), (36, 'pending')) AS t(id, st);
SELECT pg_temp.eq('fixture: ficha ligada', pg_temp.run_owner(
  'UPDATE public.patient_invitations SET patient_id = ''cc000000-0000-4000-8000-0000000000b1'' WHERE id = ' || pg_temp.inv(35)), 'ok:1');

SELECT pg_temp.eq('reserva com papéis válidos', pg_temp.run_as('service_role', NULL,
  'UPDATE public.patient_invitations SET status = ''accepted'', accepted_at = NULL WHERE id = ' || pg_temp.inv(36)), 'ok:1');
SELECT pg_temp.eq('aceito sem data ganha accepted_at',
  (SELECT (accepted_at IS NOT NULL)::text FROM public.patient_invitations
    WHERE id = 'cc000000-0000-4000-8000-000000000036'::uuid), 'true');
SELECT pg_temp.eq('devolver a pendente com papéis válidos', pg_temp.run_as('service_role', NULL,
  'UPDATE public.patient_invitations SET status = ''pending'', accepted_at = NULL WHERE id = ' || pg_temp.inv(36)), 'ok:1');

-- pendente vencido só é possível pelo passar do tempo
ALTER TABLE public.patient_invitations DISABLE TRIGGER trg_patient_invitations_validate;
UPDATE public.patient_invitations SET expires_at = now() - interval '1 day'
 WHERE id = 'cc000000-0000-4000-8000-000000000031';
ALTER TABLE public.patient_invitations ENABLE TRIGGER trg_patient_invitations_validate;

-- a psicóloga autora e responsável passa para outra clínica
SELECT pg_temp.eq('fixture: psicóloga muda de clínica', pg_temp.run_owner(format(
  'UPDATE public.profiles SET clinic_id = %L WHERE id = %L',
  (SELECT clinic FROM _u WHERE k = 'psy_b'), pg_temp.uid('psy_a'))), 'ok:1');

SELECT pg_temp.eq('depois da mudança: cancelar', pg_temp.run_as('service_role', NULL,
  'UPDATE public.patient_invitations SET status = ''revoked'' WHERE id = ' || pg_temp.inv(30)), 'ok:1');
SELECT pg_temp.eq('depois da mudança: expirar vencidos da clínica', pg_temp.run_as('service_role', NULL, format(
  'UPDATE public.patient_invitations SET status = ''expired'' WHERE clinic_id = %L AND status = ''pending'' AND expires_at <= now()',
  (SELECT clinic FROM _u WHERE k = 'pat'))), 'ok:1');
SELECT pg_temp.eq('depois da mudança: ligar ids do aceite', pg_temp.run_as('service_role', NULL, format(
  'UPDATE public.patient_invitations SET patient_profile_id = %L WHERE id = %s',
  pg_temp.uid('pat'), pg_temp.inv(32))), 'ok:1');
SELECT pg_temp.eq('depois da mudança: apagar ficha (ON DELETE SET NULL)', pg_temp.run_owner(
  'DELETE FROM public.patients WHERE id = ''cc000000-0000-4000-8000-0000000000b1'''), 'ok:1');
SELECT pg_temp.eq('ficha apagada soltou o convite',
  (SELECT (patient_id IS NULL)::text FROM public.patient_invitations
    WHERE id = 'cc000000-0000-4000-8000-000000000035'::uuid), 'true');

-- o que daria acesso continua recusado
SELECT pg_temp.eq('depois da mudança: ' || label, pg_temp.run_as('service_role', NULL,
  'UPDATE public.patient_invitations SET ' || assignment || ' WHERE id = ' || pg_temp.inv(id)), 'P0001')
FROM (VALUES
  ('reservar (aceitar) é recusado', 33, 'status = ''accepted'''),
  ('devolver a pendente é recusado', 34, 'status = ''pending'', accepted_at = NULL'),
  ('reabrir cancelado é recusado', 30, 'status = ''pending'''),
  ('aceitar cancelado é recusado', 30, 'status = ''accepted''')
) AS t(label, id, assignment);

-- ---------------------------------------------------------------------------
-- Resultado
-- ---------------------------------------------------------------------------
DO $$
DECLARE f record; v_total int; v_fail int;
BEGIN
  SELECT count(*), count(*) FILTER (WHERE NOT ok) INTO v_total, v_fail FROM pg_temp._r;
  FOR f IN SELECT label, got FROM pg_temp._r WHERE NOT ok ORDER BY n LOOP
    RAISE NOTICE 'FALHA: % (obtido: %)', f.label, f.got;
  END LOOP;
  IF v_fail > 0 THEN
    RAISE EXCEPTION 'convites só servidor: % de % verificações falharam', v_fail, v_total;
  END IF;
  RAISE NOTICE 'convites só servidor: % verificações ok', v_total;
END $$;

ROLLBACK;
