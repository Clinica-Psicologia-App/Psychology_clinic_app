-- Ensure custom questionnaires always produce at least one persisted result.

CREATE OR REPLACE FUNCTION public.ensure_draft_questionnaire_total_category()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF NEW.clinical_status IN ('draft', 'validation') THEN
    INSERT INTO public.question_categories (
      questionnaire_id,
      code,
      name,
      description
    )
    VALUES (
      NEW.id,
      'TOTAL',
      'Resultado total',
      'Pontuação agregada de todas as perguntas do instrumento.'
    )
    ON CONFLICT (questionnaire_id, lower(code)) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_questionnaires_ensure_total_category
  ON public.questionnaires;
CREATE TRIGGER trg_questionnaires_ensure_total_category
  AFTER INSERT OR UPDATE OF clinical_status ON public.questionnaires
  FOR EACH ROW
  EXECUTE FUNCTION public.ensure_draft_questionnaire_total_category();

CREATE OR REPLACE FUNCTION public.ensure_draft_question_total_category_item()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_category_id uuid;
BEGIN
  SELECT qc.id INTO v_category_id
  FROM public.question_categories qc
  JOIN public.questionnaires q ON q.id = qc.questionnaire_id
  WHERE qc.questionnaire_id = NEW.questionnaire_id
    AND lower(qc.code) = 'total'
    AND q.clinical_status IN ('draft', 'validation')
  LIMIT 1;

  IF v_category_id IS NOT NULL THEN
    INSERT INTO public.question_category_items (question_id, category_id, weight)
    VALUES (NEW.id, v_category_id, 1)
    ON CONFLICT (question_id, category_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_questions_ensure_total_category_item
  ON public.questions;
CREATE TRIGGER trg_questions_ensure_total_category_item
  AFTER INSERT OR UPDATE OF questionnaire_id ON public.questions
  FOR EACH ROW
  EXECUTE FUNCTION public.ensure_draft_question_total_category_item();

INSERT INTO public.question_categories (
  questionnaire_id,
  code,
  name,
  description
)
SELECT q.id, 'TOTAL', 'Resultado total',
       'Pontuação agregada de todas as perguntas do instrumento.'
FROM public.questionnaires q
WHERE q.clinical_status IN ('draft', 'validation')
  AND NOT EXISTS (
    SELECT 1 FROM public.question_categories qc
    WHERE qc.questionnaire_id = q.id AND lower(qc.code) = 'total'
  );

INSERT INTO public.question_category_items (question_id, category_id, weight)
SELECT qu.id, qc.id, 1
FROM public.questions qu
JOIN public.questionnaires q ON q.id = qu.questionnaire_id
JOIN public.question_categories qc
  ON qc.questionnaire_id = q.id AND lower(qc.code) = 'total'
WHERE q.clinical_status IN ('draft', 'validation')
ON CONFLICT (question_id, category_id) DO NOTHING;
