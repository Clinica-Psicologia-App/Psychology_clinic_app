-- =============================================================================
-- Migration 009: integração auth.users ↔ profiles e policies RLS multi-tenant
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. FK profiles.id → auth.users.id
-- NOT VALID: não quebra linhas legadas; novos inserts exigem auth.users.
-- -----------------------------------------------------------------------------

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_id_fkey_auth_users
  FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE
  NOT VALID;

COMMENT ON CONSTRAINT profiles_id_fkey_auth_users ON public.profiles IS
  'profiles.id = auth.users.id. Perfil criado no signup ou via trigger handle_new_user.';

-- -----------------------------------------------------------------------------
-- 2. Helpers RLS (SECURITY DEFINER — leem profiles com auth.uid())
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.current_clinic_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.clinic_id
  FROM public.profiles AS p
  WHERE p.id = auth.uid()
    AND p.is_active = true;
$$;

CREATE OR REPLACE FUNCTION public.current_role()
RETURNS public.profile_role
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT p.role
  FROM public.profiles AS p
  WHERE p.id = auth.uid()
    AND p.is_active = true;
$$;

CREATE OR REPLACE FUNCTION public.current_patient_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT pt.id
  FROM public.patients AS pt
  WHERE pt.profile_id = auth.uid()
  LIMIT 1;
$$;

CREATE OR REPLACE FUNCTION public.is_staff()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT public.current_role() IN ('admin', 'psychologist');
$$;

CREATE OR REPLACE FUNCTION public.user_can_access_patient(p_patient_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE public.current_role()
    WHEN 'admin' THEN EXISTS (
      SELECT 1
      FROM public.patients AS p
      WHERE p.id = p_patient_id
        AND p.clinic_id = public.current_clinic_id()
    )
    WHEN 'psychologist' THEN EXISTS (
      SELECT 1
      FROM public.patients AS p
      WHERE p.id = p_patient_id
        AND p.clinic_id = public.current_clinic_id()
        AND p.responsible_psychologist_id = auth.uid()
    )
    WHEN 'patient' THEN EXISTS (
      SELECT 1
      FROM public.patients AS p
      WHERE p.id = p_patient_id
        AND p.profile_id = auth.uid()
    )
    ELSE false
  END;
$$;

CREATE OR REPLACE FUNCTION public.user_can_access_response(p_response_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.questionnaire_responses AS qr
    WHERE qr.id = p_response_id
      AND qr.clinic_id = public.current_clinic_id()
      AND public.user_can_access_patient(qr.patient_id)
  );
$$;

COMMENT ON FUNCTION public.current_clinic_id() IS
  'clinic_id do usuário autenticado; NULL se sem profile ativo.';

COMMENT ON FUNCTION public.user_can_access_patient(UUID) IS
  'admin: pacientes da clínica; psychologist: pacientes sob sua responsabilidade; patient: próprio registro.';

GRANT EXECUTE ON FUNCTION public.current_clinic_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.current_patient_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_staff() TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_can_access_patient(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.user_can_access_response(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- 3. Sincronização auth.users → profiles
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_clinic_id UUID;
  v_role public.profile_role;
  v_full_name TEXT;
BEGIN
  IF NEW.raw_user_meta_data IS NULL THEN
    RETURN NEW;
  END IF;

  BEGIN
    v_clinic_id := (NEW.raw_user_meta_data ->> 'clinic_id')::UUID;
    v_role := (NEW.raw_user_meta_data ->> 'role')::public.profile_role;
  EXCEPTION
    WHEN invalid_text_representation THEN
      RETURN NEW;
  END;

  IF v_clinic_id IS NULL OR v_role IS NULL THEN
    RETURN NEW;
  END IF;

  v_full_name := COALESCE(
    NULLIF(trim(NEW.raw_user_meta_data ->> 'full_name'), ''),
    split_part(COALESCE(NEW.email, 'usuario'), '@', 1)
  );

  INSERT INTO public.profiles (id, clinic_id, full_name, email, phone, role, is_active)
  VALUES (
    NEW.id,
    v_clinic_id,
    v_full_name,
    COALESCE(NEW.email, ''),
    NULLIF(trim(NEW.raw_user_meta_data ->> 'phone'), ''),
    v_role,
    COALESCE((NEW.raw_user_meta_data ->> 'is_active')::BOOLEAN, true)
  )
  ON CONFLICT (id) DO UPDATE SET
    clinic_id = EXCLUDED.clinic_id,
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    phone = EXCLUDED.phone,
    role = EXCLUDED.role,
    is_active = EXCLUDED.is_active,
    updated_at = timezone('utc', now());

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.handle_user_email_updated()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.email IS DISTINCT FROM OLD.email THEN
    UPDATE public.profiles
    SET email = COALESCE(NEW.email, email),
        updated_at = timezone('utc', now())
    WHERE id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS on_auth_user_email_updated ON auth.users;
CREATE TRIGGER on_auth_user_email_updated
  AFTER UPDATE OF email ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_user_email_updated();

COMMENT ON FUNCTION public.handle_new_user() IS
  'Cria/atualiza profile no signup. Exige raw_user_meta_data: clinic_id, role; opcional: full_name, phone.';

-- -----------------------------------------------------------------------------
-- 4. Policies — clinics
-- -----------------------------------------------------------------------------

CREATE POLICY clinics_select_own
  ON public.clinics
  FOR SELECT
  TO authenticated
  USING (id = public.current_clinic_id());

CREATE POLICY clinics_update_admin
  ON public.clinics
  FOR UPDATE
  TO authenticated
  USING (
    id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  )
  WITH CHECK (
    id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

-- -----------------------------------------------------------------------------
-- 5. Policies — profiles
-- -----------------------------------------------------------------------------

CREATE POLICY profiles_select_clinic_or_self
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    OR id = auth.uid()
  );

CREATE POLICY profiles_update_self_or_admin
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (
    id = auth.uid()
    OR (
      clinic_id = public.current_clinic_id()
      AND public.current_role() = 'admin'
    )
  )
  WITH CHECK (
    id = auth.uid()
    OR (
      clinic_id = public.current_clinic_id()
      AND public.current_role() = 'admin'
    )
  );

CREATE POLICY profiles_insert_admin
  ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
    AND EXISTS (SELECT 1 FROM auth.users AS u WHERE u.id = profiles.id)
  );

-- -----------------------------------------------------------------------------
-- 6. Policies — patients
-- -----------------------------------------------------------------------------

CREATE POLICY patients_select_by_role
  ON public.patients
  FOR SELECT
  TO authenticated
  USING (public.user_can_access_patient(id));

CREATE POLICY patients_insert_staff
  ON public.patients
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND (
      public.current_role() = 'admin'
      OR (
        public.current_role() = 'psychologist'
        AND responsible_psychologist_id = auth.uid()
      )
    )
  );

CREATE POLICY patients_update_staff
  ON public.patients
  FOR UPDATE
  TO authenticated
  USING (public.user_can_access_patient(id))
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
    AND (
      public.current_role() = 'admin'
      OR (
        public.current_role() = 'psychologist'
        AND responsible_psychologist_id = auth.uid()
      )
    )
  );

-- -----------------------------------------------------------------------------
-- 7. Policies — questionários (catálogo global, leitura autenticada)
-- -----------------------------------------------------------------------------

CREATE POLICY questionnaires_select_active
  ON public.questionnaires
  FOR SELECT
  TO authenticated
  USING (
    is_active = true
    AND public.current_clinic_id() IS NOT NULL
  );

CREATE POLICY question_categories_select
  ON public.question_categories
  FOR SELECT
  TO authenticated
  USING (
    public.current_clinic_id() IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM public.questionnaires AS q
      WHERE q.id = questionnaire_id
        AND q.is_active = true
    )
  );

CREATE POLICY questions_select
  ON public.questions
  FOR SELECT
  TO authenticated
  USING (
    public.current_clinic_id() IS NOT NULL
    AND is_active = true
    AND EXISTS (
      SELECT 1
      FROM public.questionnaires AS q
      WHERE q.id = questionnaire_id
        AND q.is_active = true
    )
  );

CREATE POLICY question_category_items_select
  ON public.question_category_items
  FOR SELECT
  TO authenticated
  USING (public.current_clinic_id() IS NOT NULL);

-- -----------------------------------------------------------------------------
-- 8. Policies — questionnaire_responses
-- -----------------------------------------------------------------------------

CREATE POLICY questionnaire_responses_select
  ON public.questionnaire_responses
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY questionnaire_responses_insert
  ON public.questionnaire_responses
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
    AND (
      public.is_staff()
      OR (
        public.current_role() = 'patient'
        AND patient_id = public.current_patient_id()
      )
    )
  );

CREATE POLICY questionnaire_responses_update
  ON public.questionnaire_responses
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

-- -----------------------------------------------------------------------------
-- 9. Policies — questionnaire_answers
-- -----------------------------------------------------------------------------

CREATE POLICY questionnaire_answers_select
  ON public.questionnaire_answers
  FOR SELECT
  TO authenticated
  USING (public.user_can_access_response(response_id));

CREATE POLICY questionnaire_answers_insert
  ON public.questionnaire_answers
  FOR INSERT
  TO authenticated
  WITH CHECK (public.user_can_access_response(response_id));

CREATE POLICY questionnaire_answers_update
  ON public.questionnaire_answers
  FOR UPDATE
  TO authenticated
  USING (public.user_can_access_response(response_id))
  WITH CHECK (public.user_can_access_response(response_id));

-- -----------------------------------------------------------------------------
-- 10. Policies — questionnaire_results
-- -----------------------------------------------------------------------------

CREATE POLICY questionnaire_results_select
  ON public.questionnaire_results
  FOR SELECT
  TO authenticated
  USING (public.user_can_access_response(response_id));

CREATE POLICY questionnaire_results_insert_staff
  ON public.questionnaire_results
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_staff()
    AND public.user_can_access_response(response_id)
  );

CREATE POLICY questionnaire_results_update_staff
  ON public.questionnaire_results
  FOR UPDATE
  TO authenticated
  USING (
    public.is_staff()
    AND public.user_can_access_response(response_id)
  )
  WITH CHECK (public.user_can_access_response(response_id));

-- -----------------------------------------------------------------------------
-- 11. Policies — therapy_resources
-- -----------------------------------------------------------------------------

CREATE POLICY therapy_resources_select_staff
  ON public.therapy_resources
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
  );

CREATE POLICY therapy_resources_select_patient_released
  ON public.therapy_resources
  FOR SELECT
  TO authenticated
  USING (
    public.current_role() = 'patient'
    AND is_active = true
    AND EXISTS (
      SELECT 1
      FROM public.patient_resource_access AS pra
      INNER JOIN public.patients AS pt ON pt.id = pra.patient_id
      WHERE pra.resource_id = therapy_resources.id
        AND pt.profile_id = auth.uid()
        AND pra.is_active = true
    )
  );

CREATE POLICY therapy_resources_insert_staff
  ON public.therapy_resources
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
  );

CREATE POLICY therapy_resources_update_staff
  ON public.therapy_resources
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.is_staff()
  );

-- -----------------------------------------------------------------------------
-- 12. Policies — patient_resource_access
-- -----------------------------------------------------------------------------

CREATE POLICY patient_resource_access_select
  ON public.patient_resource_access
  FOR SELECT
  TO authenticated
  USING (
    public.user_can_access_patient(patient_id)
    OR (
      public.current_role() = 'patient'
      AND patient_id = public.current_patient_id()
    )
  );

CREATE POLICY patient_resource_access_insert_staff
  ON public.patient_resource_access
  FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_staff()
    AND public.user_can_access_patient(patient_id)
    AND released_by_profile_id = auth.uid()
  );

CREATE POLICY patient_resource_access_update_staff
  ON public.patient_resource_access
  FOR UPDATE
  TO authenticated
  USING (
    public.is_staff()
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    public.is_staff()
    AND public.user_can_access_patient(patient_id)
  );

-- -----------------------------------------------------------------------------
-- 13. Policies — daily_monitors
-- -----------------------------------------------------------------------------

CREATE POLICY daily_monitors_select
  ON public.daily_monitors
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY daily_monitors_insert
  ON public.daily_monitors
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND (
      (
        public.current_role() = 'patient'
        AND patient_id = public.current_patient_id()
      )
      OR (
        public.is_staff()
        AND public.user_can_access_patient(patient_id)
      )
    )
  );

CREATE POLICY daily_monitors_update
  ON public.daily_monitors
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );
