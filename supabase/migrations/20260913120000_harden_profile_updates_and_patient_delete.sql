-- F01/F02 only. Keep the existing RLS and administrative RPC contracts.
BEGIN;

CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor public.profiles%ROWTYPE;
  v_db_role text := current_setting('role', true);
BEGIN
  -- SET ROLE is enforced by PostgreSQL/PostgREST, unlike user metadata.
  -- Never use current_user here: it is the SECURITY DEFINER owner.
  -- Direct maintenance is trusted only when no application role is assumed.
  IF v_db_role = 'service_role'
    OR (v_db_role = 'none' AND session_user IN ('postgres', 'supabase_admin')) THEN
    RETURN NEW;
  END IF;

  -- GoTrue connects as supabase_auth_admin; preserve its existing email-sync
  -- trigger, without granting that connection arbitrary profile updates.
  IF v_db_role = 'none' AND session_user = 'supabase_auth_admin'
    AND (to_jsonb(NEW) - ARRAY['email', 'updated_at'])
      IS NOT DISTINCT FROM (to_jsonb(OLD) - ARRAY['email', 'updated_at'])
    AND EXISTS (SELECT 1 FROM auth.users AS u WHERE u.id = OLD.id AND u.email = NEW.email) THEN
    RETURN NEW;
  END IF;

  IF v_db_role IS DISTINCT FROM 'authenticated' OR auth.uid() IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Perfil ativo autenticado obrigatorio';
  END IF;

  SELECT * INTO v_actor FROM public.profiles WHERE id = auth.uid();
  IF NOT FOUND OR v_actor.is_active IS DISTINCT FROM true OR v_actor.role IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = '42501', MESSAGE = 'Perfil ativo autenticado obrigatorio';
  END IF;

  IF v_actor.role::text = 'platform_admin' THEN
    RETURN NEW;
  END IF;

  -- Preserve set_patient_active_status for the active, owning psychologist.
  -- No identity, contact, quota or other administrative change is allowed here.
  IF v_actor.role::text = 'psychologist' AND OLD.role::text = 'patient'
    AND (to_jsonb(NEW) - ARRAY['is_active', 'updated_at'])
      IS NOT DISTINCT FROM (to_jsonb(OLD) - ARRAY['is_active', 'updated_at'])
    AND EXISTS (
      SELECT 1 FROM public.patients AS patient
      WHERE patient.profile_id = OLD.id
        AND patient.clinic_id = v_actor.clinic_id
        AND OLD.clinic_id = v_actor.clinic_id
        AND patient.responsible_psychologist_id = v_actor.id
    ) THEN
    RETURN NEW;
  END IF;

  -- Explicit self-service allowlist. New columns are protected by default.
  -- updated_at is maintained by the existing trigger; avatar_updated_at is
  -- also sent by the existing Flutter photo-upload flow.
  IF OLD.id = v_actor.id
    AND (to_jsonb(NEW) - ARRAY[
      'full_name', 'phone', 'avatar_url', 'avatar_type', 'avatar_path',
      'avatar_config', 'avatar_updated_at', 'updated_at'
    ]) IS NOT DISTINCT FROM (to_jsonb(OLD) - ARRAY[
      'full_name', 'phone', 'avatar_url', 'avatar_type', 'avatar_path',
      'avatar_config', 'avatar_updated_at', 'updated_at'
    ]) THEN
    RETURN NEW;
  END IF;

  RAISE EXCEPTION USING ERRCODE = '42501',
    MESSAGE = 'Alteracao de campos protegidos ou de outro perfil nao autorizada';
END;
$$;

-- Trigger execution does not require an RPC EXECUTE grant for the caller.
REVOKE ALL ON FUNCTION public.prevent_profile_privilege_escalation()
  FROM PUBLIC, anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.delete_patient_as_admin(p_patient_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog
AS $$
DECLARE
  v_actor_id uuid := auth.uid();
  v_clinic_id uuid;
  v_full_name text;
BEGIN
  -- Global platform administrator, not a clinic-scoped administrator.
  -- Check before looking up the target, including missing/NULL target IDs.
  IF current_setting('role', true) IS DISTINCT FROM 'authenticated'
    OR v_actor_id IS NULL
    OR NOT EXISTS (
      SELECT 1 FROM public.profiles AS actor
      WHERE actor.id = v_actor_id
        AND actor.is_active IS TRUE
        AND actor.role::text = 'platform_admin'
    ) THEN
    RAISE EXCEPTION USING ERRCODE = '42501',
      MESSAGE = 'Apenas administradores ativos podem excluir pacientes definitivamente';
  END IF;

  SELECT clinic_id, full_name INTO v_clinic_id, v_full_name
  FROM public.patients WHERE id = p_patient_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0002', MESSAGE = 'Paciente nao encontrado';
  END IF;

  DELETE FROM public.patients WHERE id = p_patient_id;
  INSERT INTO public.audit_events (
    clinic_id, actor_profile_id, action, entity_type, entity_id, metadata
  ) VALUES (
    v_clinic_id, v_actor_id, 'patient_deleted_permanently', 'patients', p_patient_id,
    jsonb_build_object('patient_full_name', v_full_name, 'actor_role', 'platform_admin')
  );
END;
$$;

-- Remove direct/default grants as well as the implicit PUBLIC grant.
REVOKE ALL ON FUNCTION public.delete_patient_as_admin(uuid)
  FROM PUBLIC, anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.delete_patient_as_admin(uuid) TO authenticated;

COMMIT;
