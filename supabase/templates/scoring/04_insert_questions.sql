-- =============================================================================
-- Template 04: questions
-- Pré-requisito: questionnaire (03_insert_questionnaire.sql)
-- Texto do item = redação clínica aprovada (não usar texto deste template em produção).
-- =============================================================================
--
-- Placeholders:
--   {{QUESTION_ID}}       UUID fixo da pergunta
--   {{QUESTIONNAIRE_ID}}  UUID do questionário pai
-- =============================================================================

INSERT INTO public.questions (
  id,
  questionnaire_id,
  code,
  text,
  order_index,
  answer_type,
  scale_min,
  scale_max,
  is_active
)
VALUES (
  '{{QUESTION_ID}}'::uuid,
  '{{QUESTIONNAIRE_ID}}'::uuid,
  '{{QUESTION_CODE}}',       -- ex.: YSQ_01 ou código interno único no questionário
  '{{QUESTION_TEXT}}',       -- enunciado oficial validado
  {{QUESTION_ORDER_INDEX}},  -- 0, 1, 2, ...
  '{{QUESTION_ANSWER_TYPE}}'::public.question_answer_type,  -- likert_scale | numeric_scale | single_choice | text
  {{QUESTION_SCALE_MIN}},    -- NULL se não aplicável
  {{QUESTION_SCALE_MAX}},
  true
)
ON CONFLICT (id) DO NOTHING;

-- Repita um INSERT por item do instrumento.
