-- RPC que agrega o preenchimento da avaliação inicial ("Conhecer") + questionários
-- por paciente do psicólogo logado. Alimenta o anel de progresso no card da
-- lista de pacientes, no mesmo padrão de get_patients_with_pending_results_release.
--
-- Retorna uma linha por paciente ativo do psicólogo, com um booleano por seção:
--   perfil        dados básicos preenchidos em `patients`
--   queixa        `patient_intake` com motivo da procura
--   areas         ao menos uma área da vida pontuada
--   historia      ao menos um evento na linha do tempo
--   familia       ao menos uma pessoa (com vínculo) no genograma
--   questionarios ao menos um questionário concluído
--
-- SECURITY DEFINER: roda como owner (bypassa RLS), mas aplica o filtro
-- responsible_psychologist_id = auth.uid().

CREATE OR REPLACE FUNCTION public.get_patients_data_completion()
RETURNS TABLE(
  patient_id    UUID,
  perfil        BOOLEAN,
  queixa        BOOLEAN,
  areas         BOOLEAN,
  historia      BOOLEAN,
  familia       BOOLEAN,
  questionarios BOOLEAN
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id AS patient_id,
    (
      p.birth_date IS NOT NULL
      OR NULLIF(btrim(p.occupation), '') IS NOT NULL
    ) AS perfil,
    EXISTS (
      SELECT 1 FROM patient_intake pi
      WHERE pi.patient_id = p.id
        AND NULLIF(btrim(pi.reason_for_seeking), '') IS NOT NULL
    ) AS queixa,
    EXISTS (
      SELECT 1 FROM patient_life_areas la
      WHERE la.patient_id = p.id
        AND la.score IS NOT NULL
    ) AS areas,
    EXISTS (
      SELECT 1 FROM patient_timeline_events te
      WHERE te.patient_id = p.id
    ) AS historia,
    EXISTS (
      SELECT 1 FROM genogram_people gp
      WHERE gp.patient_id = p.id
        AND gp.relationship_to_patient IS NOT NULL
        AND gp.relationship_to_patient <> 'self'
    ) AS familia,
    EXISTS (
      SELECT 1 FROM questionnaire_responses qr
      WHERE qr.patient_id = p.id
        AND qr.status = 'completed'
    ) AS questionarios
  FROM patients p
  WHERE p.responsible_psychologist_id = auth.uid()
    AND p.is_active = true;
$$;

REVOKE ALL   ON FUNCTION public.get_patients_data_completion() FROM PUBLIC, anon;
GRANT  EXECUTE ON FUNCTION public.get_patients_data_completion() TO authenticated;
