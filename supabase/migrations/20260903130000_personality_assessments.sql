-- Módulo Avaliação → Personalidade (camada terapeuta).
--
-- Registra RESULTADOS de instrumentos de personalidade já aplicados/corrigidos
-- fora do app (começando pelo NEO PI-R / Big Five). O app NÃO contém itens,
-- chave de correção, normas nem conversões — apenas organiza o que o
-- profissional informou. Um paciente pode ter várias avaliações (reteste ou
-- instrumentos diferentes), por isso patient_id NÃO é único.
--
-- `results` é JSONB para ser genérico entre instrumentos (o catálogo de
-- domínios/facetas vive no app):
--   { "domains": { "<domain_code>": {
--       "score": <num|null>, "classification": "<very_low..very_high|null>",
--       "facets": { "<facet_code>": { "score":…, "classification":… } } } } }
--
-- Acesso: exclusivo do STAFF com acesso ao paciente. Compartilhamento com o
-- paciente é opt-in explícito (shared_with_patient) — tratado em fase futura.

CREATE TABLE public.personality_assessments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id     UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id    UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  created_by    UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  updated_by    UUID REFERENCES public.profiles (id) ON DELETE SET NULL,

  instrument        TEXT NOT NULL DEFAULT 'NEO_PI_R',
  applied_on        DATE,
  application_form  TEXT,
  -- 'appropriate' | 'invalidated' | 'caution' | NULL
  protocol_validity TEXT,

  results JSONB NOT NULL DEFAULT '{}'::jsonb,

  -- Reservados para fases seguintes (síntese clínica e integração):
  clinical_synthesis            JSONB NOT NULL DEFAULT '{}'::jsonb,
  conceptualization_integration JSONB NOT NULL DEFAULT '{}'::jsonb,
  shared_with_patient           BOOLEAN NOT NULL DEFAULT false,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT personality_assessments_protocol_validity_valid
    CHECK (protocol_validity IS NULL
           OR protocol_validity IN ('appropriate', 'invalidated', 'caution'))
);

COMMENT ON TABLE public.personality_assessments IS
  'Resultados de instrumentos de personalidade (NEO PI-R etc.) informados pelo '
  'terapeuta. O app não aplica/corrige o teste — só organiza o resultado. '
  'Acesso restrito ao staff.';

CREATE INDEX idx_personality_assessments_clinic_id
  ON public.personality_assessments (clinic_id);
CREATE INDEX idx_personality_assessments_patient_id
  ON public.personality_assessments (patient_id);

CREATE TRIGGER trg_personality_assessments_set_updated_at
  BEFORE UPDATE ON public.personality_assessments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Garante que o paciente pertence à clínica informada.
CREATE OR REPLACE FUNCTION public.validate_personality_assessment_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic
  FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id da avaliação';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_personality_assessments_validate_clinic
  BEFORE INSERT OR UPDATE ON public.personality_assessments
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_personality_assessment_clinic();

-- ── RLS: somente staff com acesso ao paciente ──────────────────────────────
ALTER TABLE public.personality_assessments ENABLE ROW LEVEL SECURITY;

CREATE POLICY personality_assessments_select
  ON public.personality_assessments
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY personality_assessments_insert
  ON public.personality_assessments
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
    AND (created_by IS NULL OR created_by = auth.uid())
  );

CREATE POLICY personality_assessments_update
  ON public.personality_assessments
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY personality_assessments_delete
  ON public.personality_assessments
  FOR DELETE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  );
