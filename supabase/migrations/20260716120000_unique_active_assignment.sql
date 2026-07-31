-- M-6: Impede atribuição duplicada do mesmo questionário ao mesmo paciente
-- enquanto a atribuição não estiver cancelada.
-- Sem essa constraint um psicólogo poderia atribuir o mesmo instrumento
-- várias vezes, gerando duplicatas na lista do paciente e relatórios incorretos.

ALTER TABLE public.patient_questionnaire_assignments
  ADD CONSTRAINT uq_patient_questionnaire_active
  UNIQUE NULLS NOT DISTINCT (patient_id, questionnaire_id, cancelled_at);

-- Como cancelled_at = NULL representa "ativa", NULLS NOT DISTINCT garante
-- que a DB trate dois NULLs como iguais para efeito de unicidade,
-- bloqueando um segundo assignment ativo para o mesmo (patient, questionnaire).
-- Atribuições canceladas (cancelled_at IS NOT NULL) continuam sem restrição.
