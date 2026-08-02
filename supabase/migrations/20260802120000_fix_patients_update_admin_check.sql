-- =============================================================================
-- Migration: corrige inconsistência entre USING e WITH CHECK de
-- patients_update_staff, causada pela restrição de privacidade do admin.
-- =============================================================================
--
-- Migration 20250620170035 criou patients_update_staff com a intenção de que
-- platform_admin pudesse atualizar pacientes (inativação, reatribuição):
--
--   USING (user_can_access_patient(id))
--   WITH CHECK (current_role() = 'platform_admin' OR (... psicólogo ...))
--
-- Migration 20260720120011 (restrict_admin_patient_access) removeu admin de
-- user_can_access_patient — ele passou a retornar sempre false para admin,
-- por privacidade clínica: admin não deve ler linhas individuais de
-- paciente, só contagens agregadas via RPC.
--
-- Isso quebrou silenciosamente o UPDATE: a cláusula USING (que filtra QUAIS
-- linhas podem ser atualizadas) passou a barrar admin, enquanto o WITH CHECK
-- (que valida os valores novos) continuou citando platform_admin
-- explicitamente — uma policy que promete uma capacidade que não funciona.
--
-- A correção não é "religar" admin: o UPDATE do app (patients_repository.dart
-- updatePatient) faz `.update(data).select(...).single()`, ou seja, devolve a
-- linha inteira do paciente na resposta. Se o USING voltasse a liberar admin,
-- ele voltaria a conseguir ler dados individuais de paciente através da
-- resposta do UPDATE — exatamente o que a migration de privacidade quis
-- impedir. As duas ações administrativas que admin de fato usa
-- (ativar/inativar via set_patient_active_status, excluir via
-- delete_patient_as_admin) já são SECURITY DEFINER e bypassam RLS
-- inteiramente, então não dependem desta policy e continuam funcionando.
--
-- Este UPDATE nunca foi alcançável por admin pela UI: a única tela que o
-- aciona (EditPatientPage) só é registrada para role=psychologist no router.
-- Ou seja, este é um ajuste de consistência da policy, não uma mudança de
-- comportamento observável.

DROP POLICY IF EXISTS patients_update_staff ON public.patients;
CREATE POLICY patients_update_staff
  ON public.patients
  FOR UPDATE
  TO authenticated
  USING (public.user_can_access_patient(id))
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role()::text = 'psychologist'
    AND responsible_psychologist_id = auth.uid()
  );
