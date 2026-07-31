-- B-5: Adiciona trigger de auditoria para patient_questionnaire_assignments.
-- Atribuir e cancelar questionários são ações clinicamente relevantes e
-- devem constar no log de auditoria (tabela audit_log / sensitive_changes).

DO $$
BEGIN
  -- Cria o trigger apenas se a função de auditoria existir (definida em 20250615120029).
  IF EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'audit_sensitive_change'
      AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  ) THEN
    DROP TRIGGER IF EXISTS trg_patient_questionnaire_assignments_audit
      ON public.patient_questionnaire_assignments;

    CREATE TRIGGER trg_patient_questionnaire_assignments_audit
      AFTER INSERT OR UPDATE OR DELETE
      ON public.patient_questionnaire_assignments
      FOR EACH ROW
      EXECUTE FUNCTION public.audit_sensitive_change();
  END IF;
END;
$$;
