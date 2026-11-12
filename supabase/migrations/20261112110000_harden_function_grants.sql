-- S2 (Marco Segurança Supabase): endurece EXECUTE e search_path das funções do schema public.
-- Achados M1, M2, B1, B2 e B3 do parecer da Viúva Negra (12/11/2026). Não altera corpo de função,
-- tabela, policy nem o contrato de nenhuma RPC usada pelo app.
--
-- M1  Nenhuma função de public é executável por anon/PUBLIC. As 13 SECURITY DEFINER do advisor
--     (e as demais, em profundidade) perdem EXECUTE de anon e PUBLIC. O app não chama RPC como anon
--     (grep em mobile/lib e supabase/functions: só roles autenticadas e service_role).
--     authenticated e service_role mantêm o que tinham, exceto B2. Policies RLS que chamam
--     current_clinic_id, current_role, is_staff, user_can_access_patient, user_can_access_response,
--     scoring_* etc. seguem funcionando para authenticated. Para anon (que não tem fluxo legítimo)
--     uma policy que chame essas funções passa a negar por permissão em vez de avaliar.
--     Funções novas: ALTER DEFAULT PRIVILEGES (schema public: sem anon; global: sem PUBLIC).
-- M2  rls_auto_enable (criada fora do repo, provavelmente pelo painel; não existe no banco local):
--     sem EXECUTE para PUBLIC, anon e authenticated, se existir. Ver "Drift" abaixo.
-- B2  Funções de gatilho (RETURNS trigger/event_trigger) e assert_platform_admin() sem EXECUTE para
--     authenticated. Gatilho não exige EXECUTE ao disparar (só ao criar o trigger) e todos os
--     chamadores de assert_platform_admin são SECURITY DEFINER (executam como dono).
--     Helpers usados em policies/views (current_*, is_staff, user_can_access_*, scoring_*,
--     is_library_cover_admin, personality_results_public) MANTÊM EXECUTE para authenticated.
-- B3  SET search_path = public nas funções de public que ainda não tinham search_path fixo
--     (29 no banco local, todas SECURITY INVOKER exceto validate_patient_invitation, que é
--     SECURITY DEFINER): patient_problems_set_resolved_at, personality_results_public, set_updated_at,
--     sync_questionnaire_response_context_completion, therapy_goals_set_completed_at,
--     touch_healthy_resources, touch_profile_avatar_updated_at, validate_case_conceptualization_clinic,
--     validate_daily_monitor_clinic, validate_genogram_family_patterns_clinic,
--     validate_genogram_person_clinic, validate_genogram_relationship_consistency,
--     validate_patient_check_in_clinic, validate_patient_clinic_refs, validate_patient_invitation,
--     validate_patient_problem_clinic, validate_patient_resource_access_clinic,
--     validate_patient_timeline_event_clinic, validate_personality_assessment_clinic,
--     validate_question_category_item_questionnaire, validate_question_scoring_rule_refs,
--     validate_questionnaire_answer_context, validate_questionnaire_answer_questionnaire,
--     validate_questionnaire_professional_access, validate_questionnaire_response_clinic,
--     validate_questionnaire_response_context, validate_questionnaire_result_refs,
--     validate_therapy_goal_clinic, validate_timeline_event_person_consistency.
--     Os laços abaixo são dinâmicos (pegam também deriva em produção); idempotentes.
-- B1  View patient_shared_personality: exceção INTENCIONAL ao lint "security definer view"
--     (security_invoker=false). Ela filtra por current_patient_id()/current_clinic_id(), anon não
--     tem SELECT e o score é sanitizado por personality_results_public. Mantida; documentada em
--     COMMENT ON VIEW. Não é alterada.
--
-- Drift: o comentário/rollback de rls_auto_enable só vale onde a função existe (produção).
-- Reversão (GRANTs anteriores e RESET dos search_path): bloco comentado no fim do arquivo.

-- M1: sem EXECUTE para anon/PUBLIC em toda função de public (exceto membros de extensão).
DO $m1$
DECLARE f record;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.prokind IN ('f','p')
      AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_depend d WHERE d.classid = 'pg_catalog.pg_proc'::regclass AND d.objid = p.oid AND d.objsubid = 0 AND d.deptype = 'e')
  LOOP
    EXECUTE format('REVOKE EXECUTE ON ROUTINE %s FROM PUBLIC, anon', f.sig);
  END LOOP;
END
$m1$;

-- M2: rls_auto_enable (onde existir) fechada para PUBLIC, anon e authenticated.
DO $m2$
DECLARE f record;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace AND p.proname = 'rls_auto_enable'
  LOOP
    EXECUTE format('REVOKE EXECUTE ON ROUTINE %s FROM PUBLIC, anon, authenticated', f.sig);
  END LOOP;
END
$m2$;

-- B2: gatilhos e assert_platform_admin sem EXECUTE para authenticated.
DO $b2$
DECLARE f record;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.prokind = 'f'
      AND (p.prorettype IN ('trigger'::regtype, 'event_trigger'::regtype)
           OR p.proname = 'assert_platform_admin')
      AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_depend d WHERE d.classid = 'pg_catalog.pg_proc'::regclass AND d.objid = p.oid AND d.objsubid = 0 AND d.deptype = 'e')
  LOOP
    EXECUTE format('REVOKE EXECUTE ON ROUTINE %s FROM authenticated', f.sig);
  END LOOP;
END
$b2$;

-- B3: search_path fixo, sem tocar no corpo.
DO $b3$
DECLARE f record;
BEGIN
  FOR f IN
    SELECT p.oid::regprocedure AS sig
    FROM pg_catalog.pg_proc p
    WHERE p.pronamespace = 'public'::regnamespace
      AND p.prokind IN ('f','p')
      AND NOT EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig, '{}'::text[])) c WHERE c LIKE 'search_path=%')
      AND NOT EXISTS (SELECT 1 FROM pg_catalog.pg_depend d WHERE d.classid = 'pg_catalog.pg_proc'::regclass AND d.objid = p.oid AND d.objsubid = 0 AND d.deptype = 'e')
  LOOP
    EXECUTE format('ALTER ROUTINE %s SET search_path = public', f.sig);
  END LOOP;
END
$b3$;

-- M1 (funções futuras). O default ACL de EXECUTE é por papel criador; as migrations rodam como postgres.
-- IN SCHEMA remove só o grant explícito a anon; o grant implícito a PUBLIC só sai pelo default global.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon;
-- EFEITO GLOBAL (linha abaixo): sem "IN SCHEMA", vale para QUALQUER schema e só para funções FUTURAS criadas
-- pelo papel postgres (CREATE FUNCTION em qualquer schema): deixam de nascer com EXECUTE para PUBLIC; em schemas
-- sem default próprio (tudo fora de public) nenhum papel cliente as executa até haver GRANT explícito (falha
-- segura; conferir com has_function_privilege se uma policy/view em outro schema passar a depender delas).
-- CREATE EXTENSION: NÃO é afetado. Medido localmente: funções de extensão nascem com dono supabase_admin
-- (script de extensão), logo seguem os defaults de supabase_admin (pendência abaixo) e, enquanto estes não
-- forem aplicados, ficam executáveis por anon. O laço M1 ignora membros de extensão. Depois de habilitar
-- qualquer extensão em public, CONFERIR os grants. Funções já existentes não mudam. A linha IN SCHEMA acima
-- não remove o grant implícito a PUBLIC (por isso a global). Registrar no handoff.
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
DO $dp$
BEGIN
  -- Funções criadas pelo painel/CLI como supabase_admin (origem provável de rls_auto_enable).
  BEGIN
    EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon';
    EXECUTE 'ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC';
  EXCEPTION WHEN insufficient_privilege THEN
    RAISE WARNING 'PENDENTE (gate antes do B): default privileges de supabase_admin NAO alterados (postgres sem permissao). Aplicar como supabase_admin: ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC, anon; e ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;';
  END;
END
$dp$;

-- B1: exceção intencional documentada no próprio banco.
COMMENT ON VIEW public.patient_shared_personality IS
  'Exceção intencional ao lint security_definer_view (security_invoker=false): filtra por current_patient_id()/current_clinic_id(), sem SELECT para anon, score sanitizado por personality_results_public. Mantida (S2/B1).';


-- ROLLBACK (manual, não executado). Restaura os GRANTs anteriores e o search_path.
-- Estado anterior medido no banco local: anon com EXECUTE explícito nas 47 funções abaixo; PUBLIC com
-- EXECUTE em 44 funções de public; authenticated com EXECUTE nas 36 funções de gatilho e em
-- assert_platform_admin(); 29 funções sem search_path. Default ACL anterior em public (postgres e
-- supabase_admin): anon, authenticated e service_role com EXECUTE; global: PUBLIC com EXECUTE.
--
-- 1) default privileges:
--   ALTER DEFAULT PRIVILEGES GRANT EXECUTE ON FUNCTIONS TO PUBLIC;
--   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO anon;
--   (e, se foram alteradas: o mesmo FOR ROLE supabase_admin)
-- 2) anon (47 funções, estado anterior exato):
--   GRANT EXECUTE ON FUNCTION public."current_role"() TO anon;
--   GRANT EXECUTE ON FUNCTION public.audit_sensitive_change() TO anon;
--   GRANT EXECUTE ON FUNCTION public.current_clinic_id() TO anon;
--   GRANT EXECUTE ON FUNCTION public.delete_genogram_person(uuid) TO anon;
--   GRANT EXECUTE ON FUNCTION public.ensure_draft_question_total_category_item() TO anon;
--   GRANT EXECUTE ON FUNCTION public.ensure_draft_questionnaire_total_category() TO anon;
--   GRANT EXECUTE ON FUNCTION public.get_current_clinic_entitlements() TO anon;
--   GRANT EXECUTE ON FUNCTION public.get_patient_infographic_timeline(uuid) TO anon;
--   GRANT EXECUTE ON FUNCTION public.guard_genogram_person_deleted_at() TO anon;
--   GRANT EXECUTE ON FUNCTION public.guard_timeline_shared_with_patient() TO anon;
--   GRANT EXECUTE ON FUNCTION public.handle_user_email_updated() TO anon;
--   GRANT EXECUTE ON FUNCTION public.is_staff() TO anon;
--   GRANT EXECUTE ON FUNCTION public.patient_problems_set_resolved_at() TO anon;
--   GRANT EXECUTE ON FUNCTION public.personality_results_public(jsonb) TO anon;
--   GRANT EXECUTE ON FUNCTION public.scoring_admin_can_manage_row(uuid) TO anon;
--   GRANT EXECUTE ON FUNCTION public.scoring_row_visible_to_current_clinic(uuid) TO anon;
--   GRANT EXECUTE ON FUNCTION public.set_updated_at() TO anon;
--   GRANT EXECUTE ON FUNCTION public.sync_questionnaire_response_context_completion() TO anon;
--   GRANT EXECUTE ON FUNCTION public.therapy_goals_set_completed_at() TO anon;
--   GRANT EXECUTE ON FUNCTION public.touch_healthy_resources() TO anon;
--   GRANT EXECUTE ON FUNCTION public.touch_profile_avatar_updated_at() TO anon;
--   GRANT EXECUTE ON FUNCTION public.user_can_access_patient(uuid) TO anon;
--   GRANT EXECUTE ON FUNCTION public.user_can_access_response(uuid) TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_case_conceptualization_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_daily_monitor_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_genogram_family_patterns_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_genogram_person_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_genogram_relationship_consistency() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_check_in_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_clinic_refs() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_invitation() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_problem_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_resource_access_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_timeline_event_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_personality_assessment_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_question_category_item_questionnaire() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_question_scoring_rule_refs() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_answer_context() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_answer_questionnaire() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_professional_access() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_response_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_response_context() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_result_refs() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_schemas_clinic_matches_domain() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_severity_range_refs() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_therapy_goal_clinic() TO anon;
--   GRANT EXECUTE ON FUNCTION public.validate_timeline_event_person_consistency() TO anon;
--    PUBLIC (44 funções, estado anterior exato):
--   GRANT EXECUTE ON FUNCTION public."current_role"() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.audit_sensitive_change() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.current_clinic_id() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.ensure_draft_question_total_category_item() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.ensure_draft_questionnaire_total_category() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.guard_genogram_person_deleted_at() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.guard_timeline_shared_with_patient() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.handle_user_email_updated() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.is_staff() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.patient_problems_set_resolved_at() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.personality_results_public(jsonb) TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.scoring_admin_can_manage_row(uuid) TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.scoring_row_visible_to_current_clinic(uuid) TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.set_updated_at() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.sync_questionnaire_response_context_completion() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.therapy_goals_set_completed_at() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.touch_healthy_resources() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.touch_profile_avatar_updated_at() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.user_can_access_patient(uuid) TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.user_can_access_response(uuid) TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_case_conceptualization_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_daily_monitor_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_genogram_family_patterns_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_genogram_person_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_genogram_relationship_consistency() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_check_in_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_clinic_refs() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_invitation() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_problem_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_resource_access_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_patient_timeline_event_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_personality_assessment_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_question_category_item_questionnaire() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_question_scoring_rule_refs() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_answer_context() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_answer_questionnaire() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_professional_access() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_response_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_response_context() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_questionnaire_result_refs() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_schemas_clinic_matches_domain() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_severity_range_refs() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_therapy_goal_clinic() TO PUBLIC;
--   GRANT EXECUTE ON FUNCTION public.validate_timeline_event_person_consistency() TO PUBLIC;
-- 3) authenticated nos gatilhos e assert_platform_admin:
--   DO $r$ DECLARE f record; BEGIN
--     FOR f IN SELECT p.oid::regprocedure sig FROM pg_proc p WHERE p.pronamespace='public'::regnamespace AND p.prokind='f'
--              AND (p.prorettype IN ('trigger'::regtype,'event_trigger'::regtype) OR p.proname='assert_platform_admin') LOOP
--       EXECUTE format('GRANT EXECUTE ON ROUTINE %s TO authenticated', f.sig);
--     END LOOP; END $r$;
-- 4) rls_auto_enable (onde existir): GRANT EXECUTE ON FUNCTION public.rls_auto_enable() TO PUBLIC, anon, authenticated;
--    (confirmar o estado anterior no painel antes de reabrir)
-- 5) search_path das 29 funções (nomes no cabeçalho B3): ALTER ROUTINE public.<nome>(<args>) RESET search_path;
-- 6) COMMENT ON VIEW public.patient_shared_personality IS NULL;
