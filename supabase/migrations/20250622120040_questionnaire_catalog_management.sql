-- Administrative questionnaire catalog with immutable published instruments.

CREATE OR REPLACE FUNCTION public.assert_platform_admin()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL OR public.current_role() <> 'admin' THEN
    RAISE EXCEPTION 'Only platform administrators can manage questionnaires'
      USING ERRCODE = '42501';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_list_questionnaires()
RETURNS TABLE (
  id uuid, code text, name text, description text, is_active boolean,
  author_name text, instrument_version text, citation text, license_notes text,
  clinical_status text, version_id uuid, version text, version_status text,
  reference_period text, scale_min integer, scale_max integer,
  question_count bigint, response_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_platform_admin();
  RETURN QUERY
  SELECT q.id, q.code, q.name, q.description, q.is_active,
         q.author_name, q.instrument_version, q.citation, q.license_notes,
         q.clinical_status, qv.id, qv.version, qv.status::text,
         qv.reference_period, qv.scale_min, qv.scale_max,
         (SELECT count(*) FROM public.questions qu WHERE qu.questionnaire_id = q.id),
         (SELECT count(*) FROM public.questionnaire_responses qr WHERE qr.questionnaire_id = q.id)
  FROM public.questionnaires q
  LEFT JOIN LATERAL (
    SELECT v.* FROM public.questionnaire_versions v
    WHERE v.questionnaire_id = q.id
    ORDER BY (v.status = 'active') DESC, v.created_at DESC
    LIMIT 1
  ) qv ON true
  ORDER BY q.updated_at DESC, q.name;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_get_questionnaire(p_questionnaire_id uuid)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_result jsonb;
BEGIN
  PERFORM public.assert_platform_admin();
  SELECT jsonb_build_object(
    'questionnaire', to_jsonb(q),
    'version', to_jsonb(v),
    'questions', COALESCE((
      SELECT jsonb_agg(to_jsonb(qu) || jsonb_build_object(
        'weight', COALESCE(sr.weight, 1),
        'reverse_score', COALESCE(sr.reverse_score, false)
      ) ORDER BY qu.order_index)
      FROM public.questions qu
      LEFT JOIN public.question_scoring_rules sr
        ON sr.question_id = qu.id AND sr.questionnaire_version_id = v.id
      WHERE qu.questionnaire_id = q.id
    ), '[]'::jsonb)
  ) INTO v_result
  FROM public.questionnaires q
  LEFT JOIN LATERAL (
    SELECT qv.* FROM public.questionnaire_versions qv
    WHERE qv.questionnaire_id = q.id
    ORDER BY (qv.status = 'active') DESC, qv.created_at DESC LIMIT 1
  ) v ON true
  WHERE q.id = p_questionnaire_id;
  IF v_result IS NULL THEN RAISE EXCEPTION 'Questionnaire not found' USING ERRCODE = 'P0002'; END IF;
  RETURN v_result;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_save_questionnaire_draft(
  p_id uuid DEFAULT NULL, p_code text DEFAULT NULL, p_name text DEFAULT NULL,
  p_description text DEFAULT NULL, p_author_name text DEFAULT NULL,
  p_instrument_version text DEFAULT '1.0', p_citation text DEFAULT NULL,
  p_license_notes text DEFAULT NULL, p_reference_period text DEFAULT 'unspecified',
  p_scale_min integer DEFAULT 1, p_scale_max integer DEFAULT 5
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_id uuid; v_version_id uuid;
BEGIN
  PERFORM public.assert_platform_admin();
  IF trim(COALESCE(p_code, '')) = '' OR trim(COALESCE(p_name, '')) = '' THEN
    RAISE EXCEPTION 'Code and name are required' USING ERRCODE = '22023';
  END IF;
  IF p_scale_min IS NULL OR p_scale_max IS NULL OR p_scale_min > p_scale_max THEN
    RAISE EXCEPTION 'Invalid scale range' USING ERRCODE = '22023';
  END IF;
  IF p_id IS NULL THEN
    INSERT INTO public.questionnaires (
      code, name, description, is_active, author_name, instrument_version,
      citation, license_notes, clinical_status
    ) VALUES (
      upper(trim(p_code)), trim(p_name), nullif(trim(p_description), ''), false,
      nullif(trim(p_author_name), ''), nullif(trim(p_instrument_version), ''),
      nullif(trim(p_citation), ''), nullif(trim(p_license_notes), ''), 'draft'
    ) RETURNING id INTO v_id;
    INSERT INTO public.questionnaire_versions (
      questionnaire_id, version, status, scoring_method, scale_min, scale_max,
      reference_period
    ) VALUES (
      v_id, COALESCE(nullif(trim(p_instrument_version), ''), '1.0'), 'draft',
      'weighted_sum', p_scale_min, p_scale_max, p_reference_period
    );
  ELSE
    SELECT id INTO v_id FROM public.questionnaires
    WHERE id = p_id AND clinical_status IN ('draft', 'validation') AND is_active = false
    FOR UPDATE;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Published questionnaires are immutable; duplicate it first'
        USING ERRCODE = '55000';
    END IF;
    UPDATE public.questionnaires SET
      code = upper(trim(p_code)), name = trim(p_name),
      description = nullif(trim(p_description), ''),
      author_name = nullif(trim(p_author_name), ''),
      instrument_version = nullif(trim(p_instrument_version), ''),
      citation = nullif(trim(p_citation), ''),
      license_notes = nullif(trim(p_license_notes), ''), updated_at = timezone('utc', now())
    WHERE id = v_id;
    SELECT id INTO v_version_id FROM public.questionnaire_versions
    WHERE questionnaire_id = v_id AND status = 'draft' ORDER BY created_at DESC LIMIT 1;
    UPDATE public.questionnaire_versions SET
      version = COALESCE(nullif(trim(p_instrument_version), ''), '1.0'),
      scale_min = p_scale_min, scale_max = p_scale_max,
      reference_period = p_reference_period, updated_at = timezone('utc', now())
    WHERE id = v_version_id;
  END IF;
  INSERT INTO public.audit_events (clinic_id, actor_profile_id, action, entity_type, entity_id, metadata)
  VALUES (public.current_clinic_id(), auth.uid(), CASE WHEN p_id IS NULL THEN 'create_draft' ELSE 'update_draft' END,
          'questionnaires', v_id, jsonb_build_object('source', 'admin_catalog'));
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_save_question(
  p_questionnaire_id uuid, p_question_id uuid DEFAULT NULL, p_code text DEFAULT NULL,
  p_text text DEFAULT NULL, p_order_index integer DEFAULT 0,
  p_answer_type public.question_answer_type DEFAULT 'likert_scale',
  p_scale_min integer DEFAULT 1, p_scale_max integer DEFAULT 5,
  p_weight numeric DEFAULT 1, p_reverse_score boolean DEFAULT false
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_id uuid; v_version_id uuid;
BEGIN
  PERFORM public.assert_platform_admin();
  IF NOT EXISTS (SELECT 1 FROM public.questionnaires WHERE id = p_questionnaire_id AND clinical_status IN ('draft','validation') AND NOT is_active) THEN
    RAISE EXCEPTION 'Only drafts can be edited' USING ERRCODE = '55000';
  END IF;
  IF trim(COALESCE(p_code,'')) = '' OR trim(COALESCE(p_text,'')) = '' OR p_order_index < 0 OR p_weight <= 0 OR p_scale_min > p_scale_max THEN
    RAISE EXCEPTION 'Invalid question data' USING ERRCODE = '22023';
  END IF;
  SELECT id INTO v_version_id FROM public.questionnaire_versions
  WHERE questionnaire_id = p_questionnaire_id AND status = 'draft' ORDER BY created_at DESC LIMIT 1;
  IF p_question_id IS NULL THEN
    INSERT INTO public.questions (questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max)
    VALUES (p_questionnaire_id, upper(trim(p_code)), trim(p_text), p_order_index, p_answer_type, p_scale_min, p_scale_max)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.questions SET code = upper(trim(p_code)), text = trim(p_text),
      order_index = p_order_index, answer_type = p_answer_type,
      scale_min = p_scale_min, scale_max = p_scale_max, updated_at = timezone('utc', now())
    WHERE id = p_question_id AND questionnaire_id = p_questionnaire_id RETURNING id INTO v_id;
    IF v_id IS NULL THEN RAISE EXCEPTION 'Question not found' USING ERRCODE = 'P0002'; END IF;
  END IF;
  INSERT INTO public.question_scoring_rules (questionnaire_version_id, question_id, weight, reverse_score, min_value, max_value, sort_order)
  VALUES (v_version_id, v_id, p_weight, p_reverse_score, p_scale_min, p_scale_max, p_order_index)
  ON CONFLICT (questionnaire_version_id, question_id) DO UPDATE SET
    weight = EXCLUDED.weight, reverse_score = EXCLUDED.reverse_score,
    min_value = EXCLUDED.min_value, max_value = EXCLUDED.max_value,
    sort_order = EXCLUDED.sort_order, updated_at = timezone('utc', now());
  RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_question(p_questionnaire_id uuid, p_question_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM public.assert_platform_admin();
  IF NOT EXISTS (SELECT 1 FROM public.questionnaires WHERE id = p_questionnaire_id AND clinical_status IN ('draft','validation') AND NOT is_active) THEN
    RAISE EXCEPTION 'Only draft questions can be deleted' USING ERRCODE = '55000';
  END IF;
  DELETE FROM public.questions WHERE id = p_question_id AND questionnaire_id = p_questionnaire_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Question not found' USING ERRCODE = 'P0002'; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_publish_questionnaire(p_questionnaire_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_version_id uuid; v_question_count integer; v_rule_count integer;
BEGIN
  PERFORM public.assert_platform_admin();
  SELECT qv.id INTO v_version_id FROM public.questionnaires q
  JOIN public.questionnaire_versions qv ON qv.questionnaire_id = q.id AND qv.status = 'draft'
  WHERE q.id = p_questionnaire_id AND q.clinical_status IN ('draft','validation') AND NOT q.is_active
  ORDER BY qv.created_at DESC LIMIT 1 FOR UPDATE OF q;
  IF v_version_id IS NULL THEN RAISE EXCEPTION 'Editable draft not found' USING ERRCODE = 'P0002'; END IF;
  SELECT count(*) INTO v_question_count FROM public.questions WHERE questionnaire_id = p_questionnaire_id AND is_active;
  SELECT count(*) INTO v_rule_count FROM public.question_scoring_rules WHERE questionnaire_version_id = v_version_id;
  IF v_question_count = 0 OR v_rule_count <> v_question_count THEN
    RAISE EXCEPTION 'Every questionnaire needs questions with scoring rules' USING ERRCODE = '23514';
  END IF;
  UPDATE public.questionnaire_versions SET status = 'active', published_at = timezone('utc', now()) WHERE id = v_version_id;
  UPDATE public.questionnaires SET is_active = true, clinical_status = 'approved',
    clinically_approved_at = timezone('utc', now()), clinically_approved_by = auth.uid(), updated_at = timezone('utc', now())
  WHERE id = p_questionnaire_id;
  INSERT INTO public.audit_events (clinic_id, actor_profile_id, action, entity_type, entity_id, metadata)
  VALUES (public.current_clinic_id(), auth.uid(), 'publish', 'questionnaires', p_questionnaire_id, jsonb_build_object('version_id', v_version_id));
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_archive_questionnaire(p_questionnaire_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM public.assert_platform_admin();
  UPDATE public.questionnaires SET is_active = false, clinical_status = 'suspended', updated_at = timezone('utc', now())
  WHERE id = p_questionnaire_id AND clinical_status = 'approved';
  IF NOT FOUND THEN RAISE EXCEPTION 'Published questionnaire not found' USING ERRCODE = 'P0002'; END IF;
  UPDATE public.questionnaire_versions SET status = 'archived' WHERE questionnaire_id = p_questionnaire_id AND status = 'active';
  UPDATE public.questionnaire_professional_access SET is_enabled = false WHERE questionnaire_id = p_questionnaire_id;
  INSERT INTO public.audit_events (clinic_id, actor_profile_id, action, entity_type, entity_id, metadata)
  VALUES (public.current_clinic_id(), auth.uid(), 'archive', 'questionnaires', p_questionnaire_id, '{}'::jsonb);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_questionnaire_draft(p_questionnaire_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  PERFORM public.assert_platform_admin();
  IF EXISTS (SELECT 1 FROM public.questionnaire_responses WHERE questionnaire_id = p_questionnaire_id) THEN
    RAISE EXCEPTION 'Questionnaires with responses cannot be deleted' USING ERRCODE = '55000';
  END IF;
  DELETE FROM public.questionnaires WHERE id = p_questionnaire_id AND clinical_status IN ('draft','validation') AND NOT is_active;
  IF NOT FOUND THEN RAISE EXCEPTION 'Only unused drafts can be deleted' USING ERRCODE = '55000'; END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_duplicate_questionnaire_as_draft(p_questionnaire_id uuid, p_new_code text, p_new_version text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_new_id uuid; v_new_version_id uuid; v_old_version_id uuid;
BEGIN
  PERFORM public.assert_platform_admin();
  SELECT id INTO v_old_version_id FROM public.questionnaire_versions WHERE questionnaire_id = p_questionnaire_id AND status IN ('active','archived') ORDER BY created_at DESC LIMIT 1;
  IF v_old_version_id IS NULL THEN RAISE EXCEPTION 'Published version not found' USING ERRCODE = 'P0002'; END IF;
  INSERT INTO public.questionnaires (code,name,description,is_active,author_name,instrument_version,citation,license_notes,clinical_status)
  SELECT upper(trim(p_new_code)), name, description, false, author_name, trim(p_new_version), citation, license_notes, 'draft'
  FROM public.questionnaires WHERE id = p_questionnaire_id RETURNING id INTO v_new_id;
  INSERT INTO public.questionnaire_versions (questionnaire_id,version,status,scoring_method,scale_min,scale_max,instructions,reference_period)
  SELECT v_new_id, trim(p_new_version), 'draft', scoring_method, scale_min, scale_max, instructions, reference_period
  FROM public.questionnaire_versions WHERE id = v_old_version_id RETURNING id INTO v_new_version_id;
  WITH copied AS (
    INSERT INTO public.questions (questionnaire_id,code,text,order_index,answer_type,scale_min,scale_max,is_active)
    SELECT v_new_id, code, text, order_index, answer_type, scale_min, scale_max, is_active
    FROM public.questions WHERE questionnaire_id = p_questionnaire_id
    RETURNING id, code
  )
  INSERT INTO public.question_scoring_rules (questionnaire_version_id,question_id,weight,reverse_score,min_value,max_value,sort_order,metadata)
  SELECT v_new_version_id, c.id, r.weight, r.reverse_score, r.min_value, r.max_value, r.sort_order, r.metadata
  FROM copied c
  JOIN public.questions old_q ON old_q.questionnaire_id = p_questionnaire_id AND lower(old_q.code) = lower(c.code)
  LEFT JOIN public.question_scoring_rules r ON r.questionnaire_version_id = v_old_version_id AND r.question_id = old_q.id
  WHERE r.id IS NOT NULL;
  RETURN v_new_id;
END;
$$;

REVOKE ALL ON FUNCTION public.assert_platform_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_list_questionnaires() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_get_questionnaire(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_save_questionnaire_draft(uuid,text,text,text,text,text,text,text,text,integer,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_save_question(uuid,uuid,text,text,integer,public.question_answer_type,integer,integer,numeric,boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_question(uuid,uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_publish_questionnaire(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_archive_questionnaire(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_delete_questionnaire_draft(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_duplicate_questionnaire_as_draft(uuid,text,text) TO authenticated;
