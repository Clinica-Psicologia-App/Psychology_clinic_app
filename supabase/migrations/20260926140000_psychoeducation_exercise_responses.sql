-- Respostas dos pacientes aos exercícios interativos da Fase 2
CREATE TABLE public.psychoeducation_exercise_responses (
  id          UUID        DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id  UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  module_id   UUID        NOT NULL REFERENCES public.psychoeducation_modules(id) ON DELETE CASCADE,
  responses   JSONB       NOT NULL DEFAULT '{}',
  difficulty_scale TEXT,
  wants_to_talk    BOOLEAN,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (patient_id, module_id)
);

ALTER TABLE public.psychoeducation_exercise_responses ENABLE ROW LEVEL SECURITY;

-- Paciente acessa somente as próprias respostas
CREATE POLICY "patient_own_exercise_responses"
  ON public.psychoeducation_exercise_responses
  FOR ALL
  USING (patient_id = auth.uid())
  WITH CHECK (patient_id = auth.uid());

-- Staff (psicólogo / admin) pode visualizar respostas dos pacientes que gerencia
CREATE POLICY "staff_view_exercise_responses"
  ON public.psychoeducation_exercise_responses
  FOR SELECT
  USING (is_staff() AND user_can_access_patient(patient_id));
