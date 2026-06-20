-- Simplifica o produto para administrador global, psicologo e paciente.
-- O valor legado `admin` permanece no enum apenas por compatibilidade historica.

UPDATE public.profiles
SET is_active = false
WHERE role = 'admin'
  AND lower(email) LIKE '%@clinicateste-mvp.example';

UPDATE public.profiles
SET role = 'platform_admin'
WHERE role = 'admin';

UPDATE auth.users AS users
SET raw_user_meta_data = COALESCE(users.raw_user_meta_data, '{}'::jsonb)
  || jsonb_build_object(
    'role', profiles.role::text,
    'clinic_id', profiles.clinic_id
  )
FROM public.profiles AS profiles
WHERE profiles.id = users.id
  AND profiles.role = 'platform_admin';

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_role()::text = 'psychologist';
$$;

CREATE OR REPLACE FUNCTION public.user_can_access_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE public.current_role()::text
    WHEN 'psychologist' THEN EXISTS (
      SELECT 1
      FROM public.patients AS patient
      WHERE patient.id = p_patient_id
        AND patient.clinic_id = public.current_clinic_id()
        AND patient.responsible_psychologist_id = auth.uid()
    )
    WHEN 'patient' THEN EXISTS (
      SELECT 1
      FROM public.patients AS patient
      WHERE patient.id = p_patient_id
        AND patient.profile_id = auth.uid()
    )
    ELSE false
  END;
$$;

DROP POLICY IF EXISTS clinics_select_own ON public.clinics;
CREATE POLICY clinics_select_own
  ON public.clinics
  FOR SELECT
  TO authenticated
  USING (
    public.current_role()::text = 'platform_admin'
    OR id = public.current_clinic_id()
  );

DROP POLICY IF EXISTS clinics_update_admin ON public.clinics;
CREATE POLICY clinics_update_admin
  ON public.clinics
  FOR UPDATE
  TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS profiles_select_clinic_or_self ON public.profiles;
CREATE POLICY profiles_select_clinic_or_self
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    public.current_role()::text = 'platform_admin'
    OR clinic_id = public.current_clinic_id()
    OR id = auth.uid()
  );

DROP POLICY IF EXISTS profiles_update_self_or_admin ON public.profiles;
CREATE POLICY profiles_update_self_or_admin
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR public.current_role()::text = 'platform_admin'
  )
  WITH CHECK (
    id = auth.uid()
    OR public.current_role()::text = 'platform_admin'
  );

DROP POLICY IF EXISTS profiles_insert_admin ON public.profiles;
CREATE POLICY profiles_insert_admin
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.current_role()::text = 'platform_admin'
    AND EXISTS (SELECT 1 FROM auth.users AS users WHERE users.id = profiles.id)
  );

CREATE OR REPLACE FUNCTION public.prevent_profile_privilege_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF current_user IN ('postgres', 'supabase_admin')
    OR auth.role() = 'service_role'
    OR public.current_role()::text = 'platform_admin' THEN
    RETURN NEW;
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role
    OR NEW.clinic_id IS DISTINCT FROM OLD.clinic_id
    OR NEW.is_active IS DISTINCT FROM OLD.is_active
    OR NEW.can_receive_patients IS DISTINCT FROM OLD.can_receive_patients
    OR NEW.patient_assignment_limit IS DISTINCT FROM OLD.patient_assignment_limit THEN
    RAISE EXCEPTION 'Campos administrativos do perfil nao podem ser alterados pelo proprio usuario';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_prevent_privilege_escalation ON public.profiles;
CREATE TRIGGER trg_profiles_prevent_privilege_escalation
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_profile_privilege_escalation();

CREATE OR REPLACE FUNCTION public.validate_questionnaire_professional_access()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_professional_role public.profile_role;
  v_professional_clinic UUID;
  v_granted_by_role public.profile_role;
BEGIN
  SELECT role, clinic_id
    INTO v_professional_role, v_professional_clinic
  FROM public.profiles
  WHERE id = NEW.professional_id;

  IF v_professional_role IS DISTINCT FROM 'psychologist'::public.profile_role THEN
    RAISE EXCEPTION 'professional_id deve referenciar um psicologo';
  END IF;

  IF v_professional_clinic IS DISTINCT FROM NEW.clinic_id THEN
    RAISE EXCEPTION 'clinic_id deve coincidir com a clinica do psicologo';
  END IF;

  IF NEW.granted_by IS NOT NULL THEN
    SELECT role
      INTO v_granted_by_role
    FROM public.profiles
    WHERE id = NEW.granted_by;

    IF v_granted_by_role IS DISTINCT FROM 'platform_admin'::public.profile_role THEN
      RAISE EXCEPTION 'granted_by deve referenciar um administrador';
    END IF;
  END IF;

  IF NEW.is_enabled THEN
    NEW.revoked_at := NULL;
  ELSIF NEW.revoked_at IS NULL THEN
    NEW.revoked_at := timezone('utc', now());
  END IF;

  RETURN NEW;
END;
$$;

DROP POLICY IF EXISTS questionnaire_professional_access_select_admin
  ON public.questionnaire_professional_access;
DROP POLICY IF EXISTS questionnaire_professional_access_insert_admin
  ON public.questionnaire_professional_access;
DROP POLICY IF EXISTS questionnaire_professional_access_update_admin
  ON public.questionnaire_professional_access;
DROP POLICY IF EXISTS questionnaire_professional_access_delete_admin
  ON public.questionnaire_professional_access;

CREATE POLICY questionnaire_professional_access_select_platform_admin
  ON public.questionnaire_professional_access
  FOR SELECT TO authenticated
  USING (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaire_professional_access_insert_platform_admin
  ON public.questionnaire_professional_access
  FOR INSERT TO authenticated
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaire_professional_access_update_platform_admin
  ON public.questionnaire_professional_access
  FOR UPDATE TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

CREATE POLICY questionnaire_professional_access_delete_platform_admin
  ON public.questionnaire_professional_access
  FOR DELETE TO authenticated
  USING (public.current_role()::text = 'platform_admin');

CREATE OR REPLACE FUNCTION public.validate_patient_invitation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_invited_by_role public.profile_role;
  v_invited_by_clinic UUID;
  v_responsible_role public.profile_role;
  v_responsible_clinic UUID;
BEGIN
  NEW.email := lower(trim(NEW.email));
  NEW.full_name := NULLIF(trim(COALESCE(NEW.full_name, '')), '');
  NEW.phone := NULLIF(trim(COALESCE(NEW.phone, '')), '');

  SELECT role, clinic_id
    INTO v_invited_by_role, v_invited_by_clinic
  FROM public.profiles
  WHERE id = NEW.invited_by;

  IF v_invited_by_role IS DISTINCT FROM 'psychologist'::public.profile_role
    OR v_invited_by_clinic IS DISTINCT FROM NEW.clinic_id THEN
    RAISE EXCEPTION 'invited_by deve ser psicologo da clinica do convite';
  END IF;

  SELECT role, clinic_id
    INTO v_responsible_role, v_responsible_clinic
  FROM public.profiles
  WHERE id = NEW.responsible_psychologist_id;

  IF v_responsible_role IS DISTINCT FROM 'psychologist'::public.profile_role
    OR v_responsible_clinic IS DISTINCT FROM NEW.clinic_id THEN
    RAISE EXCEPTION 'responsible_psychologist_id deve ser psicologo da clinica';
  END IF;

  IF NEW.status = 'pending' AND NEW.expires_at <= timezone('utc', now()) THEN
    RAISE EXCEPTION 'expires_at deve estar no futuro para convites pendentes';
  END IF;

  IF NEW.status = 'accepted' AND NEW.accepted_at IS NULL THEN
    NEW.accepted_at := timezone('utc', now());
  END IF;

  RETURN NEW;
END;
$$;

DROP POLICY IF EXISTS patient_invitations_select_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_insert_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_update_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_delete_admin ON public.patient_invitations;

DROP POLICY IF EXISTS legal_consents_select_own_or_admin ON public.legal_consents;
CREATE POLICY legal_consents_select_own_or_admin
  ON public.legal_consents
  FOR SELECT TO authenticated
  USING (
    profile_id = auth.uid()
    OR public.current_role()::text = 'platform_admin'
  );

DROP POLICY IF EXISTS audit_events_select_admin ON public.audit_events;
CREATE POLICY audit_events_select_admin
  ON public.audit_events
  FOR SELECT TO authenticated
  USING (public.current_role()::text = 'platform_admin');

COMMENT ON TYPE public.profile_role IS
  'Papeis ativos: platform_admin, psychologist e patient. admin e legado.';
