-- =============================================================================
-- Fix questionnaire access: 3 blockers que impediam qualquer uso em produção
-- =============================================================================

-- 1. Aprovar todos os questionários ativos para produção
--    Por padrão, clinical_status = 'validation', que bloqueia inicio de sessão
--    na edge function e desabilita cards no Flutter em modo produção.
UPDATE public.questionnaires
SET clinical_status = 'approved'
WHERE is_active = true
  AND clinical_status = 'validation';

-- 2. Política RLS: pacientes podem ler os grants do seu psicólogo responsável
--    Sem isso, patients.questionnaire_professional_access retorna {} e o
--    catálogo de questionários fica vazio para o paciente.
CREATE POLICY questionnaire_professional_access_select_patient
  ON public.questionnaire_professional_access
  FOR SELECT
  TO authenticated
  USING (
    public.current_role() = 'patient'
    AND clinic_id = public.current_clinic_id()
    AND professional_id = (
      SELECT responsible_psychologist_id
      FROM public.patients
      WHERE profile_id = auth.uid()
        AND responsible_psychologist_id IS NOT NULL
      LIMIT 1
    )
  );

-- 3. Seed de grants padrão: todos os questionários ativos habilitados para
--    todos os psicólogos ativos que ainda não possuem nenhuma configuração.
--    ON CONFLICT garante idempotência — não sobrescreve grants existentes.
INSERT INTO public.questionnaire_professional_access (
  clinic_id,
  questionnaire_id,
  professional_id,
  is_enabled,
  granted_by
)
SELECT
  p.clinic_id,
  q.id            AS questionnaire_id,
  p.id            AS professional_id,
  true            AS is_enabled,
  NULL            AS granted_by
FROM public.profiles p
CROSS JOIN public.questionnaires q
WHERE p.role      = 'psychologist'
  AND p.is_active = true
  AND q.is_active = true
ON CONFLICT (questionnaire_id, professional_id) DO NOTHING;
