-- Conceitualização de caso (módulo Síntese) — campos preenchidos pelo terapeuta
-- que não têm origem em outros módulos: necessidades não atendidas (7.2),
-- sequência de modos (10) e relação terapêutica (11).
--
-- Um documento por paciente (uma linha). As seções são JSONB porque é um
-- formulário editado em bloco (poucas linhas por paciente) e os campos podem
-- evoluir sem nova migração. As demais seções da síntese vêm da agregação do
-- Mapa mental e NÃO são armazenadas aqui.
--
-- Acesso: exclusivo do STAFF com acesso ao paciente (é a conceitualização do
-- terapeuta). O paciente NÃO vê esta tabela.

CREATE TABLE public.case_conceptualizations (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id  UUID NOT NULL UNIQUE REFERENCES public.patients (id) ON DELETE CASCADE,
  updated_by  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,

  -- 7.2 — 9 necessidades essenciais (chaves fixas no app):
  --   [{ need_key, rating, origin, schemas }]  (rating: 0–5 ou 'X')
  unmet_needs               JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- 10 — até 3 sequências:
  --   [{ trigger, activated_modes, coping_mode, sequence, effect, perpetuation }]
  mode_sequences            JSONB NOT NULL DEFAULT '[]'::jsonb,

  -- 11 — relação terapêutica:
  --   { collaboration_rating, collaboration_notes, bond_rating, bond_notes,
  --     therapist_reactions }  (ratings 1–5)
  therapeutic_relationship  JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.case_conceptualizations IS
  'Conceitualização de caso (Síntese): campos do terapeuta (necessidades não '
  'atendidas, sequência de modos, relação terapêutica). Um por paciente. '
  'Acesso restrito ao staff.';

CREATE INDEX idx_case_conceptualizations_clinic_id
  ON public.case_conceptualizations (clinic_id);

CREATE TRIGGER trg_case_conceptualizations_set_updated_at
  BEFORE UPDATE ON public.case_conceptualizations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Garante que o paciente pertence à clínica informada.
CREATE OR REPLACE FUNCTION public.validate_case_conceptualization_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic
  FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id da conceitualização';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_case_conceptualizations_validate_clinic
  BEFORE INSERT OR UPDATE ON public.case_conceptualizations
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_case_conceptualization_clinic();

-- ── RLS: somente staff com acesso ao paciente ──────────────────────────────
ALTER TABLE public.case_conceptualizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY case_conceptualizations_select
  ON public.case_conceptualizations
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY case_conceptualizations_insert
  ON public.case_conceptualizations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
    AND (updated_by IS NULL OR updated_by = auth.uid())
  );

CREATE POLICY case_conceptualizations_update
  ON public.case_conceptualizations
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

CREATE POLICY case_conceptualizations_delete
  ON public.case_conceptualizations
  FOR DELETE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND public.user_can_access_patient(patient_id)
  );
