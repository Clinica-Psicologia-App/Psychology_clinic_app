-- Versionamento real de questionários.
--
-- Perguntas passam a pertencer a uma versão (questionnaire_versions) e cada
-- resposta fixa a versão respondida. Editar um instrumento publicado cria uma
-- nova versão em rascunho — as respostas antigas continuam íntegras, apontando
-- para as perguntas/regras da versão original.
--
-- Também corrige defeito latente: o scoring passará a usar a versão fixada na
-- resposta (as edge functions são atualizadas em conjunto) em vez de resolver
-- a versão ativa no momento da finalização.

-- ═══════════════════════════════════════════════════════════════════════════
-- 1. Colunas de versão
-- ═══════════════════════════════════════════════════════════════════════════

ALTER TABLE public.questions
  ADD COLUMN IF NOT EXISTS questionnaire_version_id UUID
    REFERENCES public.questionnaire_versions(id) ON DELETE CASCADE;

ALTER TABLE public.questionnaire_responses
  ADD COLUMN IF NOT EXISTS questionnaire_version_id UUID
    REFERENCES public.questionnaire_versions(id) ON DELETE RESTRICT;

-- ═══════════════════════════════════════════════════════════════════════════
-- 2. Backfill
-- ═══════════════════════════════════════════════════════════════════════════

-- 2.1 Questionários sem nenhuma versão ganham uma v1 ativa
INSERT INTO public.questionnaire_versions (
  questionnaire_id, version, status, scoring_method, published_at
)
SELECT q.id, 'v1', 'active', 'weighted_sum', timezone('utc', now())
FROM public.questionnaires q
WHERE NOT EXISTS (
  SELECT 1 FROM public.questionnaire_versions v WHERE v.questionnaire_id = q.id
);

-- 2.2 Resolução da "versão corrente" por questionário: ativa > mais recente
CREATE TEMP TABLE _current_version ON COMMIT DROP AS
SELECT DISTINCT ON (v.questionnaire_id)
       v.questionnaire_id, v.id AS version_id
FROM public.questionnaire_versions v
ORDER BY v.questionnaire_id, (v.status = 'active') DESC, v.created_at DESC;

UPDATE public.questions qu
SET questionnaire_version_id = cv.version_id
FROM _current_version cv
WHERE cv.questionnaire_id = qu.questionnaire_id
  AND qu.questionnaire_version_id IS NULL;

UPDATE public.questionnaire_responses qr
SET questionnaire_version_id = cv.version_id
FROM _current_version cv
WHERE cv.questionnaire_id = qr.questionnaire_id
  AND qr.questionnaire_version_id IS NULL;

ALTER TABLE public.questions
  ALTER COLUMN questionnaire_version_id SET NOT NULL;
ALTER TABLE public.questionnaire_responses
  ALTER COLUMN questionnaire_version_id SET NOT NULL;

-- ═══════════════════════════════════════════════════════════════════════════
-- 3. Constraints e índices
-- ═══════════════════════════════════════════════════════════════════════════

-- Código de pergunta é único por VERSÃO (v1 e v2 podem ter o mesmo Q01)
DROP INDEX IF EXISTS public.idx_questions_questionnaire_code;
CREATE UNIQUE INDEX idx_questions_version_code
  ON public.questions (questionnaire_version_id, lower(code));

CREATE INDEX IF NOT EXISTS idx_questions_version
  ON public.questions (questionnaire_version_id);
CREATE INDEX IF NOT EXISTS idx_questionnaire_responses_version
  ON public.questionnaire_responses (questionnaire_version_id);

-- ═══════════════════════════════════════════════════════════════════════════
-- 4. Triggers de integridade (reforço por versão)
-- ═══════════════════════════════════════════════════════════════════════════

-- Pergunta da resposta deve pertencer à MESMA VERSÃO fixada na resposta
CREATE OR REPLACE FUNCTION public.validate_questionnaire_answer_questionnaire()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_response_questionnaire UUID;
  v_response_version UUID;
  v_question_questionnaire UUID;
  v_question_version UUID;
BEGIN
  SELECT questionnaire_id, questionnaire_version_id
    INTO v_response_questionnaire, v_response_version
  FROM public.questionnaire_responses WHERE id = NEW.response_id;

  SELECT questionnaire_id, questionnaire_version_id
    INTO v_question_questionnaire, v_question_version
  FROM public.questions WHERE id = NEW.question_id;

  IF v_response_questionnaire IS NULL OR v_question_questionnaire IS NULL THEN
    RAISE EXCEPTION 'response_id ou question_id inválido';
  END IF;

  IF v_response_questionnaire <> v_question_questionnaire THEN
    RAISE EXCEPTION 'pergunta deve pertencer ao questionário da resposta';
  END IF;

  IF v_response_version <> v_question_version THEN
    RAISE EXCEPTION 'pergunta deve pertencer à versão respondida do questionário';
  END IF;

  RETURN NEW;
END;
$$;

-- Regra de scoring deve apontar para pergunta da MESMA versão
CREATE OR REPLACE FUNCTION public.validate_question_scoring_rule_refs()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_question_version UUID;
BEGIN
  SELECT questionnaire_version_id INTO v_question_version
  FROM public.questions WHERE id = NEW.question_id;

  IF v_question_version IS NULL THEN
    RAISE EXCEPTION 'question_id inválido';
  END IF;

  IF v_question_version <> NEW.questionnaire_version_id THEN
    RAISE EXCEPTION 'regra de pontuação deve referenciar pergunta da mesma versão';
  END IF;

  RETURN NEW;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 5. Nova RPC: criar versão rascunho de um instrumento publicado
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.admin_create_draft_version(p_questionnaire_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active_version_id uuid;
  v_draft_version_id uuid;
  v_next_version text;
BEGIN
  PERFORM public.assert_platform_admin();

  IF EXISTS (
    SELECT 1 FROM public.questionnaire_versions
    WHERE questionnaire_id = p_questionnaire_id AND status = 'draft'
  ) THEN
    RAISE EXCEPTION 'Já existe uma versão em rascunho para este instrumento'
      USING ERRCODE = '55000';
  END IF;

  SELECT id INTO v_active_version_id
  FROM public.questionnaire_versions
  WHERE questionnaire_id = p_questionnaire_id AND status = 'active'
  FOR UPDATE;
  IF v_active_version_id IS NULL THEN
    RAISE EXCEPTION 'Instrumento não possui versão ativa para versionar'
      USING ERRCODE = 'P0002';
  END IF;

  v_next_version := 'v' || (
    SELECT count(*) + 1 FROM public.questionnaire_versions
    WHERE questionnaire_id = p_questionnaire_id
  )::text;

  INSERT INTO public.questionnaire_versions (
    questionnaire_id, version, status, scoring_method,
    scale_min, scale_max, instructions, reference_period
  )
  SELECT questionnaire_id, v_next_version, 'draft', scoring_method,
         scale_min, scale_max, instructions, reference_period
  FROM public.questionnaire_versions
  WHERE id = v_active_version_id
  RETURNING id INTO v_draft_version_id;

  -- Copia perguntas da versão ativa (ids novos, mesmos códigos)
  WITH copied AS (
    INSERT INTO public.questions (
      questionnaire_id, questionnaire_version_id, code, text, order_index,
      answer_type, scale_min, scale_max, is_active
    )
    SELECT questionnaire_id, v_draft_version_id, code, text, order_index,
           answer_type, scale_min, scale_max, is_active
    FROM public.questions
    WHERE questionnaire_version_id = v_active_version_id
    RETURNING id, code
  ),
  mapping AS (
    SELECT c.id AS new_id, old_q.id AS old_id
    FROM copied c
    JOIN public.questions old_q
      ON old_q.questionnaire_version_id = v_active_version_id
     AND lower(old_q.code) = lower(c.code)
  ),
  copy_items AS (
    -- Vínculos pergunta→categoria (categorias compartilhadas entre versões)
    INSERT INTO public.question_category_items (question_id, category_id, weight)
    SELECT m.new_id, i.category_id, i.weight
    FROM mapping m
    JOIN public.question_category_items i ON i.question_id = m.old_id
    ON CONFLICT (question_id, category_id) DO NOTHING
    RETURNING 1
  )
  INSERT INTO public.question_scoring_rules (
    questionnaire_version_id, question_id, schema_id, domain_id, weight,
    reverse_score, min_value, max_value, sort_order, metadata
  )
  SELECT v_draft_version_id, m.new_id, r.schema_id, r.domain_id, r.weight,
         r.reverse_score, r.min_value, r.max_value, r.sort_order, r.metadata
  FROM mapping m
  JOIN public.question_scoring_rules r
    ON r.questionnaire_version_id = v_active_version_id
   AND r.question_id = m.old_id;

  -- Faixas de severidade acompanham a nova versão
  INSERT INTO public.severity_ranges (
    questionnaire_version_id, schema_id, domain_id, label,
    min_score, max_score, color_key, sort_order, metadata
  )
  SELECT v_draft_version_id, schema_id, domain_id, label,
         min_score, max_score, color_key, sort_order, metadata
  FROM public.severity_ranges
  WHERE questionnaire_version_id = v_active_version_id;

  INSERT INTO public.audit_events (clinic_id, actor_profile_id, action, entity_type, entity_id, metadata)
  VALUES (public.current_clinic_id(), auth.uid(), 'create_draft_version',
          'questionnaires', p_questionnaire_id,
          jsonb_build_object('draft_version_id', v_draft_version_id, 'from_version_id', v_active_version_id));

  RETURN v_draft_version_id;
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 6. RPC: descartar versão rascunho de um publicado
-- ═══════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.admin_discard_draft_version(p_questionnaire_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE v_draft_id uuid;
BEGIN
  PERFORM public.assert_platform_admin();
  SELECT id INTO v_draft_id FROM public.questionnaire_versions
  WHERE questionnaire_id = p_questionnaire_id AND status = 'draft';
  IF v_draft_id IS NULL THEN
    RAISE EXCEPTION 'Nenhuma versão em rascunho para descartar' USING ERRCODE = 'P0002';
  END IF;
  IF EXISTS (
    SELECT 1 FROM public.questionnaire_responses
    WHERE questionnaire_version_id = v_draft_id
  ) THEN
    RAISE EXCEPTION 'Versão rascunho possui respostas e não pode ser descartada'
      USING ERRCODE = '55000';
  END IF;
  -- Cascade remove perguntas copiadas, regras e faixas da versão
  DELETE FROM public.questionnaire_versions WHERE id = v_draft_id;
  INSERT INTO public.audit_events (clinic_id, actor_profile_id, action, entity_type, entity_id, metadata)
  VALUES (public.current_clinic_id(), auth.uid(), 'discard_draft_version',
          'questionnaires', p_questionnaire_id, jsonb_build_object('version_id', v_draft_id));
END;
$$;

-- ═══════════════════════════════════════════════════════════════════════════
-- 7. RPCs existentes adaptadas ao versionamento
-- ═══════════════════════════════════════════════════════════════════════════

-- Editável = existe versão draft (instrumento novo OU nova versão de publicado)
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
  SELECT id INTO v_version_id FROM public.questionnaire_versions
  WHERE questionnaire_id = p_questionnaire_id AND status = 'draft'
  ORDER BY created_at DESC LIMIT 1;
  IF v_version_id IS NULL THEN
    RAISE EXCEPTION 'Crie uma nova versão para editar um instrumento publicado'
      USING ERRCODE = '55000';
  END IF;
  IF trim(COALESCE(p_code,'')) = '' OR trim(COALESCE(p_text,'')) = '' OR p_order_index < 0 OR p_weight <= 0 OR p_scale_min > p_scale_max THEN
    RAISE EXCEPTION 'Invalid question data' USING ERRCODE = '22023';
  END IF;
  IF p_question_id IS NULL THEN
    INSERT INTO public.questions (questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max)
    VALUES (p_questionnaire_id, v_version_id, upper(trim(p_code)), trim(p_text), p_order_index, p_answer_type, p_scale_min, p_scale_max)
    RETURNING id INTO v_id;
  ELSE
    UPDATE public.questions SET code = upper(trim(p_code)), text = trim(p_text),
      order_index = p_order_index, answer_type = p_answer_type,
      scale_min = p_scale_min, scale_max = p_scale_max, updated_at = timezone('utc', now())
    WHERE id = p_question_id
      AND questionnaire_id = p_questionnaire_id
      AND questionnaire_version_id = v_version_id
    RETURNING id INTO v_id;
    IF v_id IS NULL THEN
      RAISE EXCEPTION 'Pergunta não pertence à versão em edição' USING ERRCODE = 'P0002';
    END IF;
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
DECLARE v_version_id uuid;
BEGIN
  PERFORM public.assert_platform_admin();
  SELECT id INTO v_version_id FROM public.questionnaire_versions
  WHERE questionnaire_id = p_questionnaire_id AND status = 'draft'
  ORDER BY created_at DESC LIMIT 1;
  IF v_version_id IS NULL THEN
    RAISE EXCEPTION 'Crie uma nova versão para editar um instrumento publicado'
      USING ERRCODE = '55000';
  END IF;
  DELETE FROM public.questions
  WHERE id = p_question_id
    AND questionnaire_id = p_questionnaire_id
    AND questionnaire_version_id = v_version_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Question not found' USING ERRCODE = 'P0002'; END IF;
END;
$$;

-- Publicação: primeira publicação OU troca de versão (archiva a ativa)
CREATE OR REPLACE FUNCTION public.admin_publish_questionnaire(p_questionnaire_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_draft_version_id uuid;
  v_active_version_id uuid;
  v_question_count integer;
  v_rule_count integer;
BEGIN
  PERFORM public.assert_platform_admin();

  SELECT id INTO v_draft_version_id FROM public.questionnaire_versions
  WHERE questionnaire_id = p_questionnaire_id AND status = 'draft'
  ORDER BY created_at DESC LIMIT 1 FOR UPDATE;
  IF v_draft_version_id IS NULL THEN
    RAISE EXCEPTION 'Editable draft not found' USING ERRCODE = 'P0002';
  END IF;

  SELECT count(*) INTO v_question_count FROM public.questions
  WHERE questionnaire_version_id = v_draft_version_id AND is_active;
  SELECT count(*) INTO v_rule_count FROM public.question_scoring_rules
  WHERE questionnaire_version_id = v_draft_version_id;
  IF v_question_count = 0 OR v_rule_count <> v_question_count THEN
    RAISE EXCEPTION 'Every questionnaire needs questions with scoring rules' USING ERRCODE = '23514';
  END IF;

  -- Arquiva a versão ativa anterior, se houver (republicação)
  SELECT id INTO v_active_version_id FROM public.questionnaire_versions
  WHERE questionnaire_id = p_questionnaire_id AND status = 'active'
  FOR UPDATE;
  IF v_active_version_id IS NOT NULL THEN
    UPDATE public.questionnaire_versions
    SET status = 'archived', updated_at = timezone('utc', now())
    WHERE id = v_active_version_id;
  END IF;

  UPDATE public.questionnaire_versions
  SET status = 'active', published_at = timezone('utc', now()),
      updated_at = timezone('utc', now())
  WHERE id = v_draft_version_id;

  UPDATE public.questionnaires SET is_active = true, clinical_status = 'approved',
    clinically_approved_at = timezone('utc', now()), clinically_approved_by = auth.uid(),
    updated_at = timezone('utc', now())
  WHERE id = p_questionnaire_id;

  INSERT INTO public.audit_events (clinic_id, actor_profile_id, action, entity_type, entity_id, metadata)
  VALUES (public.current_clinic_id(), auth.uid(),
          CASE WHEN v_active_version_id IS NULL THEN 'publish' ELSE 'publish_version' END,
          'questionnaires', p_questionnaire_id,
          jsonb_build_object('version_id', v_draft_version_id, 'archived_version_id', v_active_version_id));
END;
$$;

-- Detalhe: retorna a versão DRAFT quando existir (é a editável), senão a ativa;
-- perguntas filtradas pela versão retornada; flags para a UI.
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
    'has_draft_version', (v.status = 'draft'),
    'active_version', (
      SELECT av.version FROM public.questionnaire_versions av
      WHERE av.questionnaire_id = q.id AND av.status = 'active'
    ),
    'questions', COALESCE((
      SELECT jsonb_agg(to_jsonb(qu) || jsonb_build_object(
        'weight', COALESCE(sr.weight, 1),
        'reverse_score', COALESCE(sr.reverse_score, false)
      ) ORDER BY qu.order_index)
      FROM public.questions qu
      LEFT JOIN public.question_scoring_rules sr
        ON sr.question_id = qu.id AND sr.questionnaire_version_id = v.id
      WHERE qu.questionnaire_version_id = v.id
    ), '[]'::jsonb)
  ) INTO v_result
  FROM public.questionnaires q
  LEFT JOIN LATERAL (
    SELECT qv.* FROM public.questionnaire_versions qv
    WHERE qv.questionnaire_id = q.id
    ORDER BY (qv.status = 'draft') DESC, (qv.status = 'active') DESC, qv.created_at DESC
    LIMIT 1
  ) v ON true
  WHERE q.id = p_questionnaire_id;
  IF v_result IS NULL THEN RAISE EXCEPTION 'Questionnaire not found' USING ERRCODE = 'P0002'; END IF;
  RETURN v_result;
END;
$$;

-- Duplicar (fork para novo instrumento): perguntas copiadas ganham a versão nova
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
    INSERT INTO public.questions (questionnaire_id,questionnaire_version_id,code,text,order_index,answer_type,scale_min,scale_max,is_active)
    SELECT v_new_id, v_new_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active
    FROM public.questions WHERE questionnaire_version_id = v_old_version_id
    RETURNING id, code
  )
  INSERT INTO public.question_scoring_rules (questionnaire_version_id,question_id,weight,reverse_score,min_value,max_value,sort_order,metadata)
  SELECT v_new_version_id, c.id, r.weight, r.reverse_score, r.min_value, r.max_value, r.sort_order, r.metadata
  FROM copied c
  JOIN public.questions old_q ON old_q.questionnaire_version_id = v_old_version_id AND lower(old_q.code) = lower(c.code)
  LEFT JOIN public.question_scoring_rules r ON r.questionnaire_version_id = v_old_version_id AND r.question_id = old_q.id
  WHERE r.id IS NOT NULL;
  RETURN v_new_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.admin_create_draft_version(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_discard_draft_version(uuid) TO authenticated;
