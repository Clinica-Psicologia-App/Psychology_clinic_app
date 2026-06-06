-- =============================================================================
-- Migration 022 (FH-03): catálogo de questionários + acesso por profissional
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Metadados clínicos no catálogo de questionários
-- -----------------------------------------------------------------------------

ALTER TABLE public.questionnaires
  ADD COLUMN IF NOT EXISTS author_name TEXT,
  ADD COLUMN IF NOT EXISTS instrument_version TEXT,
  ADD COLUMN IF NOT EXISTS citation TEXT,
  ADD COLUMN IF NOT EXISTS license_notes TEXT;

COMMENT ON COLUMN public.questionnaires.author_name IS
  'Autor ou autores do instrumento clínico.';

COMMENT ON COLUMN public.questionnaires.instrument_version IS
  'Versão pública ou clínica do instrumento exibida no catálogo.';

COMMENT ON COLUMN public.questionnaires.citation IS
  'Referência bibliográfica, manual ou fonte institucional do instrumento.';

COMMENT ON COLUMN public.questionnaires.license_notes IS
  'Observações internas sobre licenciamento, uso clínico ou validação.';

-- -----------------------------------------------------------------------------
-- 2. Acesso de questionários por profissional
-- -----------------------------------------------------------------------------

CREATE TABLE public.questionnaire_professional_access (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id        UUID NOT NULL REFERENCES public.clinics (id) ON DELETE CASCADE,
  questionnaire_id UUID NOT NULL REFERENCES public.questionnaires (id) ON DELETE CASCADE,
  professional_id  UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  granted_by       UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  is_enabled       BOOLEAN NOT NULL DEFAULT true,
  granted_at       TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  revoked_at       TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT questionnaire_professional_access_unique
    UNIQUE (questionnaire_id, professional_id)
);

COMMENT ON TABLE public.questionnaire_professional_access IS
  'Liberação de instrumentos por profissional dentro da clínica.';

COMMENT ON COLUMN public.questionnaire_professional_access.granted_by IS
  'Perfil que habilitou ou revisou o acesso ao instrumento.';

COMMENT ON COLUMN public.questionnaire_professional_access.is_enabled IS
  'Indica se o profissional pode aplicar/ver o instrumento no catálogo.';

CREATE INDEX idx_questionnaire_professional_access_clinic_id
  ON public.questionnaire_professional_access (clinic_id);

CREATE INDEX idx_questionnaire_professional_access_professional_id
  ON public.questionnaire_professional_access (professional_id);

CREATE INDEX idx_questionnaire_professional_access_questionnaire_id
  ON public.questionnaire_professional_access (questionnaire_id);

CREATE INDEX idx_questionnaire_professional_access_is_enabled
  ON public.questionnaire_professional_access (is_enabled);

CREATE OR REPLACE FUNCTION public.validate_questionnaire_professional_access()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_professional_role public.profile_role;
  v_professional_clinic UUID;
  v_granted_by_clinic UUID;
BEGIN
  SELECT role, clinic_id
    INTO v_professional_role, v_professional_clinic
  FROM public.profiles
  WHERE id = NEW.professional_id;

  IF v_professional_role IS NULL THEN
    RAISE EXCEPTION 'professional_id inválido para questionnaire_professional_access';
  END IF;

  IF v_professional_role NOT IN ('admin', 'psychologist') THEN
    RAISE EXCEPTION 'professional_id deve referenciar perfil admin ou psychologist';
  END IF;

  IF v_professional_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'clinic_id deve coincidir com a clínica do profissional';
  END IF;

  IF NEW.granted_by IS NOT NULL THEN
    SELECT clinic_id
      INTO v_granted_by_clinic
    FROM public.profiles
    WHERE id = NEW.granted_by;

    IF v_granted_by_clinic IS NULL THEN
      RAISE EXCEPTION 'granted_by inválido para questionnaire_professional_access';
    END IF;

    IF v_granted_by_clinic <> NEW.clinic_id THEN
      RAISE EXCEPTION 'granted_by deve pertencer à mesma clínica do acesso';
    END IF;
  END IF;

  IF NEW.is_enabled THEN
    NEW.revoked_at := NULL;
  ELSIF NEW.revoked_at IS NULL THEN
    NEW.revoked_at := timezone('utc', now());
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_questionnaire_professional_access_set_updated_at
  BEFORE UPDATE ON public.questionnaire_professional_access
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_questionnaire_professional_access_validate
  BEFORE INSERT OR UPDATE ON public.questionnaire_professional_access
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_questionnaire_professional_access();

-- -----------------------------------------------------------------------------
-- 3. RLS
-- -----------------------------------------------------------------------------

ALTER TABLE public.questionnaire_professional_access ENABLE ROW LEVEL SECURITY;

CREATE POLICY questionnaire_professional_access_select_admin
  ON public.questionnaire_professional_access
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY questionnaire_professional_access_select_own_psychologist
  ON public.questionnaire_professional_access
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'psychologist'
    AND professional_id = auth.uid()
  );

CREATE POLICY questionnaire_professional_access_insert_admin
  ON public.questionnaire_professional_access
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY questionnaire_professional_access_update_admin
  ON public.questionnaire_professional_access
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY questionnaire_professional_access_delete_admin
  ON public.questionnaire_professional_access
  FOR DELETE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );
