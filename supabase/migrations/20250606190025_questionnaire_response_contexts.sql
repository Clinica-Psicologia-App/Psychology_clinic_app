-- =============================================================================
-- Migration 025 (FH-04): contexts múltiplos por response de questionário
-- =============================================================================

CREATE TABLE public.questionnaire_response_contexts (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id         UUID NOT NULL REFERENCES public.clinics (id) ON DELETE CASCADE,
  response_id       UUID NOT NULL REFERENCES public.questionnaire_responses (id) ON DELETE CASCADE,
  patient_id        UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  questionnaire_id  UUID NOT NULL REFERENCES public.questionnaires (id) ON DELETE CASCADE,
  context_type      TEXT NOT NULL,
  context_key       TEXT NOT NULL,
  context_label     TEXT NOT NULL,
  sort_order        INTEGER NOT NULL DEFAULT 0,
  status            TEXT NOT NULL DEFAULT 'draft',
  completed_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT questionnaire_response_contexts_status_check
    CHECK (status IN ('draft', 'completed')),
  CONSTRAINT questionnaire_response_contexts_parental_type_check
    CHECK (context_type = 'parental_figure'),
  CONSTRAINT questionnaire_response_contexts_parental_key_check
    CHECK (context_key IN ('mother', 'father', 'other')),
  CONSTRAINT questionnaire_response_contexts_other_label_check
    CHECK (
      context_key <> 'other'
      OR (
        NULLIF(trim(context_label), '') IS NOT NULL
        AND lower(trim(context_label)) <> 'outro'
      )
    ),
  CONSTRAINT questionnaire_response_contexts_completed_at_when_completed_check
    CHECK (
      status <> 'completed'
      OR completed_at IS NOT NULL
    ),
  CONSTRAINT questionnaire_response_contexts_unique
    UNIQUE (response_id, context_type, context_key, context_label)
);

COMMENT ON TABLE public.questionnaire_response_contexts IS
  'Contextos múltiplos de resposta para um mesmo questionnaire_response, como figuras parentais.';

COMMENT ON COLUMN public.questionnaire_response_contexts.context_key IS
  'Chave controlada do contexto. No FH-04: mother, father, other.';

ALTER TABLE public.questionnaire_answers
  ADD COLUMN IF NOT EXISTS response_context_id UUID NULL
  REFERENCES public.questionnaire_response_contexts (id) ON DELETE CASCADE;

COMMENT ON COLUMN public.questionnaire_answers.response_context_id IS
  'Contexto opcional da resposta. Ex.: figura parental em PARENTAL_STYLES_V1.';

DROP INDEX IF EXISTS idx_questionnaire_answers_response_question;

CREATE UNIQUE INDEX idx_questionnaire_answers_response_question_without_context
  ON public.questionnaire_answers (response_id, question_id)
  WHERE response_context_id IS NULL;

CREATE UNIQUE INDEX idx_questionnaire_answers_response_question_with_context
  ON public.questionnaire_answers (response_id, question_id, response_context_id)
  WHERE response_context_id IS NOT NULL;

CREATE INDEX idx_questionnaire_answers_response_context_id
  ON public.questionnaire_answers (response_context_id);

CREATE INDEX idx_questionnaire_response_contexts_clinic_id
  ON public.questionnaire_response_contexts (clinic_id);

CREATE INDEX idx_questionnaire_response_contexts_response_id
  ON public.questionnaire_response_contexts (response_id);

CREATE INDEX idx_questionnaire_response_contexts_patient_id
  ON public.questionnaire_response_contexts (patient_id);

CREATE INDEX idx_questionnaire_response_contexts_questionnaire_id
  ON public.questionnaire_response_contexts (questionnaire_id);

CREATE INDEX idx_questionnaire_response_contexts_status
  ON public.questionnaire_response_contexts (status);

CREATE OR REPLACE FUNCTION public.validate_questionnaire_response_context()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_response RECORD;
BEGIN
  SELECT qr.clinic_id, qr.patient_id, qr.questionnaire_id
    INTO v_response
  FROM public.questionnaire_responses AS qr
  WHERE qr.id = NEW.response_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'response_id inválido para questionnaire_response_contexts';
  END IF;

  IF NEW.clinic_id <> v_response.clinic_id THEN
    RAISE EXCEPTION 'clinic_id do contexto deve coincidir com questionnaire_responses';
  END IF;

  IF NEW.patient_id <> v_response.patient_id THEN
    RAISE EXCEPTION 'patient_id do contexto deve coincidir com questionnaire_responses';
  END IF;

  IF NEW.questionnaire_id <> v_response.questionnaire_id THEN
    RAISE EXCEPTION 'questionnaire_id do contexto deve coincidir com questionnaire_responses';
  END IF;

  IF NEW.status = 'completed' AND NEW.completed_at IS NULL THEN
    NEW.completed_at := timezone('utc', now());
  ELSIF NEW.status = 'draft' THEN
    NEW.completed_at := NULL;
  END IF;

  NEW.context_label := trim(NEW.context_label);
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.validate_questionnaire_answer_context()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_context RECORD;
BEGIN
  IF NEW.response_context_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT qrc.response_id, qrc.patient_id, qrc.questionnaire_id, qrc.clinic_id
    INTO v_context
  FROM public.questionnaire_response_contexts AS qrc
  WHERE qrc.id = NEW.response_context_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'response_context_id inválido para questionnaire_answers';
  END IF;

  IF v_context.response_id <> NEW.response_id THEN
    RAISE EXCEPTION 'response_context_id deve pertencer à mesma response';
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.sync_questionnaire_response_context_completion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_context_id UUID;
  v_questionnaire_id UUID;
  v_answered_count INTEGER;
  v_total_questions INTEGER;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_context_id := OLD.response_context_id;
  ELSE
    v_context_id := NEW.response_context_id;
  END IF;

  IF v_context_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT questionnaire_id
    INTO v_questionnaire_id
  FROM public.questionnaire_response_contexts
  WHERE id = v_context_id;

  IF v_questionnaire_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT COUNT(*)
    INTO v_total_questions
  FROM public.questions
  WHERE questionnaire_id = v_questionnaire_id
    AND is_active = true
    AND code LIKE 'M_%';

  SELECT COUNT(DISTINCT qa.question_id)
    INTO v_answered_count
  FROM public.questionnaire_answers AS qa
  WHERE qa.response_context_id = v_context_id
    AND qa.answer_value IS NOT NULL;

  UPDATE public.questionnaire_response_contexts
  SET status = CASE
      WHEN v_total_questions > 0 AND v_answered_count >= v_total_questions
        THEN 'completed'
      ELSE 'draft'
    END,
      completed_at = CASE
        WHEN v_total_questions > 0 AND v_answered_count >= v_total_questions
          THEN COALESCE(completed_at, timezone('utc', now()))
        ELSE NULL
      END
  WHERE id = v_context_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_questionnaire_response_contexts_set_updated_at
  BEFORE UPDATE ON public.questionnaire_response_contexts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_questionnaire_response_contexts_validate
  BEFORE INSERT OR UPDATE ON public.questionnaire_response_contexts
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_questionnaire_response_context();

CREATE TRIGGER trg_questionnaire_answers_validate_context
  BEFORE INSERT OR UPDATE ON public.questionnaire_answers
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_questionnaire_answer_context();

CREATE TRIGGER trg_questionnaire_answers_sync_context_completion
  AFTER INSERT OR UPDATE OR DELETE ON public.questionnaire_answers
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_questionnaire_response_context_completion();

ALTER TABLE public.questionnaire_response_contexts ENABLE ROW LEVEL SECURITY;

CREATE POLICY questionnaire_response_contexts_select
  ON public.questionnaire_response_contexts
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_response(response_id)
  );

CREATE POLICY questionnaire_response_contexts_insert
  ON public.questionnaire_response_contexts
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_response(response_id)
  );

CREATE POLICY questionnaire_response_contexts_update
  ON public.questionnaire_response_contexts
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_response(response_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_response(response_id)
  );
