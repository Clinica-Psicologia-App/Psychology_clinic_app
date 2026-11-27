-- =============================================================================
-- Convites de paciente: escrita somente pelas funções do servidor (service_role).
-- MARCO_CONVITES_SO_SERVIDOR, Etapa 1.
--
--  1. Remove as policies de INSERT/UPDATE/DELETE (psicóloga e platform_admin).
--     As policies de SELECT continuam como estão.
--  2. anon fica sem nenhum privilégio na tabela; authenticated fica só com SELECT.
--  3. validate_patient_invitation: search_path vazio e validação apenas quando
--     o que ela protege muda (criar, trocar clínica/quem convidou/responsável,
--     mudar para pendente ou aceito, mudar o prazo de um pendente). Cancelar,
--     expirar, ligar ids e ON DELETE SET NULL deixam de falhar quando o papel ou
--     a clínica de alguém mudou depois do convite.
--
-- ORDEM NA PRODUÇÃO: publicar ANTES a função create-patient-invitation que grava
-- com service_role. A versão anterior grava como a psicóloga e passa a falhar
-- assim que esta migration for aplicada.
--
-- Rollback comentado no fim do arquivo.
-- =============================================================================

BEGIN;

-- 1) Policies de escrita (as *_admin são de nomes antigos; só por segurança).
DROP POLICY IF EXISTS patient_invitations_insert_psychologist ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_update_psychologist ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_delete_psychologist ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_insert_platform_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_update_platform_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_delete_platform_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_insert_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_update_admin ON public.patient_invitations;
DROP POLICY IF EXISTS patient_invitations_delete_admin ON public.patient_invitations;

-- 2) Privilégios de tabela (REVOKE ALL também retira privilégios de coluna).
REVOKE ALL ON TABLE public.patient_invitations FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.patient_invitations TO authenticated;

-- 3) Gatilho de validação.
CREATE OR REPLACE FUNCTION public.validate_patient_invitation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_enters_live_status boolean;
  v_check_staff        boolean;
  v_check_expiry       boolean;
  v_invited_by_role    public.profile_role;
  v_invited_by_clinic  uuid;
  v_responsible_role   public.profile_role;
  v_responsible_clinic uuid;
BEGIN
  NEW.email      := lower(trim(NEW.email));
  NEW.full_name  := NULLIF(trim(COALESCE(NEW.full_name, '')), '');
  NEW.phone      := NULLIF(trim(COALESCE(NEW.phone, '')), '');

  IF TG_OP = 'INSERT' THEN
    v_check_staff  := true;
    v_check_expiry := NEW.status = 'pending';
  ELSE
    -- Passar a 'pending' ou 'accepted' é o que permite criar uma conta.
    v_enters_live_status := NEW.status IS DISTINCT FROM OLD.status
      AND NEW.status IN ('pending', 'accepted');
    v_check_staff := v_enters_live_status
      OR NEW.clinic_id IS DISTINCT FROM OLD.clinic_id
      OR NEW.invited_by IS DISTINCT FROM OLD.invited_by
      OR NEW.responsible_psychologist_id IS DISTINCT FROM OLD.responsible_psychologist_id;
    v_check_expiry := NEW.status = 'pending'
      AND (v_enters_live_status OR NEW.expires_at IS DISTINCT FROM OLD.expires_at);
  END IF;

  IF v_check_staff THEN
    SELECT role, clinic_id
      INTO v_invited_by_role, v_invited_by_clinic
    FROM public.profiles
    WHERE id = NEW.invited_by;

    -- Permite psychologist ou platform_admin como criador do convite.
    IF v_invited_by_role NOT IN ('psychologist', 'platform_admin')
      OR v_invited_by_clinic IS DISTINCT FROM NEW.clinic_id THEN
      RAISE EXCEPTION 'invited_by deve ser psicologo ou admin da clinica do convite';
    END IF;

    SELECT role, clinic_id
      INTO v_responsible_role, v_responsible_clinic
    FROM public.profiles
    WHERE id = NEW.responsible_psychologist_id;

    IF v_responsible_role IS DISTINCT FROM 'psychologist'::public.profile_role
      OR v_responsible_clinic IS DISTINCT FROM NEW.clinic_id THEN
      RAISE EXCEPTION 'responsible_psychologist_id deve ser psicologo da clinica';
    END IF;
  END IF;

  IF v_check_expiry AND NEW.expires_at <= timezone('utc', now()) THEN
    RAISE EXCEPTION 'expires_at deve estar no futuro para convites pendentes';
  END IF;

  IF NEW.status = 'accepted' AND NEW.accepted_at IS NULL THEN
    NEW.accepted_at := timezone('utc', now());
  END IF;

  RETURN NEW;
END;
$$;

-- Gatilho não precisa de EXECUTE para disparar.
REVOKE EXECUTE ON FUNCTION public.validate_patient_invitation() FROM PUBLIC, anon, authenticated;

-- 4) Conferência: aborta tudo se o estado final não for o esperado.
DO $check$
DECLARE
  v_table constant regclass := 'public.patient_invitations'::regclass;
  v_priv text;
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_policies
             WHERE schemaname = 'public' AND tablename = 'patient_invitations'
               AND cmd <> 'SELECT') THEN
    RAISE EXCEPTION 'patient_invitations ainda tem policy de escrita';
  END IF;
  FOREACH v_priv IN ARRAY ARRAY['INSERT','UPDATE','DELETE','TRUNCATE','REFERENCES','TRIGGER'] LOOP
    IF has_table_privilege('anon', v_table, v_priv)
      OR has_table_privilege('authenticated', v_table, v_priv) THEN
      RAISE EXCEPTION 'anon/authenticated ainda tem % em patient_invitations', v_priv;
    END IF;
  END LOOP;
  IF has_table_privilege('anon', v_table, 'SELECT')
    OR has_any_column_privilege('anon', v_table, 'SELECT, INSERT, UPDATE, REFERENCES')
    OR has_any_column_privilege('authenticated', v_table, 'INSERT, UPDATE, REFERENCES') THEN
    RAISE EXCEPTION 'privilégio de leitura/coluna não esperado em patient_invitations';
  END IF;
  IF NOT has_table_privilege('authenticated', v_table, 'SELECT')
    OR NOT has_table_privilege('service_role', v_table, 'SELECT')
    OR NOT has_table_privilege('service_role', v_table, 'INSERT')
    OR NOT has_table_privilege('service_role', v_table, 'UPDATE') THEN
    RAISE EXCEPTION 'privilégio necessário ausente em patient_invitations';
  END IF;
  IF NOT (SELECT relrowsecurity FROM pg_catalog.pg_class WHERE oid = v_table) THEN
    RAISE EXCEPTION 'RLS desligada em patient_invitations';
  END IF;
END
$check$;

COMMIT;

-- =============================================================================
-- ROLLBACK (estado do repositório antes desta migration). Na produção, conferir
-- contra a cópia das policies/grants salva em docs/rollback/ antes de aplicar.
-- Só é preciso se a função antiga (que grava como a psicóloga) voltar: reverter
-- este bloco ANTES de republicar a função antiga.
--
-- BEGIN;
-- GRANT ALL ON TABLE public.patient_invitations TO anon, authenticated;
--
-- CREATE POLICY patient_invitations_insert_psychologist ON public.patient_invitations
--   FOR INSERT TO authenticated
--   WITH CHECK (clinic_id = public.current_clinic_id()
--     AND public.current_role() = 'psychologist'
--     AND invited_by = auth.uid() AND responsible_psychologist_id = auth.uid());
-- CREATE POLICY patient_invitations_update_psychologist ON public.patient_invitations
--   FOR UPDATE TO authenticated
--   USING (clinic_id = public.current_clinic_id()
--     AND public.current_role() = 'psychologist' AND responsible_psychologist_id = auth.uid())
--   WITH CHECK (clinic_id = public.current_clinic_id()
--     AND public.current_role() = 'psychologist' AND responsible_psychologist_id = auth.uid());
-- CREATE POLICY patient_invitations_delete_psychologist ON public.patient_invitations
--   FOR DELETE TO authenticated
--   USING (clinic_id = public.current_clinic_id()
--     AND public.current_role() = 'psychologist' AND responsible_psychologist_id = auth.uid());
-- CREATE POLICY patient_invitations_insert_platform_admin ON public.patient_invitations
--   FOR INSERT TO authenticated
--   WITH CHECK (public.current_role()::text = 'platform_admin');
-- CREATE POLICY patient_invitations_update_platform_admin ON public.patient_invitations
--   FOR UPDATE TO authenticated
--   USING (public.current_role()::text = 'platform_admin')
--   WITH CHECK (public.current_role()::text = 'platform_admin');
-- CREATE POLICY patient_invitations_delete_platform_admin ON public.patient_invitations
--   FOR DELETE TO authenticated
--   USING (public.current_role()::text = 'platform_admin');
--
-- CREATE OR REPLACE FUNCTION public.validate_patient_invitation()
-- RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
-- AS $fn$
-- DECLARE
--   v_invited_by_role    public.profile_role;
--   v_invited_by_clinic  UUID;
--   v_responsible_role   public.profile_role;
--   v_responsible_clinic UUID;
-- BEGIN
--   NEW.email      := lower(trim(NEW.email));
--   NEW.full_name  := NULLIF(trim(COALESCE(NEW.full_name, '')), '');
--   NEW.phone      := NULLIF(trim(COALESCE(NEW.phone, '')), '');
--   SELECT role, clinic_id INTO v_invited_by_role, v_invited_by_clinic
--   FROM public.profiles WHERE id = NEW.invited_by;
--   IF v_invited_by_role NOT IN ('psychologist', 'platform_admin')
--     OR v_invited_by_clinic IS DISTINCT FROM NEW.clinic_id THEN
--     RAISE EXCEPTION 'invited_by deve ser psicologo ou admin da clinica do convite';
--   END IF;
--   SELECT role, clinic_id INTO v_responsible_role, v_responsible_clinic
--   FROM public.profiles WHERE id = NEW.responsible_psychologist_id;
--   IF v_responsible_role IS DISTINCT FROM 'psychologist'::public.profile_role
--     OR v_responsible_clinic IS DISTINCT FROM NEW.clinic_id THEN
--     RAISE EXCEPTION 'responsible_psychologist_id deve ser psicologo da clinica';
--   END IF;
--   IF NEW.status = 'pending' AND NEW.expires_at <= timezone('utc', now()) THEN
--     RAISE EXCEPTION 'expires_at deve estar no futuro para convites pendentes';
--   END IF;
--   IF NEW.status = 'accepted' AND NEW.accepted_at IS NULL THEN
--     NEW.accepted_at := timezone('utc', now());
--   END IF;
--   RETURN NEW;
-- END;
-- $fn$;
-- COMMIT;
-- =============================================================================
