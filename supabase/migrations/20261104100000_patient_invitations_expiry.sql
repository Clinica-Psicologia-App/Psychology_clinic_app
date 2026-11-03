-- =============================================================================
-- Convites de paciente: convite vencido deixa de ocupar vaga.
--
-- Até aqui um convite com prazo vencido continuava com status 'pending' para
-- sempre: ocupava uma vaga do psicólogo (limite de pacientes) e, pelo índice
-- único de e-mail pendente, impedia reenviar convite ao mesmo e-mail.
--
--  1. A contagem do painel passa a considerar só convites pendentes DENTRO do
--     prazo (a mesma regra aplicada na função de servidor que bloqueia o
--     cadastro, para os dois sempre concordarem).
--  2. Convites pendentes já vencidos são marcados como 'expired' (nenhum
--     registro é apagado). Novos vencimentos são marcados na criação de um novo
--     convite (create-patient-invitation).
-- =============================================================================

BEGIN;

-- Mesmo corpo da função atual (com o controle de acesso reforçado); só muda o
-- filtro de convites pendentes.
CREATE OR REPLACE FUNCTION public.get_patient_counts_by_psychologist()
 RETURNS TABLE(psychologist_id uuid, active_count bigint, pending_invites bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  v_actor_id uuid := auth.uid();
BEGIN
  IF current_setting('role', true) IS DISTINCT FROM 'authenticated'
    OR v_actor_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Administrative counts access denied';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles AS actor
    WHERE actor.id = v_actor_id AND actor.is_active IS TRUE
      AND actor.role::text = 'platform_admin'
  ) THEN
    RAISE EXCEPTION USING ERRCODE='42501', MESSAGE='Administrative counts access denied';
  END IF;

  -- Global contract: do not filter the administrator or counts by clinic.
  RETURN QUERY
  SELECT prof.id AS psychologist_id,
    (SELECT COUNT(*) FROM public.patients p
     WHERE p.responsible_psychologist_id = prof.id AND p.is_active = true) AS active_count,
    (SELECT COUNT(*) FROM public.patient_invitations pi
     WHERE pi.responsible_psychologist_id = prof.id
       AND pi.status = 'pending'
       AND pi.expires_at > pg_catalog.now()) AS pending_invites
  FROM public.profiles prof
  WHERE prof.role = 'psychologist';
END;
$function$;

-- Marca os convites pendentes que já venceram. Não apaga nada.
UPDATE public.patient_invitations
SET status = 'expired'
WHERE status = 'pending'
  AND expires_at <= now();

COMMIT;
