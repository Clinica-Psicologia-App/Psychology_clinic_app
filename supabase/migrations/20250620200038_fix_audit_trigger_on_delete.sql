-- =============================================================================
-- Migration 038: corrige audit_sensitive_change para DELETE operations
-- =============================================================================
-- Problema: ao deletar um paciente, o trigger AFTER DELETE tenta inserir
-- em audit_events com patient_id = <id_do_paciente>, mas esse registro
-- já não existe, causando FK violation (23503).
-- Correção: em DELETE operations, patient_id sempre NULL no audit log.
-- O entity_id já captura o UUID do registro deletado.

CREATE OR REPLACE FUNCTION public.audit_sensitive_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row JSONB;
  v_clinic_id UUID;
  v_patient_id UUID;
  v_entity_id UUID;
BEGIN
  v_row := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
  v_clinic_id := NULLIF(v_row ->> 'clinic_id', '')::UUID;
  v_entity_id := NULLIF(v_row ->> 'id', '')::UUID;

  -- Em DELETE, nunca referenciar patient_id via FK — o registro pode já
  -- não existir, causando foreign_key_violation (23503).
  -- Para INSERT/UPDATE mantém o comportamento original.
  v_patient_id := CASE
    WHEN TG_OP = 'DELETE' THEN NULL
    WHEN TG_TABLE_NAME = 'patients' THEN v_entity_id
    ELSE NULLIF(v_row ->> 'patient_id', '')::UUID
  END;

  INSERT INTO public.audit_events (
    clinic_id,
    actor_profile_id,
    action,
    entity_type,
    entity_id,
    patient_id,
    metadata
  )
  VALUES (
    v_clinic_id,
    auth.uid(),
    lower(TG_OP),
    TG_TABLE_NAME,
    v_entity_id,
    v_patient_id,
    jsonb_build_object('source', 'database_trigger')
  );

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;
