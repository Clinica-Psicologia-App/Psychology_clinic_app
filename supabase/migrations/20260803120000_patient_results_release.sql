-- Liberação de resultados por PACIENTE (substitui o gate por resposta via
-- reviewed_at). O psicólogo valida os esquemas no Dashboard Clínico e, quando
-- pronto, libera TODOS os resultados do paciente numa ação explícita.
--
-- Enquanto patients.results_released_at IS NULL, o paciente não lê
-- questionnaire_results nem os answers de respostas concluídas. Staff sempre vê.

-- 1) Coluna de liberação -------------------------------------------------------
ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS results_released_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS results_released_by UUID
    REFERENCES public.profiles(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.patients.results_released_at IS
  'Quando não nulo, os resultados clínicos ficam visíveis ao paciente.';

-- Backfill: pacientes que já tinham alguma resposta revisada (régua antiga)
-- entram como liberados, para não perderem acesso na virada do modelo.
UPDATE public.patients AS p
SET results_released_at = timezone('utc', now())
WHERE p.results_released_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM public.questionnaire_responses AS qr
    WHERE qr.patient_id = p.id
      AND qr.reviewed_at IS NOT NULL
  );

-- 2) RPC de liberação/revogação (psicólogo responsável) ------------------------
CREATE OR REPLACE FUNCTION public.set_patient_results_released(
  p_patient_id UUID,
  p_released BOOLEAN
)
RETURNS public.patients
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_patient public.patients%ROWTYPE;
BEGIN
  IF public.current_role()::TEXT <> 'psychologist' THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Apenas psicologos podem liberar resultados';
  END IF;

  SELECT *
  INTO v_patient
  FROM public.patients
  WHERE id = p_patient_id
  FOR UPDATE;

  IF NOT FOUND
    OR v_patient.clinic_id IS DISTINCT FROM public.current_clinic_id()
    OR v_patient.responsible_psychologist_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'Paciente nao encontrado ou nao pertence ao psicologo';
  END IF;

  UPDATE public.patients
  SET
    results_released_at = CASE
      WHEN p_released THEN timezone('utc', now())
      ELSE NULL
    END,
    results_released_by = CASE
      WHEN p_released THEN auth.uid()
      ELSE NULL
    END,
    updated_at = timezone('utc', now())
  WHERE id = p_patient_id
  RETURNING * INTO v_patient;

  INSERT INTO public.audit_events (
    clinic_id,
    actor_profile_id,
    action,
    entity_type,
    entity_id,
    patient_id,
    metadata
  )
  VALUES (
    v_patient.clinic_id,
    auth.uid(),
    CASE WHEN p_released THEN 'patient_results_released'
         ELSE 'patient_results_unreleased' END,
    'patients',
    v_patient.id,
    v_patient.id,
    jsonb_build_object('source', 'set_patient_results_released',
                       'released', p_released)
  );

  RETURN v_patient;
END;
$$;

REVOKE ALL ON FUNCTION public.set_patient_results_released(UUID, BOOLEAN)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_patient_results_released(UUID, BOOLEAN)
  TO authenticated;

-- 3) RLS: paciente só lê resultados após liberação do paciente -----------------
DROP POLICY IF EXISTS questionnaire_results_select ON public.questionnaire_results;
CREATE POLICY questionnaire_results_select
  ON public.questionnaire_results
  FOR SELECT
  TO authenticated
  USING (
    public.user_can_access_response(response_id)
    AND (
      public.current_role() <> 'patient'
      OR EXISTS (
        SELECT 1
        FROM public.questionnaire_responses AS qr
        JOIN public.patients AS p ON p.id = qr.patient_id
        WHERE qr.id = questionnaire_results.response_id
          AND p.results_released_at IS NOT NULL
      )
    )
  );

-- Answers de respostas concluídas seguem a mesma liberação; drafts (não
-- concluídas) continuam visíveis ao próprio paciente para retomar.
DROP POLICY IF EXISTS questionnaire_answers_select ON public.questionnaire_answers;
CREATE POLICY questionnaire_answers_select
  ON public.questionnaire_answers
  FOR SELECT
  TO authenticated
  USING (
    public.user_can_access_response(response_id)
    AND (
      public.current_role() <> 'patient'
      OR EXISTS (
        SELECT 1
        FROM public.questionnaire_responses AS qr
        JOIN public.patients AS p ON p.id = qr.patient_id
        WHERE qr.id = questionnaire_answers.response_id
          AND (
            qr.status <> 'completed'
            OR p.results_released_at IS NOT NULL
          )
      )
    )
  );
