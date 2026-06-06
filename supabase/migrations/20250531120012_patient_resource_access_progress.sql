-- Progresso do paciente em recursos liberados (visualizado / concluído).

ALTER TABLE public.patient_resource_access
  ADD COLUMN IF NOT EXISTS viewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

COMMENT ON COLUMN public.patient_resource_access.viewed_at IS
  'Primeira visualização pelo paciente no app.';
COMMENT ON COLUMN public.patient_resource_access.completed_at IS
  'Marcação de conclusão pelo paciente.';

CREATE POLICY patient_resource_access_update_patient
  ON public.patient_resource_access
  FOR UPDATE
  TO authenticated
  USING (
    public.current_role() = 'patient'
    AND patient_id = public.current_patient_id()
    AND is_active = true
  )
  WITH CHECK (
    public.current_role() = 'patient'
    AND patient_id = public.current_patient_id()
  );
