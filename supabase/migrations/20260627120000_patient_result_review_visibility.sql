-- Pacientes só podem ler resultados clínicos após revisão/liberação da equipe.
-- A resposta continua visível para preservar status de questionário concluído,
-- mas answers/resultados de respostas concluídas ficam protegidos até reviewed_at.

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
        WHERE qr.id = questionnaire_answers.response_id
          AND (
            qr.status <> 'completed'
            OR qr.reviewed_at IS NOT NULL
          )
      )
    )
  );

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
        WHERE qr.id = questionnaire_results.response_id
          AND qr.reviewed_at IS NOT NULL
      )
    )
  );
