-- =============================================================================
-- Migration: corrige get_patient_counts_by_psychologist para platform_admin
-- =============================================================================
-- A migration 20260720120011_restrict_admin_patient_access criou esta RPC mas
-- com dois bugs:
--   1. Verifica current_role() <> 'admin', mas o enum usa 'platform_admin'.
--      Resultado: a função lança exception para qualquer chamada legítima.
--   2. Filtra por clinic_id = current_clinic_id(), mas platform_admin pode ter
--      clinic_id NULL ou pertencer a uma clínica diferente dos psicólogos.
--      Resultado: sem psicólogos retornados mesmo se o bug 1 fosse corrigido.
--
-- Correção: usar current_role()::text = 'platform_admin' e remover o filtro
-- de clínica (admin tem visibilidade global, alinhado com o acesso que já tem
-- em profiles e patients via outras políticas).

CREATE OR REPLACE FUNCTION public.get_patient_counts_by_psychologist()
RETURNS TABLE(
  psychologist_id UUID,
  active_count    BIGINT,
  pending_invites BIGINT
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.current_role()::text <> 'platform_admin' THEN
    RAISE EXCEPTION 'Acesso restrito a administradores.'
      USING ERRCODE = '42501';
  END IF;

  RETURN QUERY
  SELECT
    prof.id AS psychologist_id,
    (
      SELECT COUNT(*)
      FROM public.patients p
      WHERE p.responsible_psychologist_id = prof.id
        AND p.is_active = true
    ) AS active_count,
    (
      SELECT COUNT(*)
      FROM public.patient_invitations pi
      WHERE pi.responsible_psychologist_id = prof.id
        AND pi.status = 'pending'
    ) AS pending_invites
  FROM public.profiles prof
  WHERE prof.role = 'psychologist';
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_patient_counts_by_psychologist() TO authenticated;
