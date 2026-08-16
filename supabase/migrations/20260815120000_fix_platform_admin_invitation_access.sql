-- =============================================================================
-- Migration: restaura acesso de platform_admin a patient_invitations
-- =============================================================================
-- A migração 20250620130032_simplify_administrator_roles removeu as policies
-- `patient_invitations_select/insert/update/delete_admin` sem recriar
-- equivalentes para platform_admin. A consequência é que o admin vê 0 convites
-- em todas as telas, incluindo a distribuição de pacientes.
-- A migração 20250620170035_platform_admin_patient_access corrigiu apenas
-- `patients` (via user_can_access_patient); aqui corrigimos as invitations.

-- SELECT: platform_admin enxerga todos os convites (sem filtro de clínica,
-- alinhado com o acesso global que já tem em profiles e patients).
DROP POLICY IF EXISTS patient_invitations_select_platform_admin
  ON public.patient_invitations;

CREATE POLICY patient_invitations_select_platform_admin
  ON public.patient_invitations
  FOR SELECT
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');

-- INSERT: platform_admin pode criar convites em qualquer clínica.
DROP POLICY IF EXISTS patient_invitations_insert_platform_admin
  ON public.patient_invitations;

CREATE POLICY patient_invitations_insert_platform_admin
  ON public.patient_invitations
  FOR INSERT
  TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');

-- UPDATE: platform_admin pode cancelar / reenviar qualquer convite.
DROP POLICY IF EXISTS patient_invitations_update_platform_admin
  ON public.patient_invitations;

CREATE POLICY patient_invitations_update_platform_admin
  ON public.patient_invitations
  FOR UPDATE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

-- DELETE: platform_admin pode remover convites expirados / inválidos.
DROP POLICY IF EXISTS patient_invitations_delete_platform_admin
  ON public.patient_invitations;

CREATE POLICY patient_invitations_delete_platform_admin
  ON public.patient_invitations
  FOR DELETE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin');
