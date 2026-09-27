-- Lote F: N01/F05/F07/F08. F09 (non-atomic completion) remains open.
BEGIN;

DROP POLICY qsa_staff_all ON public.questionnaire_schema_activations;
DROP POLICY qsa_patient_select ON public.questionnaire_schema_activations;
CREATE POLICY qsa_staff_all ON public.questionnaire_schema_activations
FOR ALL TO authenticated
USING (public.is_staff() IS TRUE AND clinic_id=public.current_clinic_id()
  AND public.user_can_access_response(questionnaire_response_id))
WITH CHECK (public.is_staff() IS TRUE AND clinic_id=public.current_clinic_id()
  AND public.user_can_access_response(questionnaire_response_id));

DROP POLICY questionnaire_results_select ON public.questionnaire_results;
CREATE POLICY questionnaire_results_select ON public.questionnaire_results
FOR SELECT TO authenticated USING (public.is_staff() IS TRUE
  AND public.user_can_access_response(response_id));

-- RLS controls rows, not columns. Raw professional columns must not be readable
-- by the shared authenticated database role. Authorized staff read via RPC.
REVOKE SELECT ON public.questionnaire_responses, public.questionnaire_answers
  FROM PUBLIC, anon, authenticated;
GRANT SELECT (id,clinic_id,patient_id,questionnaire_id,questionnaire_version_id,
  status,started_at,completed_at,created_at,updated_at)
  ON public.questionnaire_responses TO authenticated;
GRANT SELECT (id,response_id,question_id,answer_value,response_context_id,
  created_at,updated_at) ON public.questionnaire_answers TO authenticated;

CREATE FUNCTION public.guard_patient_questionnaire_write()
RETURNS trigger LANGUAGE plpgsql SECURITY INVOKER SET search_path=pg_catalog AS $$
DECLARE v_parent public.questionnaire_responses%ROWTYPE;
  v_total_questions integer; v_answered_count integer;
  v_db_role text:=current_setting('role',true);
BEGIN
  -- Trusted database/service writers retain their existing workflow. Neither
  -- user_metadata nor application JWT role claims can select a database role.
  IF v_db_role='service_role' OR
    (v_db_role='none' AND session_user IN ('postgres','supabase_admin')) THEN RETURN NEW; END IF;
  IF v_db_role IS DISTINCT FROM 'authenticated' OR auth.uid() IS NULL OR public.current_role() IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Questionnaire identity required';
  END IF;
  IF public.current_role()::text <> 'patient' THEN RETURN NEW; END IF;
  IF public.current_patient_id() IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Active patient required';
  END IF;

  IF TG_TABLE_NAME='questionnaire_responses' THEN
    IF NEW.patient_id IS DISTINCT FROM public.current_patient_id()
      OR NEW.reviewed_at IS NOT NULL OR NEW.reviewed_by_profile_id IS NOT NULL
      OR NEW.review_notes IS NOT NULL THEN
      -- Existing professional values may remain unchanged on an update.
      IF TG_OP='INSERT' THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Professional response fields are private';
      END IF;
    END IF;
    IF TG_OP='INSERT' THEN
      IF NEW.status::text <> 'draft' OR NEW.completed_at IS NOT NULL THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Response must start as draft';
      END IF;
      NEW.created_at:=now(); NEW.updated_at:=now(); NEW.started_at:=now();
    ELSE
      IF (to_jsonb(NEW)-ARRAY['status','completed_at','updated_at'])
        IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['status','completed_at','updated_at'])
        OR OLD.status::text <> 'draft'
        OR NEW.status::text NOT IN ('draft','completed')
        OR (NEW.status::text='draft' AND NEW.completed_at IS NOT NULL) THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Response transition or field is protected';
      END IF;
      IF NEW.status::text='completed' THEN NEW.completed_at:=now(); END IF;
    END IF;
  ELSIF TG_TABLE_NAME='questionnaire_answers' THEN
    -- Lock the parent while checking its state; completion cannot race an edit.
    SELECT id,status INTO v_parent.id,v_parent.status
      FROM public.questionnaire_responses WHERE id=NEW.response_id FOR UPDATE;
    IF NOT FOUND OR v_parent.status::text <> 'draft' THEN
      RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Finalized answers are immutable';
    END IF;
    IF TG_OP='INSERT' THEN
      IF NEW.professional_value IS NOT NULL OR NEW.professional_note IS NOT NULL THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Professional answer fields are protected';
      END IF;
      NEW.created_at:=now(); NEW.updated_at:=now();
    ELSIF (to_jsonb(NEW)-ARRAY['answer_value','updated_at'])
      IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['answer_value','updated_at']) THEN
      RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Answer field is protected';
    END IF;
  ELSIF TG_TABLE_NAME='questionnaire_response_contexts' THEN
    SELECT id,status INTO v_parent.id,v_parent.status
      FROM public.questionnaire_responses WHERE id=NEW.response_id FOR UPDATE;
    IF NOT FOUND OR (v_parent.status::text <> 'draft' AND
      (TG_OP='INSERT' OR NEW.status <> 'completed')) THEN
      RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Finalized context cannot reopen';
    END IF;
    IF TG_OP='INSERT' THEN
      IF NEW.status <> 'draft' OR NEW.completed_at IS NOT NULL THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Context must start as draft';
      END IF;
      NEW.created_at:=now(); NEW.updated_at:=now();
    END IF;
    IF TG_OP='UPDATE' AND (to_jsonb(NEW)-ARRAY['status','completed_at','updated_at'])
      IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['status','completed_at','updated_at']) THEN
      RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Context identity is protected';
    END IF;
    -- A direct status toggle must not erase/recreate a completed timestamp.
    -- Match the existing answer-sync workflow when a patient changes context status.
    IF TG_OP='UPDATE' AND NEW.status IS DISTINCT FROM OLD.status THEN
      SELECT count(*) INTO v_total_questions FROM public.questions
        WHERE questionnaire_id=NEW.questionnaire_id AND is_active=true AND code LIKE 'M_%';
      SELECT count(DISTINCT question_id) INTO v_answered_count FROM public.questionnaire_answers
        WHERE response_context_id=NEW.id AND answer_value IS NOT NULL;
      IF NEW.status IS DISTINCT FROM (CASE WHEN v_total_questions>0 AND v_answered_count>=v_total_questions
          THEN 'completed' ELSE 'draft' END) THEN
        RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Context status must follow answer progress';
      END IF;
    END IF;
    -- Patient JWT is also used by answer synchronization and official finish.
    -- Never trust its timestamp: generate on transition, preserve on repetition.
    -- This runs before the legacy validator, which otherwise retains input dates.
    IF TG_OP='UPDATE' THEN
      IF NEW.status='completed' THEN
        NEW.completed_at:=CASE WHEN OLD.status='completed' THEN OLD.completed_at ELSE now() END;
      ELSE
        NEW.completed_at:=NULL;
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;
ALTER FUNCTION public.guard_patient_questionnaire_write() OWNER TO postgres;
REVOKE ALL ON FUNCTION public.guard_patient_questionnaire_write() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER guard_patient_questionnaire_write BEFORE INSERT OR UPDATE
  ON public.questionnaire_responses FOR EACH ROW EXECUTE FUNCTION public.guard_patient_questionnaire_write();
CREATE TRIGGER guard_patient_questionnaire_write BEFORE INSERT OR UPDATE
  ON public.questionnaire_answers FOR EACH ROW EXECUTE FUNCTION public.guard_patient_questionnaire_write();
CREATE TRIGGER guard_patient_questionnaire_write BEFORE INSERT OR UPDATE
  ON public.questionnaire_response_contexts FOR EACH ROW EXECUTE FUNCTION public.guard_patient_questionnaire_write();

-- Explicit recursive schema, not a blacklist: unknown keys and object-valued
-- scalar fields never survive. Only released chart data is shared; no raw
-- snapshot, item-level scoring, free-text notes or professional overrides.
CREATE FUNCTION public.questionnaire_patient_chart(p_data jsonb,p_kind text DEFAULT 'root')
RETURNS jsonb LANGUAGE plpgsql STABLE SET search_path=pg_catalog AS $$
DECLARE v_out jsonb:='{}'::jsonb; v_key text; v_value jsonb; v_keys text[];
BEGIN
  IF jsonb_typeof(p_data) IS DISTINCT FROM 'object' THEN RETURN v_out; END IF;
  v_keys:=CASE p_kind
    WHEN 'root' THEN ARRAY['version','category_code','category_name','answer_count','total_weighted_score','average_score','completed_at']
    WHEN 'questionnaire_version' THEN ARRAY['version','scoring_method','scale_min','scale_max']
    WHEN 'summary' THEN ARRAY['raw_score','weighted_score','average_score','answered_items','max_possible_score']
    WHEN 'metric' THEN ARRAY['id','code','name','raw_score','weighted_score','average_score','answered_items','max_possible_score']
    WHEN 'context' THEN ARRAY['id','key','label','status','completed_at','answer_count','total_questions','completion_ratio']
    ELSE ARRAY[]::text[] END;
  FOREACH v_key IN ARRAY v_keys LOOP
    v_value:=p_data->v_key;
    IF jsonb_typeof(v_value) IN ('string','number','boolean','null') THEN
      v_out:=v_out || jsonb_build_object(v_key,v_value);
    END IF;
  END LOOP;
  IF p_kind IN ('root','context') THEN
    v_out:=v_out || jsonb_build_object('summary',public.questionnaire_patient_chart(p_data->'summary','summary'));
    FOREACH v_key IN ARRAY ARRAY['schemas','domains','contexts'] LOOP
      IF jsonb_typeof(p_data->v_key)='array' AND (p_kind='root' OR v_key='schemas') THEN
        SELECT coalesce(jsonb_agg(public.questionnaire_patient_chart(value,
          CASE WHEN v_key='contexts' THEN 'context' ELSE 'metric' END)),'[]'::jsonb)
          INTO v_value FROM jsonb_array_elements(p_data->v_key);
        v_out:=v_out || jsonb_build_object(v_key,v_value);
      END IF;
    END LOOP;
  END IF;
  IF p_kind='root' THEN
    v_out:=v_out || jsonb_build_object('questionnaire_version',
      public.questionnaire_patient_chart(p_data->'questionnaire_version','questionnaire_version'));
  END IF;
  RETURN v_out;
END;
$$;
ALTER FUNCTION public.questionnaire_patient_chart(jsonb,text) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.questionnaire_patient_chart(jsonb,text) FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.get_questionnaire_response_detail(p_response_id uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
DECLARE v_response public.questionnaire_responses%ROWTYPE;
  v_staff boolean; v_released boolean; v_out jsonb; v_answers jsonb; v_results jsonb;
BEGIN
  IF current_setting('role',true) IS DISTINCT FROM 'authenticated' OR auth.uid() IS NULL THEN RETURN NULL; END IF;
  v_staff:=public.current_role()::text='psychologist';
  SELECT r.* INTO v_response FROM public.questionnaire_responses r
    JOIN public.patients p ON p.id=r.patient_id AND p.clinic_id=r.clinic_id
    WHERE r.id=p_response_id AND r.clinic_id=public.current_clinic_id()
      AND ((v_staff IS TRUE AND public.user_can_access_response(r.id))
        OR (public.current_role()::text='patient' AND p.id=public.current_patient_id()));
  IF NOT FOUND THEN RETURN NULL; END IF;
  SELECT results_released_at IS NOT NULL INTO v_released FROM public.patients WHERE id=v_response.patient_id;
  v_out:=jsonb_build_object('id',v_response.id,'patient_id',v_response.patient_id,
    'questionnaire_id',v_response.questionnaire_id,'status',v_response.status,
    'started_at',v_response.started_at,'completed_at',v_response.completed_at,'created_at',v_response.created_at,
    'questionnaire',(SELECT jsonb_build_object('id',q.id,'code',q.code,'name',q.name,'description',q.description)
      FROM public.questionnaires q WHERE q.id=v_response.questionnaire_id));
  IF v_staff IS TRUE THEN
    v_out:=v_out || jsonb_build_object('reviewed_at',v_response.reviewed_at,'review_notes',v_response.review_notes,
      'reviewed_by',(SELECT jsonb_build_object('full_name',p.full_name) FROM public.profiles p WHERE p.id=v_response.reviewed_by_profile_id));
  END IF;
  SELECT coalesce(jsonb_agg((CASE WHEN v_staff IS TRUE THEN to_jsonb(a) ELSE
    jsonb_build_object('id',a.id,'question_id',a.question_id,'answer_value',a.answer_value) END)
    || jsonb_build_object('question',jsonb_build_object('id',q.id,'code',q.code,'text',q.text,
      'order_index',q.order_index,'answer_type',q.answer_type,'scale_min',q.scale_min,'scale_max',q.scale_max),
      'response_context',jsonb_build_object('context_label',c.context_label)) ORDER BY q.order_index),'[]'::jsonb)
    INTO v_answers FROM public.questionnaire_answers a JOIN public.questions q ON q.id=a.question_id
    LEFT JOIN public.questionnaire_response_contexts c ON c.id=a.response_context_id
    WHERE a.response_id=v_response.id AND (v_staff IS TRUE OR v_released OR v_response.status::text='draft');
  SELECT coalesce(jsonb_agg((CASE WHEN v_staff IS TRUE THEN to_jsonb(r) ELSE
    jsonb_build_object('id',r.id,'category_id',r.category_id,'total_score',r.total_score,'average_score',r.average_score,
      'patient_result',public.questionnaire_patient_chart(r.snapshot)) END)
    || jsonb_build_object('category',jsonb_build_object('id',c.id,'code',c.code,'name',c.name))),'[]'::jsonb)
    INTO v_results FROM public.questionnaire_results r JOIN public.question_categories c ON c.id=r.category_id
    WHERE r.response_id=v_response.id AND (v_staff IS TRUE OR v_released);
  RETURN v_out || jsonb_build_object('questionnaire_answers',v_answers,'questionnaire_results',v_results);
END;
$$;

CREATE FUNCTION public.list_questionnaire_response_summaries(p_patient_id uuid)
RETURNS SETOF jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT (d.value - ARRAY['questionnaire_answers','questionnaire_results']) || jsonb_build_object(
    'questionnaire_answers',jsonb_build_array(jsonb_build_object('count',jsonb_array_length(d.value->'questionnaire_answers'))),
    'questionnaire_results',jsonb_build_array(jsonb_build_object('count',jsonb_array_length(d.value->'questionnaire_results'))))
  FROM public.questionnaire_responses r
  CROSS JOIN LATERAL (SELECT public.get_questionnaire_response_detail(r.id) AS value) d
  WHERE r.patient_id=p_patient_id AND d.value IS NOT NULL ORDER BY r.created_at DESC;
$$;

CREATE FUNCTION public.get_patient_schema_activations(p_response_id uuid)
RETURNS TABLE(id uuid,questionnaire_response_id uuid,schema_code text,schema_name text,created_at timestamptz)
LANGUAGE sql STABLE SECURITY DEFINER SET search_path=pg_catalog AS $$
  SELECT a.id,a.questionnaire_response_id,a.schema_code,a.schema_name,a.created_at
  FROM public.questionnaire_schema_activations a
  JOIN public.questionnaire_responses r ON r.id=a.questionnaire_response_id AND r.clinic_id=a.clinic_id
  JOIN public.patients p ON p.id=r.patient_id AND p.clinic_id=r.clinic_id
  WHERE current_setting('role',true)='authenticated' AND auth.uid() IS NOT NULL
    AND public.current_role()::text='patient' AND p.id=public.current_patient_id()
    AND p.clinic_id=public.current_clinic_id() AND p.results_released_at IS NOT NULL AND r.id=p_response_id;
$$;

ALTER FUNCTION public.get_questionnaire_response_detail(uuid) OWNER TO postgres;
ALTER FUNCTION public.list_questionnaire_response_summaries(uuid) OWNER TO postgres;
ALTER FUNCTION public.get_patient_schema_activations(uuid) OWNER TO postgres;
REVOKE ALL ON FUNCTION public.get_questionnaire_response_detail(uuid),
  public.list_questionnaire_response_summaries(uuid), public.get_patient_schema_activations(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_questionnaire_response_detail(uuid),
  public.list_questionnaire_response_summaries(uuid), public.get_patient_schema_activations(uuid) TO authenticated;
COMMIT;
