-- S2: grants e search_path das funções de public (M1, M2, B2, B3) e fluxos que dependem delas.
-- Local, fixtures fictícias, rollback ao final. Execute com psql -X -v ON_ERROR_STOP=1 como supabase_admin.
BEGIN;
SET LOCAL statement_timeout='60s';
CREATE FUNCTION pg_temp.check_true(ok boolean,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF;
 RAISE NOTICE 'PASS: %',label;
END;
$$;

-- Itens PENDENTES (gates que a migration nao consegue fechar sozinha) ficam visiveis: WARNING 'PENDENTE' e
-- resumo final. Para tratar PENDENTE como falha: PGOPTIONS="-c s2.strict=on" psql ... < este arquivo.
CREATE TEMP TABLE s2_pending(label text);

-- ---------- Estado dos grants (todas as funções de public, exceto membros de extensão) ----------
CREATE TEMP VIEW pg_temp.pub_funcs AS
SELECT p.oid, p.oid::regprocedure AS sig, p.proname, p.prorettype, p.proconfig, p.proacl, p.proowner
FROM pg_catalog.pg_proc p
WHERE p.pronamespace='public'::regnamespace AND p.prokind IN ('f','p')
  AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_depend d WHERE d.classid='pg_catalog.pg_proc'::regclass AND d.objid=p.oid AND d.objsubid=0 AND d.deptype='e');

SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE has_function_privilege('anon',f.oid,'EXECUTE')),
 'M1 nenhuma função de public executável por anon: '||coalesce((SELECT string_agg(sig::text,', ') FROM (SELECT sig FROM pg_temp.pub_funcs f WHERE has_function_privilege('anon',f.oid,'EXECUTE') LIMIT 3) s),'ok'));
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE f.proacl IS NULL
   OR EXISTS(SELECT 1 FROM aclexplode(f.proacl) a WHERE a.grantee=0 AND a.privilege_type='EXECUTE')),
 'M1 nenhuma função de public com EXECUTE para PUBLIC');
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE f.prorettype IN ('trigger'::regtype,'event_trigger'::regtype)
   AND has_function_privilege('authenticated',f.oid,'EXECUTE')),
 'B2 funções de gatilho sem EXECUTE para authenticated');
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE f.proname='assert_platform_admin'
   AND (has_function_privilege('authenticated',f.oid,'EXECUTE') OR has_function_privilege('anon',f.oid,'EXECUTE'))),
 'B2 assert_platform_admin sem EXECUTE para authenticated/anon');
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE f.proname='rls_auto_enable'
   AND (has_function_privilege('authenticated',f.oid,'EXECUTE') OR has_function_privilege('anon',f.oid,'EXECUTE'))),
 'M2 rls_auto_enable (se existir) sem EXECUTE para authenticated/anon');
SELECT pg_temp.check_true(NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f
   WHERE NOT EXISTS(SELECT 1 FROM unnest(coalesce(f.proconfig,'{}'::text[])) c WHERE c LIKE 'search_path=%')),
 'B3 toda função de public com search_path fixo: '||coalesce((SELECT string_agg(sig::text,', ') FROM (SELECT sig FROM pg_temp.pub_funcs f WHERE NOT EXISTS(SELECT 1 FROM unnest(coalesce(f.proconfig,'{}'::text[])) c WHERE c LIKE 'search_path=%') LIMIT 3) s),'ok'));
SELECT pg_temp.check_true((SELECT count(*) FROM pg_temp.pub_funcs f WHERE f.proname IN (
 'patient_problems_set_resolved_at','personality_results_public','set_updated_at','sync_questionnaire_response_context_completion',
 'therapy_goals_set_completed_at','touch_healthy_resources','touch_profile_avatar_updated_at','validate_case_conceptualization_clinic',
 'validate_daily_monitor_clinic','validate_genogram_family_patterns_clinic','validate_genogram_person_clinic',
 'validate_genogram_relationship_consistency','validate_patient_check_in_clinic','validate_patient_clinic_refs',
 'validate_patient_invitation','validate_patient_problem_clinic','validate_patient_resource_access_clinic',
 'validate_patient_timeline_event_clinic','validate_personality_assessment_clinic','validate_question_category_item_questionnaire',
 'validate_question_scoring_rule_refs','validate_questionnaire_answer_context','validate_questionnaire_answer_questionnaire',
 'validate_questionnaire_professional_access','validate_questionnaire_response_clinic','validate_questionnaire_response_context',
 'validate_questionnaire_result_refs','validate_therapy_goal_clinic','validate_timeline_event_person_consistency')
 AND 'search_path=public'=ANY(f.proconfig))=29,'B3 as 29 funções do advisor com search_path=public');

-- ---------- O que NÃO pode ter se perdido: helpers de RLS e RPCs do app seguem com authenticated ----------
DO $$
DECLARE n text;
BEGIN
 FOREACH n IN ARRAY ARRAY['current_clinic_id','current_role','current_patient_id','is_staff','is_library_cover_admin',
  'user_can_access_patient','user_can_access_response','scoring_admin_can_manage_row','scoring_row_visible_to_current_clinic',
  'personality_results_public','admin_duplicate_questionnaire_as_draft','admin_get_questionnaire','admin_list_questionnaires',
  'admin_save_question','admin_save_questionnaire_draft','delete_genogram_person','get_current_clinic_entitlements','get_my_library',
  'get_patient_counts_by_psychologist','get_patient_schema_activations','get_patients_data_completion','get_psychoeducation_journey',
  'get_psychologist_alerts','indicate_library_work','delete_patient_as_admin','get_patient_infographic_timeline','get_patient_vitals',
  'get_patients_with_pending_results_release','get_questionnaire_response_detail','list_questionnaire_response_summaries',
  'set_patient_active_status','set_patient_results_released',
  -- as 6 RPCs admin chamadas via _call() em questionnaire_catalog_admin_repository.dart:87-108
  'admin_delete_question','admin_publish_questionnaire','admin_archive_questionnaire','admin_delete_questionnaire_draft',
  'admin_create_draft_version','admin_discard_draft_version'] LOOP
  PERFORM pg_temp.check_true(EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE f.proname=n)
   AND NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE f.proname=n AND NOT has_function_privilege('authenticated',f.oid,'EXECUTE')),
   'mantém authenticated: '||n);
  -- service_role fechado de propósito em get_psychoeducation_journey (20260914150000) e delete_patient_as_admin: não é da S2.
  PERFORM pg_temp.check_true(n IN ('get_psychoeducation_journey','delete_patient_as_admin') OR NOT EXISTS(SELECT 1 FROM pg_temp.pub_funcs f WHERE f.proname=n AND NOT has_function_privilege('service_role',f.oid,'EXECUTE')),
   'mantém service_role: '||n);
 END LOOP;
END;
$$;

-- ---------- Funções futuras: default privileges ----------
-- postgres é o papel das migrations (obrigatório). supabase_admin (painel/CLI) só pode ser ajustado por
-- esse próprio papel: se sobrar anon/PUBLIC ali, fica PENDENTE (WARNING + resumo final; FAIL em modo strict).
DO $$
DECLARE owner_name text; ok_anon boolean; ok_public boolean; ok_clients boolean; pend text;
BEGIN
 FOREACH owner_name IN ARRAY ARRAY['postgres','supabase_admin'] LOOP
  pend:=NULL;
  BEGIN
   EXECUTE format('SET LOCAL ROLE %I',owner_name);
   CREATE FUNCTION public.s2_probe() RETURNS integer LANGUAGE sql AS 'SELECT 1';
   RESET ROLE;
   ok_anon:=NOT has_function_privilege('anon','public.s2_probe()','EXECUTE');
   ok_public:=NOT EXISTS(SELECT 1 FROM pg_proc p, aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a
     WHERE p.oid='public.s2_probe()'::regprocedure AND a.grantee=0 AND a.privilege_type='EXECUTE');
   ok_clients:=has_function_privilege('authenticated','public.s2_probe()','EXECUTE')
     AND has_function_privilege('service_role','public.s2_probe()','EXECUTE');
   IF owner_name='postgres' THEN
    PERFORM pg_temp.check_true(ok_anon AND ok_public AND ok_clients,
     'M1 função nova criada por postgres: sem anon e sem PUBLIC, com authenticated e service_role');
   ELSIF ok_anon AND ok_public AND ok_clients THEN
    PERFORM pg_temp.check_true(true,'M1 função nova criada por supabase_admin: sem anon e sem PUBLIC, com authenticated e service_role');
   ELSE
    pend:=format('função nova criada por supabase_admin: anon=%s PUBLIC=%s (defaults de supabase_admin não aplicados)',NOT ok_anon,NOT ok_public);
   END IF;
   RAISE EXCEPTION USING ERRCODE='ZB002';
  EXCEPTION WHEN SQLSTATE 'ZB002' THEN RESET ROLE;
  END;
  IF pend IS NOT NULL THEN
   IF coalesce(current_setting('s2.strict',true),'off')='on' THEN RAISE EXCEPTION 'FAIL: %',pend; END IF;
   INSERT INTO s2_pending VALUES (pend);
   RAISE WARNING 'PENDENTE: %',pend;
  END IF;
 END LOOP;
END;
$$;

-- CREATE EXTENSION feito por postgres: a função da extensão nasce com dono supabase_admin (script de extensão),
-- então vale o default de supabase_admin (gate PENDENTE acima), NÃO o ALTER DEFAULT PRIVILEGES de postgres.
-- O laço M1 também ignora membros de extensão. Conferir os grants sempre que habilitar uma extensão.
DO $$
DECLARE n_total int; n_anon int; n_public int; owner_name text; err text:=NULL; pend text:=NULL;
BEGIN
 BEGIN
  SET LOCAL ROLE postgres;
  CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;
  RESET ROLE;
  SELECT count(*), count(*) FILTER (WHERE has_function_privilege('anon',p.oid,'EXECUTE')),
         count(*) FILTER (WHERE EXISTS(SELECT 1 FROM aclexplode(coalesce(p.proacl,acldefault('f',p.proowner))) a WHERE a.grantee=0 AND a.privilege_type='EXECUTE')),
         min(pg_get_userbyid(p.proowner))
    INTO n_total,n_anon,n_public,owner_name
  FROM pg_proc p JOIN pg_depend d ON d.classid='pg_catalog.pg_proc'::regclass AND d.objid=p.oid AND d.objsubid=0 AND d.deptype='e'
  JOIN pg_extension e ON e.oid=d.refobjid AND d.refclassid='pg_catalog.pg_extension'::regclass AND e.extname='citext';
  PERFORM pg_temp.check_true(n_total>0,'CREATE EXTENSION citext por postgres criou funções (dono='||owner_name||', total='||n_total||')');
  IF n_anon=0 AND n_public=0 THEN
   PERFORM pg_temp.check_true(true,'extensão em public: nenhuma função executável por anon/PUBLIC');
  ELSE
   pend:=format('extensão em public: %s de %s funções executáveis por anon e %s por PUBLIC (dono %s; mesmo gate dos defaults de supabase_admin)',n_anon,n_total,n_public,owner_name);
  END IF;
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN RESET ROLE;
          WHEN insufficient_privilege OR feature_not_supported OR undefined_file THEN RESET ROLE; err:=SQLERRM;
 END;
 IF err IS NOT NULL THEN pend:='CREATE EXTENSION não testável neste ambiente: '||err; END IF;
 IF pend IS NOT NULL THEN
  IF coalesce(current_setting('s2.strict',true),'off')='on' THEN RAISE EXCEPTION 'FAIL: %',pend; END IF;
  INSERT INTO s2_pending VALUES (pend);
  RAISE WARNING 'PENDENTE: %',pend;
 END IF;
END;
$$;

-- ---------- Comportamento: policies, gatilhos e RPCs continuam funcionando ----------
INSERT INTO public.clinics(id,name) VALUES ('e6100000-0000-0000-0000-000000000001','S2 A'),('e6100000-0000-0000-0000-000000000002','S2 B');
INSERT INTO auth.users(id,email) SELECT ('e6200000-0000-0000-0000-'||lpad(n::text,12,'0'))::uuid,'s2-'||n||'@example.test' FROM generate_series(1,4) n;
-- 1 platform_admin (A); 2 psicólogo A; 3 psicólogo B; 4 paciente A
INSERT INTO public.profiles(id,clinic_id,full_name,email,role,is_active)
SELECT id, CASE right(id::text,2) WHEN '03' THEN 'e6100000-0000-0000-0000-000000000002'::uuid ELSE 'e6100000-0000-0000-0000-000000000001'::uuid END,
 'S2 fixture',email,
 CASE right(id::text,2) WHEN '01' THEN 'platform_admin' WHEN '02' THEN 'psychologist' WHEN '03' THEN 'psychologist' ELSE 'patient' END::public.profile_role,true
FROM auth.users WHERE id::text LIKE 'e6200000-%';
INSERT INTO public.patients(id,clinic_id,profile_id,responsible_psychologist_id,full_name,birth_date)
VALUES ('e6300000-0000-0000-0000-000000000001','e6100000-0000-0000-0000-000000000001','e6200000-0000-0000-0000-000000000004','e6200000-0000-0000-0000-000000000002','S2 paciente','1990-01-01');

CREATE FUNCTION pg_temp.run_case(label text,actor uuid,dbrole text,statement text,deny boolean DEFAULT false)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE result text; denied boolean:=false;
BEGIN
 BEGIN
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role',dbrole)::text,true);
  EXECUTE format('SET LOCAL ROLE %I',dbrole);
  IF deny THEN
   BEGIN
    EXECUTE statement;
   EXCEPTION WHEN insufficient_privilege THEN denied:=true;
   END;
   RESET ROLE;
   PERFORM pg_temp.check_true(denied,'DENY (42501) '||label);
  ELSE
   EXECUTE statement INTO result;
   RESET ROLE;
   PERFORM pg_temp.check_true(result::boolean,label);
  END IF;
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN RESET ROLE;
 END;
END;
$$;

-- Executa setup e verificação sob o mesmo papel/claims; a verificação roda como dono (vê audit_events etc.).
CREATE FUNCTION pg_temp.run_steps(label text,actor uuid,dbrole text,setup text,check_sql text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE result text;
BEGIN
 BEGIN
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role',dbrole)::text,true);
  EXECUTE format('SET LOCAL ROLE %I',dbrole);
  EXECUTE setup;
  RESET ROLE;
  EXECUTE check_sql INTO result;
  PERFORM pg_temp.check_true(result::boolean,label);
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN RESET ROLE;
 END;
END;
$$;
-- Espera erro DE NEGÓCIO (o gatilho executou); permission denied (42501) conta como falha.
CREATE FUNCTION pg_temp.run_error(label text,actor uuid,dbrole text,statement text,msg_like text)
RETURNS void LANGUAGE plpgsql AS $$
DECLARE msg text; st text;
BEGIN
 BEGIN
  PERFORM set_config('request.jwt.claim.sub','',true);
  PERFORM set_config('request.jwt.claims',jsonb_build_object('sub',actor,'role',dbrole)::text,true);
  EXECUTE format('SET LOCAL ROLE %I',dbrole);
  BEGIN
   EXECUTE statement;
   msg:=NULL;
  EXCEPTION WHEN OTHERS THEN GET STACKED DIAGNOSTICS msg=MESSAGE_TEXT; st:=SQLSTATE;
  END;
  RESET ROLE;
  PERFORM pg_temp.check_true(msg IS NOT NULL AND st<>'42501' AND msg LIKE msg_like,label||' (erro: '||coalesce(msg,'nenhum')||')');
  RAISE EXCEPTION USING ERRCODE='ZB002';
 EXCEPTION WHEN SQLSTATE 'ZB002' THEN RESET ROLE;
 END;
END;
$$;

-- Policies RLS que chamam helpers (current_clinic_id, user_can_access_patient...) com authenticated.
SELECT pg_temp.run_case('RLS: psicólogo A vê o próprio paciente','e6200000-0000-0000-0000-000000000002','authenticated',
 $s$SELECT count(*)=1 FROM public.patients WHERE id='e6300000-0000-0000-0000-000000000001'$s$);
SELECT pg_temp.run_case('RLS: psicólogo B não vê paciente de A','e6200000-0000-0000-0000-000000000003','authenticated',
 $s$SELECT count(*)=0 FROM public.patients WHERE id='e6300000-0000-0000-0000-000000000001'$s$);
SELECT pg_temp.run_case('RLS: paciente vê o próprio registro','e6200000-0000-0000-0000-000000000004','authenticated',
 $s$SELECT count(*)=1 FROM public.patients WHERE id='e6300000-0000-0000-0000-000000000001'$s$);
-- Gatilhos disparam para authenticated sem EXECUTE: um caso por gatilho de therapy_goals.
SELECT pg_temp.run_case('gatilho therapy_goals_set_completed_at: meta concluída recebe completed_at','e6200000-0000-0000-0000-000000000002','authenticated',
 $s$WITH i AS (INSERT INTO public.therapy_goals(clinic_id,patient_id,title,status,created_by) VALUES ('e6100000-0000-0000-0000-000000000001','e6300000-0000-0000-0000-000000000001','S2 meta','completed','e6200000-0000-0000-0000-000000000002') RETURNING completed_at)
  SELECT count(*)=1 AND bool_and(completed_at IS NOT NULL) FROM i$s$);
SELECT pg_temp.run_steps('gatilho set_updated_at: UPDATE com updated_at antigo é sobrescrito','e6200000-0000-0000-0000-000000000002','authenticated',
 $s$INSERT INTO public.therapy_goals(clinic_id,patient_id,title,created_by) VALUES ('e6100000-0000-0000-0000-000000000001','e6300000-0000-0000-0000-000000000001','S2 meta U','e6200000-0000-0000-0000-000000000002');
    UPDATE public.therapy_goals SET title='S2 meta U2', updated_at='2000-01-01' WHERE title='S2 meta U'$s$,
 $s$SELECT updated_at > '2001-01-01' FROM public.therapy_goals WHERE title='S2 meta U2'$s$);
SELECT pg_temp.run_error('gatilho validate_therapy_goal_clinic: meta com clínica diferente do paciente é recusada','e6200000-0000-0000-0000-000000000002','authenticated',
 $s$INSERT INTO public.therapy_goals(clinic_id,patient_id,title,created_by) VALUES ('e6100000-0000-0000-0000-000000000002','e6300000-0000-0000-0000-000000000001','S2 meta X','e6200000-0000-0000-0000-000000000002')$s$,
 '%patient_id deve pertencer%');
SELECT pg_temp.run_steps('gatilho audit_sensitive_change: inserir meta grava audit_events','e6200000-0000-0000-0000-000000000002','authenticated',
 $s$INSERT INTO public.therapy_goals(clinic_id,patient_id,title,created_by) VALUES ('e6100000-0000-0000-0000-000000000001','e6300000-0000-0000-0000-000000000001','S2 meta A','e6200000-0000-0000-0000-000000000002')$s$,
 $s$SELECT count(*)=1 FROM public.therapy_goals g JOIN public.audit_events a ON a.entity_id=g.id
    WHERE g.title='S2 meta A' AND g.patient_id='e6300000-0000-0000-0000-000000000001'
      AND a.entity_type='therapy_goals' AND a.action='insert'
      AND a.actor_profile_id='e6200000-0000-0000-0000-000000000002'
      AND a.patient_id=g.patient_id AND a.clinic_id=g.clinic_id$s$);
SELECT pg_temp.run_case('RPC SECURITY DEFINER lê via helper: get_patient_vitals','e6200000-0000-0000-0000-000000000002','authenticated',
 $s$SELECT (public.get_patient_vitals('e6300000-0000-0000-0000-000000000001')->>'access')::boolean$s$);
SELECT pg_temp.run_case('admin RPC chama assert_platform_admin por dentro (dono executa)','e6200000-0000-0000-0000-000000000001','authenticated',
 $s$SELECT count(*)>=0 FROM public.admin_list_questionnaires()$s$);
-- Negativas: o que deve ficar fechado.
SELECT pg_temp.run_case('platform_admin ATIVO (authenticated) não chama assert_platform_admin direto','e6200000-0000-0000-0000-000000000001','authenticated',$s$SELECT public.assert_platform_admin()$s$,true);
SELECT pg_temp.run_case('psicólogo ativo (authenticated) não chama função de gatilho direto','e6200000-0000-0000-0000-000000000002','authenticated',$s$SELECT public.set_updated_at()$s$,true);
SELECT pg_temp.run_case('anon não chama current_clinic_id',NULL,'anon',$s$SELECT public.current_clinic_id()$s$,true);
SELECT pg_temp.run_case('anon não chama get_current_clinic_entitlements',NULL,'anon',$s$SELECT * FROM public.get_current_clinic_entitlements()$s$,true);
SELECT pg_temp.run_case('anon não chama delete_genogram_person',NULL,'anon',$s$SELECT public.delete_genogram_person('00000000-0000-0000-0000-000000000000')$s$,true);
SELECT pg_temp.run_case('anon não chama user_can_access_patient',NULL,'anon',$s$SELECT public.user_can_access_patient('00000000-0000-0000-0000-000000000000')$s$,true);
DO $$
DECLARE n int; r text;
BEGIN
 SELECT count(*) INTO n FROM s2_pending;
 IF n=0 THEN RAISE NOTICE 'RESULTADO S2: COMPLETO (nenhum item pendente)';
 ELSE
  FOR r IN SELECT label FROM s2_pending LOOP RAISE WARNING 'RESULTADO S2: PENDENTE -> %',r; END LOOP;
  RAISE WARNING 'RESULTADO S2: INCOMPLETO, % item(ns) PENDENTE(S); não fechar o gate B sem resolver',n;
 END IF;
END;
$$;
ROLLBACK;
