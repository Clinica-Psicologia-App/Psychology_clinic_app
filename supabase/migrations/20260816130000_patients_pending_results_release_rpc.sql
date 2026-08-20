-- RPC que lista, sem limite, os IDs de pacientes do psicólogo logado com
-- questionário concluído mas resultado ainda não liberado.
--
-- Existe separada de get_psychologist_alerts() (que já cobre a mesma
-- categoria) porque aquela trunca em 3 itens para caber no card de
-- Notificações — aqui precisamos do conjunto completo para marcar o selo
-- correto em cada card da lista de pacientes, não só nos 3 mais antigos.

CREATE OR REPLACE FUNCTION public.get_patients_with_pending_results_release()
RETURNS TABLE(patient_id UUID)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT DISTINCT p.id
  FROM questionnaire_responses qr
  JOIN patients p ON p.id = qr.patient_id
  WHERE p.responsible_psychologist_id = auth.uid()
    AND p.is_active            = true
    AND qr.status               = 'completed'
    AND p.results_released_at IS NULL;
$$;

REVOKE ALL   ON FUNCTION public.get_patients_with_pending_results_release() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.get_patients_with_pending_results_release() TO authenticated;
