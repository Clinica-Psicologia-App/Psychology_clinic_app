-- Hipóteses para Conceitualização (spec §43) — anotações clínicas do terapeuta
-- sobre um paciente, organizadas por tipo (necessidade emocional, esquema,
-- modo, estilo de enfrentamento, problema atual, observação). São HIPÓTESES,
-- inteiramente escritas pelo terapeuta — o app nunca preenche automaticamente.
-- Campo PRIVADO DA EQUIPE: RLS restrita a staff; o paciente não lê nem escreve.

CREATE TABLE public.clinical_hypotheses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id  UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  author_id   UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  kind        TEXT NOT NULL CHECK (kind IN (
                'emotional_need',
                'schema',
                'mode',
                'coping_style',
                'current_problem',
                'clinical_note'
              )),
  body        TEXT NOT NULL CHECK (length(btrim(body)) > 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.clinical_hypotheses IS
  'Hipóteses de conceitualização do terapeuta por paciente (§43). Campo privado da equipe — o app não preenche automaticamente; RLS impede acesso do paciente.';

CREATE INDEX idx_clinical_hypotheses_clinic_id  ON public.clinical_hypotheses (clinic_id);
CREATE INDEX idx_clinical_hypotheses_patient_id ON public.clinical_hypotheses (patient_id);

CREATE TRIGGER trg_clinical_hypotheses_set_updated_at
  BEFORE UPDATE ON public.clinical_hypotheses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- RLS: SÓ a equipe com acesso ao paciente. O paciente não tem policy alguma.
ALTER TABLE public.clinical_hypotheses ENABLE ROW LEVEL SECURITY;

CREATE POLICY clinical_hypotheses_all
  ON public.clinical_hypotheses
  FOR ALL
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
    AND (author_id IS NULL OR author_id = auth.uid())
  );
