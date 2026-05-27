-- =============================================================================
-- Migration 005: respostas, itens respondidos e resultados calculados
-- =============================================================================

-- -----------------------------------------------------------------------------
-- questionnaire_responses — sessão de aplicação de um questionário
-- -----------------------------------------------------------------------------

CREATE TABLE public.questionnaire_responses (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id         UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id        UUID NOT NULL REFERENCES public.patients (id) ON DELETE RESTRICT,
  questionnaire_id  UUID NOT NULL REFERENCES public.questionnaires (id) ON DELETE RESTRICT,
  status            public.questionnaire_response_status NOT NULL DEFAULT 'draft',
  started_at        TIMESTAMPTZ,
  completed_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT questionnaire_responses_completed_at_when_completed CHECK (
    status <> 'completed'
    OR completed_at IS NOT NULL
  )
);

COMMENT ON TABLE public.questionnaire_responses IS
  'Instância de aplicação de questionário por paciente. Agrupa respostas e resultados.';

COMMENT ON COLUMN public.questionnaire_responses.status IS
  'draft: em andamento; completed: finalizado; cancelled: abandonado.';

CREATE INDEX idx_questionnaire_responses_clinic_id
  ON public.questionnaire_responses (clinic_id);

CREATE INDEX idx_questionnaire_responses_patient_id
  ON public.questionnaire_responses (patient_id);

CREATE INDEX idx_questionnaire_responses_questionnaire_id
  ON public.questionnaire_responses (questionnaire_id);

CREATE INDEX idx_questionnaire_responses_clinic_patient
  ON public.questionnaire_responses (clinic_id, patient_id);

CREATE INDEX idx_questionnaire_responses_status
  ON public.questionnaire_responses (status);

-- -----------------------------------------------------------------------------
-- questionnaire_answers — valor respondido por pergunta
-- -----------------------------------------------------------------------------

CREATE TABLE public.questionnaire_answers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  response_id   UUID NOT NULL REFERENCES public.questionnaire_responses (id) ON DELETE CASCADE,
  question_id   UUID NOT NULL REFERENCES public.questions (id) ON DELETE RESTRICT,
  answer_value  NUMERIC(12, 4),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.questionnaire_answers IS
  'Resposta individual. answer_value numérico no MVP; textos futuros podem exigir coluna adicional.';

COMMENT ON COLUMN public.questionnaire_answers.answer_value IS
  'Valor da resposta (ex.: 1–6 em Likert). Motor de apuração consumirá este campo.';

CREATE INDEX idx_questionnaire_answers_response_id
  ON public.questionnaire_answers (response_id);

CREATE INDEX idx_questionnaire_answers_question_id
  ON public.questionnaire_answers (question_id);

CREATE UNIQUE INDEX idx_questionnaire_answers_response_question
  ON public.questionnaire_answers (response_id, question_id);

-- -----------------------------------------------------------------------------
-- questionnaire_results — scores por categoria após apuração (preenchido depois)
-- -----------------------------------------------------------------------------

CREATE TABLE public.questionnaire_results (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  response_id       UUID NOT NULL REFERENCES public.questionnaire_responses (id) ON DELETE CASCADE,
  questionnaire_id  UUID NOT NULL REFERENCES public.questionnaires (id) ON DELETE RESTRICT,
  category_id       UUID NOT NULL REFERENCES public.question_categories (id) ON DELETE RESTRICT,
  total_score       NUMERIC(12, 4),
  average_score     NUMERIC(12, 4),
  percentage        NUMERIC(7, 4),
  classification    TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT questionnaire_results_percentage_range CHECK (
    percentage IS NULL
    OR (percentage >= 0 AND percentage <= 100)
  )
);

COMMENT ON TABLE public.questionnaire_results IS
  'Resultado calculado por categoria. Populado pelo motor de apuração ao concluir response (não implementado nesta etapa).';

COMMENT ON COLUMN public.questionnaire_results.classification IS
  'Rótulo interpretativo (ex.: elevado, moderado). Regras definidas no motor futuro.';

CREATE INDEX idx_questionnaire_results_response_id
  ON public.questionnaire_results (response_id);

CREATE INDEX idx_questionnaire_results_questionnaire_id
  ON public.questionnaire_results (questionnaire_id);

CREATE INDEX idx_questionnaire_results_category_id
  ON public.questionnaire_results (category_id);

CREATE UNIQUE INDEX idx_questionnaire_results_response_category
  ON public.questionnaire_results (response_id, category_id);
