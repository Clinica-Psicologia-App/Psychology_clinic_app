\set ON_ERROR_STOP on
BEGIN;
CREATE FUNCTION pg_temp.check_true(ok boolean, label text) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN
  IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
  RAISE NOTICE 'PASS: %',label;
END $$;
CREATE FUNCTION pg_temp.forge_review_via_definer() RETURNS void LANGUAGE sql SECURITY DEFINER AS $$
  UPDATE public.questionnaire_responses SET review_notes='FORGED' WHERE id='fa000000-0000-0000-0000-000000000701';
$$;
CREATE FUNCTION pg_temp.denied(statement text,label text) RETURNS void
LANGUAGE plpgsql AS $$ BEGIN
  BEGIN
    EXECUTE statement;
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE NOTICE 'PASS: %',label; RETURN;
  END;
  RAISE EXCEPTION 'FAIL: % (operation allowed)',label;
END $$;


CREATE FUNCTION pg_temp.stored_state() RETURNS jsonb LANGUAGE sql SECURITY DEFINER AS $$
 SELECT jsonb_build_object(
 'responses',(SELECT jsonb_agg(to_jsonb(r) ORDER BY id) FROM public.questionnaire_responses r),
 'answers',(SELECT jsonb_agg(to_jsonb(a) ORDER BY id) FROM public.questionnaire_answers a),
 'contexts',(SELECT jsonb_agg(to_jsonb(c) ORDER BY id) FROM public.questionnaire_response_contexts c),
 'activations',(SELECT jsonb_agg(to_jsonb(a) ORDER BY id) FROM public.questionnaire_schema_activations a),
 'patients',(SELECT jsonb_agg(to_jsonb(p) ORDER BY id) FROM public.patients p),
 'results',(SELECT jsonb_agg(to_jsonb(r) ORDER BY id) FROM public.questionnaire_results r));
$$;
CREATE FUNCTION pg_temp.unchanged(statement text,label text) RETURNS void LANGUAGE plpgsql AS $$
DECLARE before_state jsonb:=pg_temp.stored_state();
BEGIN
 BEGIN EXECUTE statement; EXCEPTION WHEN insufficient_privilege THEN NULL; END;
 PERFORM pg_temp.check_true(pg_temp.stored_state()=before_state,label||' persisted state unchanged');
END $$;

INSERT INTO public.clinics(id,name) VALUES ('fa000000-0000-0000-0000-000000000001','Lote F other clinic');
INSERT INTO auth.users(id,email,raw_user_meta_data)
SELECT ('fa000000-0000-0000-0000-00000000010'||n)::uuid,'lote-f-'||n||'@test.invalid','{}'::jsonb
FROM generate_series(1,6) n;
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
SELECT id,'11111111-1111-1111-1111-111111111101','Lote F identity',email,'patient',true
FROM auth.users WHERE email LIKE 'lote-f-%@test.invalid';
UPDATE public.profiles SET role='psychologist',clinic_id='11111111-1111-1111-1111-111111111101',is_active=true
WHERE id IN ('fa000000-0000-0000-0000-000000000101','fa000000-0000-0000-0000-000000000102');
UPDATE public.profiles SET is_active=false WHERE id='fa000000-0000-0000-0000-000000000102';
UPDATE public.profiles SET role='psychologist',clinic_id='fa000000-0000-0000-0000-000000000001',is_active=true WHERE id='fa000000-0000-0000-0000-000000000103';
UPDATE public.profiles SET role='patient',clinic_id='fa000000-0000-0000-0000-000000000001',is_active=true WHERE id='fa000000-0000-0000-0000-000000000104';
UPDATE public.profiles SET role='patient',clinic_id='11111111-1111-1111-1111-111111111101',is_active=false WHERE id='fa000000-0000-0000-0000-000000000105';
DELETE FROM public.profiles WHERE id='fa000000-0000-0000-0000-000000000106';
INSERT INTO public.patients(id,clinic_id,profile_id,full_name,responsible_psychologist_id)
VALUES ('fa000000-0000-0000-0000-000000000201','fa000000-0000-0000-0000-000000000001',
  'fa000000-0000-0000-0000-000000000104','Other clinic patient','fa000000-0000-0000-0000-000000000103');
INSERT INTO public.questionnaire_schema_activations(questionnaire_response_id,schema_code,schema_name,psi_observation,activated_by_profile_id,clinic_id)
VALUES ('11111111-1111-1111-1111-111111111701','LOTE_F','Shared activation','PRIVATE_PSI_OBSERVATION_LOTE_F','11111111-1111-1111-1111-111111111103','11111111-1111-1111-1111-111111111101');
UPDATE public.patients SET results_released_at=NULL WHERE id='11111111-1111-1111-1111-111111111201';
UPDATE public.questionnaire_responses SET reviewed_at=now(),review_notes='PRIVATE_REVIEW' WHERE id='11111111-1111-1111-1111-111111111701';
UPDATE public.questionnaire_answers SET professional_note='PRIVATE_ANSWER',professional_value=999 WHERE response_id='11111111-1111-1111-1111-111111111701';
UPDATE public.questionnaire_results SET professional_note='PRIVATE_RESULT',snapshot='{"version":"scoring-demo-1","psi_observation":"PRIVATE_ROOT","summary":{"average_score":4,"professional_note":"PRIVATE_SUMMARY"},"schemas":[{"id":"s","code":"s","name":"Schema","average_score":4,"professional_value":999,"extra":{"private":true}}],"contexts":[{"id":"c","label":"Parent","professional_note":"PRIVATE_CONTEXT","schemas":[{"name":"S","professional_note":"PRIVATE_NESTED"}]}]}'
WHERE response_id='11111111-1111-1111-1111-111111111701';
INSERT INTO public.questionnaire_responses(id,clinic_id,patient_id,questionnaire_id,questionnaire_version_id,status,started_at)
SELECT 'fa000000-0000-0000-0000-000000000701',clinic_id,patient_id,questionnaire_id,questionnaire_version_id,'draft',now()
FROM public.questionnaire_responses WHERE id='11111111-1111-1111-1111-111111111701';


-- Dedicated sentinel target is present and owned by the authenticated patient.
INSERT INTO public.questionnaire_answers(id,response_id,question_id,answer_value)
VALUES ('fa000000-0000-0000-0000-000000000802','fa000000-0000-0000-0000-000000000701','11111111-1111-1111-1111-111111111502',3);
SELECT pg_temp.check_true((SELECT r.patient_id=p.id AND p.profile_id='11111111-1111-1111-1111-111111111104'
 FROM public.questionnaire_responses r JOIN public.patients p ON p.id=r.patient_id WHERE r.id='fa000000-0000-0000-0000-000000000701'),'fixture response exists and patient owns it');
SELECT pg_temp.check_true((SELECT a.psi_observation='PRIVATE_PSI_OBSERVATION_LOTE_F' AND r.patient_id='11111111-1111-1111-1111-111111111201'
 FROM public.questionnaire_schema_activations a JOIN public.questionnaire_responses r ON r.id=a.questionnaire_response_id WHERE a.schema_code='LOTE_F'),'fixture activation private sentinel exists for own response');
SELECT pg_temp.check_true((SELECT professional_note IS NULL AND response_id='fa000000-0000-0000-0000-000000000701'
 FROM public.questionnaire_answers WHERE id='fa000000-0000-0000-0000-000000000802'),'fixture answer exists before forgery');
INSERT INTO public.questionnaire_response_contexts(id,clinic_id,response_id,patient_id,questionnaire_id,context_type,context_key,context_label,status,completed_at)
SELECT 'fa000000-0000-0000-0000-000000000901',clinic_id,id,patient_id,questionnaire_id,'parental_figure','mother','SQL guard fixture','completed','2026-01-01T00:00:00Z'
FROM public.questionnaire_responses WHERE id='11111111-1111-1111-1111-111111111701';
SELECT pg_temp.check_true((SELECT status='completed' AND completed_at='2026-01-01T00:00:00Z' AND patient_id='11111111-1111-1111-1111-111111111201'
 FROM public.questionnaire_response_contexts WHERE id='fa000000-0000-0000-0000-000000000901'),'fixture completed context exists and is owned');
-- FIXTURES_READY

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111104","role":"authenticated"}',true);
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM public.questionnaire_schema_activations WHERE psi_observation='PRIVATE_PSI_OBSERVATION_LOTE_F'),'F05 private sentinel not exposed');
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_response_contexts SET completed_at='2099-01-01T00:00:00Z' WHERE id='fa000000-0000-0000-0000-000000000901'$q$,'F07 context timestamp');
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_response_contexts SET completed_at=NULL WHERE id='fa000000-0000-0000-0000-000000000901'$q$,'F07 context null timestamp');
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_answers SET professional_note='PATIENT_FORGED_LOTE_F' WHERE id='fa000000-0000-0000-0000-000000000802'$q$,'F07 sentinel');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_schema_activations),'F05 raw activation denied');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_results),'F08 raw results denied');
SELECT pg_temp.unchanged($q$INSERT INTO public.questionnaire_results(response_id,questionnaire_id,category_id,total_score)
  VALUES('11111111-1111-1111-1111-111111111701','11111111-1111-1111-1111-111111111301','11111111-1111-1111-1111-111111111401',999)$q$,'F07 patient cannot insert computed result');
WITH changed AS (UPDATE public.questionnaire_results SET total_score=999 WHERE response_id='11111111-1111-1111-1111-111111111701' RETURNING id)
SELECT pg_temp.check_true((SELECT count(*)=0 FROM changed),'F07 patient cannot update computed result');
SELECT pg_temp.unchanged($q$UPDATE public.patients SET results_released_at=now() WHERE id='11111111-1111-1111-1111-111111111201'$q$,'F08 patient cannot release results');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.get_patient_schema_activations('11111111-1111-1111-1111-111111111701')),'F08 reviewed is not released');
SELECT pg_temp.check_true(jsonb_array_length(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701')->'questionnaire_results')=0,'F08 detail before release');
SELECT pg_temp.denied('SELECT review_notes FROM public.questionnaire_responses','F05 raw review notes');
SELECT pg_temp.denied('SELECT professional_note,professional_value FROM public.questionnaire_answers','F05 raw professional answers');
SELECT pg_temp.denied('SELECT * FROM public.questionnaire_responses','F05 response wildcard');
SELECT pg_temp.denied('SELECT * FROM public.questionnaire_answers','F05 answer wildcard');
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_responses SET status='draft',completed_at=NULL WHERE id='11111111-1111-1111-1111-111111111701'$q$,'F07 cannot reopen');
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_responses SET review_notes='FORGED',reviewed_at=now() WHERE id='fa000000-0000-0000-0000-000000000701'$q$,'F07 cannot forge review');
SELECT pg_temp.unchanged('SELECT pg_temp.forge_review_via_definer()','F07 SECURITY DEFINER does not bypass patient guard');
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111104","role":"service_role","app_metadata":{"role":"psychologist"}}',true);
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_responses SET review_notes='FORGED' WHERE id='fa000000-0000-0000-0000-000000000701'$q$,'F07 JWT claims do not select trusted database role');
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111104","role":"authenticated"}',true);
SELECT pg_temp.unchanged($q$INSERT INTO public.questionnaire_answers(response_id,question_id,answer_value,professional_note) VALUES('fa000000-0000-0000-0000-000000000701','11111111-1111-1111-1111-111111111501',3,'FORGED')$q$,'F07 cannot insert professional note');
INSERT INTO public.questionnaire_answers(id,response_id,question_id,answer_value)
VALUES('fa000000-0000-0000-0000-000000000801','fa000000-0000-0000-0000-000000000701','11111111-1111-1111-1111-111111111501',3);
UPDATE public.questionnaire_answers SET answer_value=4 WHERE id='fa000000-0000-0000-0000-000000000801';
SELECT pg_temp.check_true((SELECT answer_value=4 FROM public.questionnaire_answers WHERE id='fa000000-0000-0000-0000-000000000801'),'F07 save and edit draft');
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_answers SET professional_note='FORGED',professional_value=99 WHERE id='fa000000-0000-0000-0000-000000000801'$q$,'F07 cannot update professional fields');
UPDATE public.questionnaire_responses SET status='completed',completed_at=now() WHERE id='fa000000-0000-0000-0000-000000000701';
SELECT pg_temp.check_true((SELECT status='completed' FROM public.questionnaire_responses WHERE id='fa000000-0000-0000-0000-000000000701'),'F07 official forward transition');

RESET ROLE;
UPDATE public.patients SET results_released_at=now() WHERE id='11111111-1111-1111-1111-111111111201';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111104","role":"authenticated"}',true);
SELECT pg_temp.check_true((SELECT count(*)=1 FROM public.get_patient_schema_activations('11111111-1111-1111-1111-111111111701')),'F08 released activation');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_schema_activations),'F05 private activation denied even released');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_results),'F08 raw snapshot denied even released');
SELECT pg_temp.check_true(jsonb_array_length(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701')->'questionnaire_results')>0,'F08 released result projection');
SELECT pg_temp.check_true(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701')::text !~ 'PRIVATE|professional_|psi_observation|review_notes|"snapshot"|"extra"','F05 recursive allowlist excludes private fields');
SELECT pg_temp.unchanged($q$UPDATE public.questionnaire_answers SET answer_value=1 WHERE id='fa000000-0000-0000-0000-000000000801'$q$,'F07 completed answer immutable after release');

-- Every unauthorized identity probes raw clinical rows and both SD read paths.
DO $$ DECLARE actor text; changed integer; BEGIN
  FOREACH actor IN ARRAY ARRAY['fa000000-0000-0000-0000-000000000101','fa000000-0000-0000-0000-000000000102',
    'fa000000-0000-0000-0000-000000000103','fa000000-0000-0000-0000-000000000104',
    'fa000000-0000-0000-0000-000000000105','fa000000-0000-0000-0000-000000000106',
    '11111111-1111-1111-1111-111111111102'] LOOP
    PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role','authenticated')::text,true);
    PERFORM pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_schema_activations),'N01 identity '||actor);
    PERFORM pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_results),'F08 identity '||actor);
    PERFORM pg_temp.check_true(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701') IS NULL,'detail identity '||actor);
    PERFORM pg_temp.check_true((SELECT count(*)=0 FROM public.get_patient_schema_activations('11111111-1111-1111-1111-111111111701')),'activation identity '||actor);
    UPDATE public.questionnaire_schema_activations SET psi_observation='FORGED' WHERE schema_code='LOTE_F';
    GET DIAGNOSTICS changed=ROW_COUNT;
    PERFORM pg_temp.check_true(changed=0,'activation UPDATE identity '||actor);
    UPDATE public.questionnaire_responses SET review_notes='FORGED' WHERE id='11111111-1111-1111-1111-111111111701';
    GET DIAGNOSTICS changed=ROW_COUNT;
    PERFORM pg_temp.check_true(changed=0,'response UPDATE identity '||actor);
    PERFORM pg_temp.unchanged($q$INSERT INTO public.questionnaire_schema_activations(questionnaire_response_id,schema_code,schema_name,clinic_id,activated_by_profile_id)
      VALUES('11111111-1111-1111-1111-111111111701','FORGED','FORGED','11111111-1111-1111-1111-111111111101','11111111-1111-1111-1111-111111111103')$q$,'activation INSERT identity '||actor);
  END LOOP;
END $$;
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111103","role":"authenticated"}',true);
SELECT pg_temp.check_true((SELECT psi_observation='PRIVATE_PSI_OBSERVATION_LOTE_F' FROM public.questionnaire_schema_activations WHERE schema_code='LOTE_F'),'N01 responsible professional read');
SELECT pg_temp.check_true(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701')->>'review_notes'='PRIVATE_REVIEW','F07 professional detail preserved');
UPDATE public.questionnaire_responses SET review_notes='Reviewed' WHERE id='11111111-1111-1111-1111-111111111701';
UPDATE public.questionnaire_answers SET professional_note='Reviewed',professional_value=4 WHERE response_id='11111111-1111-1111-1111-111111111701';
SELECT pg_temp.check_true(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701')->>'review_notes'='Reviewed','F07 responsible review preserved');
RESET ROLE;
UPDATE public.profiles SET is_active=false WHERE id='11111111-1111-1111-1111-111111111103';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111103","role":"authenticated"}',true);
SELECT pg_temp.check_true(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701') IS NULL,'inactive responsible psychologist detail denied');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_schema_activations),'inactive responsible psychologist activation denied');
RESET ROLE;
UPDATE public.profiles SET is_active=true WHERE id='11111111-1111-1111-1111-111111111103';
UPDATE public.profiles SET is_active=false WHERE id='11111111-1111-1111-1111-111111111104';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claims','{"sub":"11111111-1111-1111-1111-111111111104","role":"authenticated"}',true);
SELECT pg_temp.check_true(public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701') IS NULL,'own inactive patient detail denied');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_answers),'own inactive patient raw answers denied');
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.get_patient_schema_activations('11111111-1111-1111-1111-111111111701')),'own inactive patient activations denied');
RESET ROLE;
SET LOCAL ROLE anon;
SELECT set_config('request.jwt.claims','{"role":"anon"}',true);
SELECT pg_temp.check_true((SELECT count(*)=0 FROM public.questionnaire_schema_activations),'anon activation denied');
SELECT pg_temp.denied($q$SELECT public.get_questionnaire_response_detail('11111111-1111-1111-1111-111111111701')$q$,'anon detail execute denied');
RESET ROLE;
ROLLBACK;
