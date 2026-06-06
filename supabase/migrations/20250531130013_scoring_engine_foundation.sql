-- =============================================================================
-- Migration 013: fundação do motor clínico (catálogo oficial no Postgres)
-- Fonte de verdade: Supabase. Sem seed. Sem cálculo. Não altera finish-questionnaire.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Enums
-- -----------------------------------------------------------------------------

CREATE TYPE public.questionnaire_version_status AS ENUM (
  'draft',
  'active',
  'archived'
);

COMMENT ON TYPE public.questionnaire_version_status IS
  'Ciclo de vida de uma versão publicada de questionário (regras de pontuação).';

-- -----------------------------------------------------------------------------
-- Helpers RLS — catálogo global (clinic_id NULL) ou da clínica do usuário
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.scoring_row_visible_to_current_clinic(p_row_clinic_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_clinic_id() IS NOT NULL
    AND (
      p_row_clinic_id IS NULL
      OR p_row_clinic_id = public.current_clinic_id()
    );
$$;

COMMENT ON FUNCTION public.scoring_row_visible_to_current_clinic(UUID) IS
  'TRUE se o registro é global (clinic_id NULL) ou pertence à clínica do JWT.';

CREATE OR REPLACE FUNCTION public.scoring_admin_can_manage_row(p_row_clinic_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_role() = 'admin'
    AND (
      (p_row_clinic_id IS NULL)
      OR (p_row_clinic_id = public.current_clinic_id())
    );
$$;

COMMENT ON FUNCTION public.scoring_admin_can_manage_row(UUID) IS
  'Admin pode gerir catálogo global ou da própria clínica.';

-- -----------------------------------------------------------------------------
-- 1. schema_domains — domínios clínicos (Terapia do Esquema)
-- -----------------------------------------------------------------------------

CREATE TABLE public.schema_domains (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   UUID REFERENCES public.clinics (id) ON DELETE CASCADE,
  code        TEXT NOT NULL,
  name        TEXT NOT NULL,
  description TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT schema_domains_code_not_empty CHECK (char_length(trim(code)) > 0),
  CONSTRAINT schema_domains_name_not_empty CHECK (char_length(trim(name)) > 0),
  CONSTRAINT schema_domains_sort_order_non_negative CHECK (sort_order >= 0)
);

COMMENT ON TABLE public.schema_domains IS
  'Domínios clínicos oficiais. clinic_id NULL = catálogo global da plataforma; UUID = extensão/override por clínica.';

COMMENT ON COLUMN public.schema_domains.clinic_id IS
  'NULL = regra global; preenchido = domínio específico da clínica.';

CREATE INDEX idx_schema_domains_clinic_id ON public.schema_domains (clinic_id);
CREATE INDEX idx_schema_domains_is_active ON public.schema_domains (is_active);
CREATE INDEX idx_schema_domains_sort_order ON public.schema_domains (sort_order);

CREATE UNIQUE INDEX idx_schema_domains_code_global
  ON public.schema_domains (lower(code))
  WHERE clinic_id IS NULL;

CREATE UNIQUE INDEX idx_schema_domains_code_clinic
  ON public.schema_domains (clinic_id, lower(code))
  WHERE clinic_id IS NOT NULL;

-- -----------------------------------------------------------------------------
-- 2. schemas — esquemas mal-adaptativos (vinculados a um domínio)
-- -----------------------------------------------------------------------------

CREATE TABLE public.schemas (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_id   UUID NOT NULL REFERENCES public.schema_domains (id) ON DELETE RESTRICT,
  clinic_id   UUID REFERENCES public.clinics (id) ON DELETE CASCADE,
  code        TEXT NOT NULL,
  name        TEXT NOT NULL,
  description TEXT,
  sort_order  INTEGER NOT NULL DEFAULT 0,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT schemas_code_not_empty CHECK (char_length(trim(code)) > 0),
  CONSTRAINT schemas_name_not_empty CHECK (char_length(trim(name)) > 0),
  CONSTRAINT schemas_sort_order_non_negative CHECK (sort_order >= 0)
);

COMMENT ON TABLE public.schemas IS
  'Esquemas clínicos oficiais. clinic_id deve alinhar ao domínio pai (validado por trigger).';

CREATE INDEX idx_schemas_domain_id ON public.schemas (domain_id);
CREATE INDEX idx_schemas_clinic_id ON public.schemas (clinic_id);
CREATE INDEX idx_schemas_is_active ON public.schemas (is_active);
CREATE INDEX idx_schemas_domain_sort ON public.schemas (domain_id, sort_order);

CREATE UNIQUE INDEX idx_schemas_domain_code
  ON public.schemas (domain_id, lower(code));

-- -----------------------------------------------------------------------------
-- 3. questionnaire_versions — versão publicada de um instrumento
-- -----------------------------------------------------------------------------

CREATE TABLE public.questionnaire_versions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_id  UUID NOT NULL REFERENCES public.questionnaires (id) ON DELETE CASCADE,
  version           TEXT NOT NULL,
  status            public.questionnaire_version_status NOT NULL DEFAULT 'draft',
  scoring_method    TEXT,
  scale_min         INTEGER,
  scale_max         INTEGER,
  instructions      TEXT,
  published_at      TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT questionnaire_versions_version_not_empty
    CHECK (char_length(trim(version)) > 0),
  CONSTRAINT questionnaire_versions_scale_range_valid CHECK (
    scale_min IS NULL
    OR scale_max IS NULL
    OR scale_min <= scale_max
  ),
  CONSTRAINT questionnaire_versions_published_when_active CHECK (
    status <> 'active'
    OR published_at IS NOT NULL
  )
);

COMMENT ON TABLE public.questionnaire_versions IS
  'Versões do questionário com regras de pontuação e instruções. Catálogo global (por questionnaire_id).';

COMMENT ON COLUMN public.questionnaire_versions.scoring_method IS
  'Identificador do método de apuração (ex.: weighted_sum). Motor ainda não implementado.';

CREATE INDEX idx_questionnaire_versions_questionnaire_id
  ON public.questionnaire_versions (questionnaire_id);

CREATE INDEX idx_questionnaire_versions_status
  ON public.questionnaire_versions (status);

CREATE UNIQUE INDEX idx_questionnaire_versions_questionnaire_version
  ON public.questionnaire_versions (questionnaire_id, lower(version));

CREATE UNIQUE INDEX idx_questionnaire_versions_one_active_per_questionnaire
  ON public.questionnaire_versions (questionnaire_id)
  WHERE status = 'active';

-- -----------------------------------------------------------------------------
-- 4. question_scoring_rules — regra por pergunta em uma versão
-- -----------------------------------------------------------------------------

CREATE TABLE public.question_scoring_rules (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_version_id UUID NOT NULL
    REFERENCES public.questionnaire_versions (id) ON DELETE CASCADE,
  question_id             UUID NOT NULL REFERENCES public.questions (id) ON DELETE CASCADE,
  schema_id               UUID REFERENCES public.schemas (id) ON DELETE SET NULL,
  domain_id               UUID REFERENCES public.schema_domains (id) ON DELETE SET NULL,
  weight                  NUMERIC(12, 4) NOT NULL DEFAULT 1,
  reverse_score           BOOLEAN NOT NULL DEFAULT false,
  min_value               NUMERIC(12, 4),
  max_value               NUMERIC(12, 4),
  sort_order              INTEGER NOT NULL DEFAULT 0,
  metadata                JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT question_scoring_rules_weight_positive CHECK (weight > 0),
  CONSTRAINT question_scoring_rules_sort_order_non_negative CHECK (sort_order >= 0),
  CONSTRAINT question_scoring_rules_value_range_valid CHECK (
    min_value IS NULL
    OR max_value IS NULL
    OR min_value <= max_value
  )
);

COMMENT ON TABLE public.question_scoring_rules IS
  'Mapeamento oficial pergunta → esquema/domínio, peso e reverse scoring por versão do instrumento.';

CREATE INDEX idx_question_scoring_rules_version_id
  ON public.question_scoring_rules (questionnaire_version_id);

CREATE INDEX idx_question_scoring_rules_question_id
  ON public.question_scoring_rules (question_id);

CREATE INDEX idx_question_scoring_rules_schema_id
  ON public.question_scoring_rules (schema_id);

CREATE INDEX idx_question_scoring_rules_domain_id
  ON public.question_scoring_rules (domain_id);

CREATE UNIQUE INDEX idx_question_scoring_rules_version_question
  ON public.question_scoring_rules (questionnaire_version_id, question_id);

-- -----------------------------------------------------------------------------
-- 5. severity_ranges — faixas de severidade por versão (e opcional esquema/domínio)
-- -----------------------------------------------------------------------------

CREATE TABLE public.severity_ranges (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_version_id UUID NOT NULL
    REFERENCES public.questionnaire_versions (id) ON DELETE CASCADE,
  schema_id               UUID REFERENCES public.schemas (id) ON DELETE SET NULL,
  domain_id               UUID REFERENCES public.schema_domains (id) ON DELETE SET NULL,
  label                   TEXT NOT NULL,
  min_score               NUMERIC(12, 4),
  max_score               NUMERIC(12, 4),
  color_key               TEXT,
  sort_order              INTEGER NOT NULL DEFAULT 0,
  metadata                JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at              TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT severity_ranges_label_not_empty CHECK (char_length(trim(label)) > 0),
  CONSTRAINT severity_ranges_sort_order_non_negative CHECK (sort_order >= 0),
  CONSTRAINT severity_ranges_score_range_valid CHECK (
    min_score IS NULL
    OR max_score IS NULL
    OR min_score <= max_score
  )
);

COMMENT ON TABLE public.severity_ranges IS
  'Faixas clínicas (ex.: baixo, moderado, alto). Motor de classificação ainda não implementado.';

CREATE INDEX idx_severity_ranges_version_id
  ON public.severity_ranges (questionnaire_version_id);

CREATE INDEX idx_severity_ranges_schema_id
  ON public.severity_ranges (schema_id);

CREATE INDEX idx_severity_ranges_domain_id
  ON public.severity_ranges (domain_id);

CREATE INDEX idx_severity_ranges_version_sort
  ON public.severity_ranges (questionnaire_version_id, sort_order);

-- -----------------------------------------------------------------------------
-- Triggers updated_at
-- -----------------------------------------------------------------------------

CREATE TRIGGER trg_schema_domains_set_updated_at
  BEFORE UPDATE ON public.schema_domains
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_schemas_set_updated_at
  BEFORE UPDATE ON public.schemas
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_questionnaire_versions_set_updated_at
  BEFORE UPDATE ON public.questionnaire_versions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_question_scoring_rules_set_updated_at
  BEFORE UPDATE ON public.question_scoring_rules
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_severity_ranges_set_updated_at
  BEFORE UPDATE ON public.severity_ranges
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Integridade cross-table
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_schemas_clinic_matches_domain()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_domain_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_domain_clinic
  FROM public.schema_domains
  WHERE id = NEW.domain_id;

  IF v_domain_clinic IS NULL THEN
    IF NEW.clinic_id IS NOT NULL THEN
      RAISE EXCEPTION 'domínio global exige schema sem clinic_id';
    END IF;
  ELSIF NEW.clinic_id IS NOT NULL AND NEW.clinic_id <> v_domain_clinic THEN
    RAISE EXCEPTION 'schema.clinic_id deve ser NULL ou igual ao do domínio';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_schemas_validate_clinic_domain
  BEFORE INSERT OR UPDATE ON public.schemas
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_schemas_clinic_matches_domain();

CREATE OR REPLACE FUNCTION public.validate_question_scoring_rule_refs()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_version_questionnaire UUID;
  v_question_questionnaire UUID;
  v_schema_domain UUID;
  v_schema_clinic UUID;
  v_domain_clinic UUID;
BEGIN
  SELECT questionnaire_id INTO v_version_questionnaire
  FROM public.questionnaire_versions
  WHERE id = NEW.questionnaire_version_id;

  SELECT questionnaire_id INTO v_question_questionnaire
  FROM public.questions
  WHERE id = NEW.question_id;

  IF v_version_questionnaire IS NULL OR v_question_questionnaire IS NULL THEN
    RAISE EXCEPTION 'questionnaire_version_id ou question_id inválido';
  END IF;

  IF v_version_questionnaire <> v_question_questionnaire THEN
    RAISE EXCEPTION 'pergunta deve pertencer ao mesmo questionário da versão';
  END IF;

  IF NEW.schema_id IS NOT NULL THEN
    SELECT domain_id, clinic_id INTO v_schema_domain, v_schema_clinic
    FROM public.schemas
    WHERE id = NEW.schema_id;

    IF v_schema_domain IS NULL THEN
      RAISE EXCEPTION 'schema_id inválido';
    END IF;

    IF NEW.domain_id IS NOT NULL AND NEW.domain_id <> v_schema_domain THEN
      RAISE EXCEPTION 'domain_id deve coincidir com o domínio do schema_id';
    END IF;
  END IF;

  IF NEW.domain_id IS NOT NULL THEN
    SELECT clinic_id INTO v_domain_clinic
    FROM public.schema_domains
    WHERE id = NEW.domain_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_question_scoring_rules_validate_refs
  BEFORE INSERT OR UPDATE ON public.question_scoring_rules
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_question_scoring_rule_refs();

CREATE OR REPLACE FUNCTION public.validate_severity_range_refs()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  v_schema_domain UUID;
BEGIN
  IF NEW.schema_id IS NOT NULL AND NEW.domain_id IS NOT NULL THEN
    SELECT domain_id INTO v_schema_domain
    FROM public.schemas
    WHERE id = NEW.schema_id;

    IF v_schema_domain IS NULL OR v_schema_domain <> NEW.domain_id THEN
      RAISE EXCEPTION 'domain_id deve coincidir com o domínio do schema_id em severity_ranges';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_severity_ranges_validate_refs
  BEFORE INSERT OR UPDATE ON public.severity_ranges
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_severity_range_refs();

-- -----------------------------------------------------------------------------
-- Row Level Security
-- -----------------------------------------------------------------------------

ALTER TABLE public.schema_domains ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.schemas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questionnaire_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_scoring_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.severity_ranges ENABLE ROW LEVEL SECURITY;

-- schema_domains
CREATE POLICY schema_domains_select
  ON public.schema_domains
  FOR SELECT
  TO authenticated
  USING (public.scoring_row_visible_to_current_clinic(clinic_id));

CREATE POLICY schema_domains_insert
  ON public.schema_domains
  FOR INSERT
  TO authenticated
  WITH CHECK (public.scoring_admin_can_manage_row(clinic_id));

CREATE POLICY schema_domains_update
  ON public.schema_domains
  FOR UPDATE
  TO authenticated
  USING (public.scoring_admin_can_manage_row(clinic_id))
  WITH CHECK (public.scoring_admin_can_manage_row(clinic_id));

CREATE POLICY schema_domains_delete
  ON public.schema_domains
  FOR DELETE
  TO authenticated
  USING (public.scoring_admin_can_manage_row(clinic_id));

-- schemas
CREATE POLICY schemas_select
  ON public.schemas
  FOR SELECT
  TO authenticated
  USING (public.scoring_row_visible_to_current_clinic(clinic_id));

CREATE POLICY schemas_insert
  ON public.schemas
  FOR INSERT
  TO authenticated
  WITH CHECK (public.scoring_admin_can_manage_row(clinic_id));

CREATE POLICY schemas_update
  ON public.schemas
  FOR UPDATE
  TO authenticated
  USING (public.scoring_admin_can_manage_row(clinic_id))
  WITH CHECK (public.scoring_admin_can_manage_row(clinic_id));

CREATE POLICY schemas_delete
  ON public.schemas
  FOR DELETE
  TO authenticated
  USING (public.scoring_admin_can_manage_row(clinic_id));

-- questionnaire_versions (global por instrumento; leitura = qualquer usuário autenticado da clínica)
CREATE POLICY questionnaire_versions_select
  ON public.questionnaire_versions
  FOR SELECT
  TO authenticated
  USING (public.current_clinic_id() IS NOT NULL);

CREATE POLICY questionnaire_versions_insert
  ON public.questionnaire_versions
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY questionnaire_versions_update
  ON public.questionnaire_versions
  FOR UPDATE
  TO authenticated
  USING (public.current_role() = 'admin')
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY questionnaire_versions_delete
  ON public.questionnaire_versions
  FOR DELETE
  TO authenticated
  USING (public.current_role() = 'admin');

-- question_scoring_rules
CREATE POLICY question_scoring_rules_select
  ON public.question_scoring_rules
  FOR SELECT
  TO authenticated
  USING (public.current_clinic_id() IS NOT NULL);

CREATE POLICY question_scoring_rules_insert
  ON public.question_scoring_rules
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY question_scoring_rules_update
  ON public.question_scoring_rules
  FOR UPDATE
  TO authenticated
  USING (public.current_role() = 'admin')
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY question_scoring_rules_delete
  ON public.question_scoring_rules
  FOR DELETE
  TO authenticated
  USING (public.current_role() = 'admin');

-- severity_ranges
CREATE POLICY severity_ranges_select
  ON public.severity_ranges
  FOR SELECT
  TO authenticated
  USING (public.current_clinic_id() IS NOT NULL);

CREATE POLICY severity_ranges_insert
  ON public.severity_ranges
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY severity_ranges_update
  ON public.severity_ranges
  FOR UPDATE
  TO authenticated
  USING (public.current_role() = 'admin')
  WITH CHECK (public.current_role() = 'admin');

CREATE POLICY severity_ranges_delete
  ON public.severity_ranges
  FOR DELETE
  TO authenticated
  USING (public.current_role() = 'admin');
