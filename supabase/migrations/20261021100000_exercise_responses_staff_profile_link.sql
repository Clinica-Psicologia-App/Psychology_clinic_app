-- Responses reference profiles.id; user_can_access_patient receives patients.id.
-- Preserve canonical responsible-psychologist/clinic restrictions and admin denial.
ALTER POLICY staff_view_exercise_responses
  ON public.psychoeducation_exercise_responses
  USING (
    public.is_staff()
    AND EXISTS (
      SELECT 1 FROM public.patients AS p
      WHERE p.profile_id = psychoeducation_exercise_responses.patient_id
        AND public.user_can_access_patient(p.id)
    )
  );
