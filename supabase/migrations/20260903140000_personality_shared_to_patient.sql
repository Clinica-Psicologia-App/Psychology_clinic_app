-- Compartilhamento opt-in do perfil de personalidade com o PACIENTE (Fase 3).
--
-- O terapeuta libera manualmente (personality_assessments.shared_with_patient).
-- O paciente NUNCA vê a síntese clínica nem a integração à conceitualização
-- (raciocínio do terapeuta), e NÃO vê os números brutos — apenas a
-- classificação (faixa) de domínios e facetas.
--
-- Isolamento por VIEW (security definer): expõe só colunas seguras, com os
-- escores removidos do JSONB, e apenas as linhas do próprio paciente marcadas
-- como compartilhadas. A tabela base continua inacessível ao paciente (RLS
-- staff-only inalterada).

-- Remove todas as chaves "score" de results, preservando "classification" e a
-- estrutura de domínios/facetas.
CREATE OR REPLACE FUNCTION public.personality_results_public(p JSONB)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT jsonb_build_object(
    'domains',
    COALESCE((
      SELECT jsonb_object_agg(
        dk,
        (dv - 'score') || jsonb_build_object(
          'facets',
          COALESCE((
            SELECT jsonb_object_agg(fk, fv - 'score')
            FROM jsonb_each(COALESCE(dv->'facets', '{}'::jsonb)) AS f(fk, fv)
          ), '{}'::jsonb)
        )
      )
      FROM jsonb_each(COALESCE(p->'domains', '{}'::jsonb)) AS d(dk, dv)
    ), '{}'::jsonb)
  );
$$;

CREATE VIEW public.patient_shared_personality
WITH (security_invoker = false) AS
  SELECT
    id,
    patient_id,
    instrument,
    applied_on,
    public.personality_results_public(results) AS results,
    updated_at
  FROM public.personality_assessments
  WHERE shared_with_patient = true
    AND patient_id = public.current_patient_id();

COMMENT ON VIEW public.patient_shared_personality IS
  'Perfil de personalidade que o terapeuta compartilhou com o paciente: só '
  'classificações (sem escores), sem síntese/integração. Filtra pelo próprio '
  'paciente.';

GRANT SELECT ON public.patient_shared_personality TO authenticated;
