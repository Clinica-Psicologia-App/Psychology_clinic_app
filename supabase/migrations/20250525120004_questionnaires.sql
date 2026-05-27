-- =============================================================================
-- Migration 004: questionários, categorias, perguntas e vínculos de apuração
-- =============================================================================

-- -----------------------------------------------------------------------------
-- questionnaires — instrumentos (ex.: YSQ, SMI); catálogo global no MVP
-- -----------------------------------------------------------------------------

CREATE TABLE public.questionnaires (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        TEXT NOT NULL,
  name        TEXT NOT NULL,
  description TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT questionnaires_code_not_empty CHECK (char_length(trim(code)) > 0),
  CONSTRAINT questionnaires_name_not_empty CHECK (char_length(trim(name)) > 0)
);

COMMENT ON TABLE public.questionnaires IS
  'Catálogo de questionários padronizados. Não é por clínica: mesma definição para todas as clínicas no MVP.';

CREATE UNIQUE INDEX idx_questionnaires_code ON public.questionnaires (lower(code));
CREATE INDEX idx_questionnaires_is_active ON public.questionnaires (is_active);

-- -----------------------------------------------------------------------------
-- question_categories — dimensões/esquemas para apuração e dashboard
-- -----------------------------------------------------------------------------

CREATE TABLE public.question_categories (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_id  UUID NOT NULL REFERENCES public.questionnaires (id) ON DELETE CASCADE,
  code              TEXT NOT NULL,
  name              TEXT NOT NULL,
  description       TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT question_categories_code_not_empty CHECK (char_length(trim(code)) > 0),
  CONSTRAINT question_categories_name_not_empty CHECK (char_length(trim(name)) > 0)
);

COMMENT ON TABLE public.question_categories IS
  'Categorias de apuração (ex.: esquemas, modos). Base para questionnaire_results e dashboard futuro.';

CREATE INDEX idx_question_categories_questionnaire_id
  ON public.question_categories (questionnaire_id);

CREATE UNIQUE INDEX idx_question_categories_questionnaire_code
  ON public.question_categories (questionnaire_id, lower(code));

-- -----------------------------------------------------------------------------
-- questions — itens do questionário
-- -----------------------------------------------------------------------------

CREATE TABLE public.questions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_id  UUID NOT NULL REFERENCES public.questionnaires (id) ON DELETE CASCADE,
  code              TEXT NOT NULL,
  text              TEXT NOT NULL,
  order_index       INTEGER NOT NULL,
  answer_type       public.question_answer_type NOT NULL DEFAULT 'likert_scale',
  scale_min         INTEGER,
  scale_max         INTEGER,
  is_active         BOOLEAN NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT questions_code_not_empty CHECK (char_length(trim(code)) > 0),
  CONSTRAINT questions_text_not_empty CHECK (char_length(trim(text)) > 0),
  CONSTRAINT questions_order_index_non_negative CHECK (order_index >= 0),
  CONSTRAINT questions_scale_range_valid CHECK (
    scale_min IS NULL
    OR scale_max IS NULL
    OR scale_min <= scale_max
  )
);

COMMENT ON TABLE public.questions IS
  'Perguntas de um questionário. scale_min/scale_max aplicam-se a tipos com escala numérica.';

COMMENT ON COLUMN public.questions.order_index IS
  'Ordem de exibição na aplicação do questionário.';

CREATE INDEX idx_questions_questionnaire_id ON public.questions (questionnaire_id);
CREATE INDEX idx_questions_questionnaire_order ON public.questions (questionnaire_id, order_index);

CREATE UNIQUE INDEX idx_questions_questionnaire_code
  ON public.questions (questionnaire_id, lower(code));

-- -----------------------------------------------------------------------------
-- question_category_items — peso da pergunta em cada categoria (motor de apuração)
-- -----------------------------------------------------------------------------

CREATE TABLE public.question_category_items (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES public.questions (id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.question_categories (id) ON DELETE CASCADE,
  weight      NUMERIC(10, 4) NOT NULL DEFAULT 1,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT question_category_items_weight_positive CHECK (weight > 0)
);

COMMENT ON TABLE public.question_category_items IS
  'Associação N:N entre pergunta e categoria com peso. Define como respostas alimentam o cálculo por categoria.';

CREATE INDEX idx_question_category_items_question_id
  ON public.question_category_items (question_id);

CREATE INDEX idx_question_category_items_category_id
  ON public.question_category_items (category_id);

CREATE UNIQUE INDEX idx_question_category_items_question_category
  ON public.question_category_items (question_id, category_id);
