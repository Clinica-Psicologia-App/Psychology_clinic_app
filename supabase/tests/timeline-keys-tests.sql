-- Linha do Tempo: CHECK de emotional_need_keys e present_area_keys aceitam a união
-- dos vocabulários (paciente + psicóloga), continuam recusando chave inválida e
-- não mexem nas demais regras. Stack local de teste apenas; tudo em uma transação
-- que termina em ROLLBACK.
-- Rodar: docker exec -i supabase_db_App_Clinica_Psicologia psql -U postgres -v ON_ERROR_STOP=1 < supabase/tests/timeline-keys-tests.sql
BEGIN;

INSERT INTO public.clinics (id, name) VALUES ('ee000000-0000-4000-8000-000000000001', 'Clinica Timeline Teste');

INSERT INTO auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000000', 'ee000000-0000-4000-8000-0000000000a1', 'authenticated', 'authenticated',
  'tl-psi@esquemacore.test', crypt('TimelineTest2026!', gen_salt('bf')), timezone('utc', now()), '', '', '', '',
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, timezone('utc', now()), timezone('utc', now()))
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.profiles (id, clinic_id, full_name, email, role, is_active)
VALUES ('ee000000-0000-4000-8000-0000000000a1', 'ee000000-0000-4000-8000-000000000001', 'Psi Timeline',
  'tl-psi@esquemacore.test', 'psychologist', true)
ON CONFLICT (id) DO UPDATE SET clinic_id = EXCLUDED.clinic_id, role = EXCLUDED.role, is_active = true;

INSERT INTO public.patients (id, clinic_id, responsible_psychologist_id, full_name, is_active)
VALUES ('ee000000-0000-4000-8000-0000000000b1', 'ee000000-0000-4000-8000-000000000001',
  'ee000000-0000-4000-8000-0000000000a1', 'Paciente Timeline Ficticia', true);

CREATE TEMP TABLE _tl_counts (inserted int NOT NULL DEFAULT 0);
INSERT INTO _tl_counts VALUES (0);

-- Insere um evento com as listas dadas; devolve true se aceito, false se 23514
-- (e o nome da constraint em out_constraint).
CREATE FUNCTION pg_temp.try_event(p_needs text[], p_areas text[], p_need_other text DEFAULT NULL,
                                  OUT ok boolean, OUT out_constraint text)
LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO public.patient_timeline_events
    (clinic_id, patient_id, title, emotional_need_keys, present_area_keys, emotional_need_other)
  VALUES ('ee000000-0000-4000-8000-000000000001', 'ee000000-0000-4000-8000-0000000000b1',
    'Evento fictício', p_needs, p_areas, p_need_other);
  ok := true; out_constraint := NULL;
EXCEPTION WHEN check_violation THEN
  GET STACKED DIAGNOSTICS out_constraint = CONSTRAINT_NAME;
  ok := false;
END $$;

-- 1) as 6 chaves novas de necessidade e as 3 de área passam (separadas e misturadas)
DO $$
DECLARE k text; r record;
BEGIN
  FOREACH k IN ARRAY ARRAY['connection_acceptance','autonomy_competence_identity','limits_self_control',
      'expression_freedom','recognition_value','spontaneity_leisure'] LOOP
    SELECT * INTO r FROM pg_temp.try_event(ARRAY[k], '{}');
    IF NOT r.ok THEN RAISE EXCEPTION 'FALHA 1: necessidade % recusada (%)', k, r.out_constraint; END IF;
  END LOOP;
  FOREACH k IN ARRAY ARRAY['self_esteem','decisions','body'] LOOP
    SELECT * INTO r FROM pg_temp.try_event('{}', ARRAY[k]);
    IF NOT r.ok THEN RAISE EXCEPTION 'FALHA 1: área % recusada (%)', k, r.out_constraint; END IF;
  END LOOP;
  SELECT * INTO r FROM pg_temp.try_event(
    ARRAY['presence','connection_acceptance','spontaneity_leisure','other'],
    ARRAY['self_view','self_esteem','body','family'], 'Outra necessidade fictícia');
  IF NOT r.ok THEN RAISE EXCEPTION 'FALHA 1: lista mista recusada (%)', r.out_constraint; END IF;
END $$;

-- 2) regressão: o vocabulário antigo da paciente continua passando (todas as chaves)
DO $$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM pg_temp.try_event(
    ARRAY['presence','safety','affection','understanding','acceptance','expression','autonomy',
          'encouragement','limits','play','dont_know'],
    ARRAY['self_view','relationships','family','emotions','work','choices','coping']);
  IF NOT r.ok THEN RAISE EXCEPTION 'FALHA 2: vocabulário da paciente recusado (%)', r.out_constraint; END IF;
  SELECT * INTO r FROM pg_temp.try_event('{}', '{}');
  IF NOT r.ok THEN RAISE EXCEPTION 'FALHA 2: listas vazias recusadas'; END IF;
END $$;

-- 3) chave inexistente continua barrada, com o nome exato da constraint
DO $$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM pg_temp.try_event(ARRAY['zzz'], '{}');
  IF r.ok OR r.out_constraint IS DISTINCT FROM 'patient_timeline_events_emotional_need_keys_valid' THEN
    RAISE EXCEPTION 'FALHA 3a: chave inválida em necessidade: ok=%, constraint=%', r.ok, r.out_constraint;
  END IF;
  SELECT * INTO r FROM pg_temp.try_event('{}', ARRAY['zzz']);
  IF r.ok OR r.out_constraint IS DISTINCT FROM 'patient_timeline_events_present_area_keys_valid' THEN
    RAISE EXCEPTION 'FALHA 3b: chave inválida em área: ok=%, constraint=%', r.ok, r.out_constraint;
  END IF;
  -- uma chave inválida no meio de chaves válidas também é barrada
  SELECT * INTO r FROM pg_temp.try_event(ARRAY['presence','connection_acceptance','zzz'], '{}');
  IF r.ok THEN RAISE EXCEPTION 'FALHA 3c: lista com chave inválida foi aceita'; END IF;
END $$;

-- 4) 'other' sem texto continua barrado; com texto passa
DO $$
DECLARE r record;
BEGIN
  SELECT * INTO r FROM pg_temp.try_event(ARRAY['other'], '{}');
  IF r.ok OR r.out_constraint IS DISTINCT FROM 'patient_timeline_events_emotional_need_other_required' THEN
    RAISE EXCEPTION 'FALHA 4: other sem texto: ok=%, constraint=%', r.ok, r.out_constraint;
  END IF;
  SELECT * INTO r FROM pg_temp.try_event(ARRAY['other'], '{}', 'Texto fictício');
  IF NOT r.ok THEN RAISE EXCEPTION 'FALHA 4: other com texto recusado'; END IF;
END $$;

-- 5) as duas CHECK existem, estão validadas e as demais continuam no lugar
DO $$
DECLARE c text;
BEGIN
  FOREACH c IN ARRAY ARRAY['patient_timeline_events_emotional_need_keys_valid',
      'patient_timeline_events_present_area_keys_valid'] LOOP
    IF (SELECT count(*) FROM pg_constraint WHERE conrelid = 'public.patient_timeline_events'::regclass
        AND conname = c AND contype = 'c' AND convalidated) <> 1 THEN
      RAISE EXCEPTION 'FALHA 5: constraint % ausente ou não validada', c;
    END IF;
  END LOOP;
  FOREACH c IN ARRAY ARRAY['patient_timeline_events_belief_keys_valid','patient_timeline_events_emotion_keys_valid',
      'patient_timeline_events_category_keys_valid','patient_timeline_events_life_chapter_valid',
      'patient_timeline_events_recurrence_valid','patient_timeline_events_need_was_met_valid',
      'patient_timeline_events_still_influences_valid','patient_timeline_events_coping_other_required'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid = 'public.patient_timeline_events'::regclass AND conname = c) THEN
      RAISE EXCEPTION 'FALHA 5: constraint % sumiu', c;
    END IF;
  END LOOP;
END $$;

-- 6) RLS segue ligada, com policies, e nenhuma coluna foi criada/removida pela migration
DO $$
BEGIN
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.patient_timeline_events'::regclass) THEN
    RAISE EXCEPTION 'FALHA 6: RLS desligada em patient_timeline_events';
  END IF;
  IF (SELECT count(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'patient_timeline_events') = 0 THEN
    RAISE EXCEPTION 'FALHA 6: sem policies em patient_timeline_events';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public'
      AND table_name = 'patient_timeline_events' AND column_name = 'emotional_need_keys' AND data_type = 'ARRAY') THEN
    RAISE EXCEPTION 'FALHA 6: coluna emotional_need_keys mudou';
  END IF;
END $$;

DO $$ BEGIN RAISE NOTICE 'timeline-keys-tests: TODOS OK'; END $$;

ROLLBACK;
