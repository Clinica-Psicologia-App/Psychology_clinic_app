-- =============================================================================
-- Conceituação no formato do Formulário 3.8: cabeçalho digitado + logo própria.
--
-- 1. case_conceptualizations.form_header (JSONB): nome da psicóloga, data do
--    formulário, nº de sessões, meses desde a 1ª sessão. Digitado pela
--    psicóloga. JSONB porque é lido/gravado junto e não é filtrado em SQL.
-- 2. profiles.document_logo_path / document_logo_updated_at: logo que a
--    psicóloga usa nos documentos. NULL = o app usa a logo padrão do EsquemaCore.
-- 3. Bucket PRIVADO `document-logos` (png/jpeg/webp, 2 MB). Path único
--    permitido: {auth.uid()}/logo.{png|jpg|jpeg|webp}. Só o dono lê, grava,
--    troca e apaga; não há leitura pública nem entre colegas da clínica.
--
-- ADITIVA: não altera nem apaga dados, não muda a RLS de case_conceptualizations
-- nem de profiles (profiles_update_self_or_admin já cobre a própria linha e o
-- trigger de privilégios continua barrando role/clinic_id/is_active).
-- As demais mudanças (N/A na seção 5, X na 7.2, 11.2/11.3/11.4) moram dentro de
-- JSONB já existente (functioning, unmet_needs, therapeutic_relationship): sem DDL.
--
-- ROLLBACK (só se as colunas estiverem vazias e o bucket sem objetos):
--   SELECT count(*) FROM public.case_conceptualizations WHERE form_header <> '{}'::jsonb;
--   SELECT count(*) FROM public.profiles WHERE document_logo_path IS NOT NULL;
--   SELECT count(*) FROM storage.objects WHERE bucket_id = 'document-logos';
--   -- se tudo 0:
--   DROP POLICY IF EXISTS document_logos_select_own ON storage.objects;
--   DROP POLICY IF EXISTS document_logos_insert_own ON storage.objects;
--   DROP POLICY IF EXISTS document_logos_update_own ON storage.objects;
--   DROP POLICY IF EXISTS document_logos_delete_own ON storage.objects;
--   DELETE FROM storage.buckets WHERE id = 'document-logos';
--   ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_document_logo_path_valid;
--   ALTER TABLE public.profiles DROP COLUMN IF EXISTS document_logo_path,
--                               DROP COLUMN IF EXISTS document_logo_updated_at;
--   ALTER TABLE public.case_conceptualizations DROP CONSTRAINT IF EXISTS case_conceptualizations_form_header_shape;
--   ALTER TABLE public.case_conceptualizations DROP COLUMN IF EXISTS form_header;
-- =============================================================================

BEGIN;

-- ── 1. Cabeçalho do formulário ───────────────────────────────────────────────
ALTER TABLE public.case_conceptualizations
  ADD COLUMN IF NOT EXISTS form_header JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN public.case_conceptualizations.form_header IS
  'Cabeçalho do formulário 3.8, digitado pela psicóloga: {therapist_name, form_date (YYYY-MM-DD), sessions_count, months_since_first}.';

ALTER TABLE public.case_conceptualizations
  DROP CONSTRAINT IF EXISTS case_conceptualizations_form_header_shape;
ALTER TABLE public.case_conceptualizations
  ADD CONSTRAINT case_conceptualizations_form_header_shape
  CHECK (
    jsonb_typeof(form_header) = 'object'
    AND length(form_header::text) <= 2048
  );

-- ── 2. Logo no perfil ────────────────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS document_logo_path TEXT,
  ADD COLUMN IF NOT EXISTS document_logo_updated_at TIMESTAMPTZ;

COMMENT ON COLUMN public.profiles.document_logo_path IS
  'Path da logo dos documentos no bucket privado document-logos, sem host: {id}/logo.ext. NULL = logo padrão do EsquemaCore.';
COMMENT ON COLUMN public.profiles.document_logo_updated_at IS
  'Última troca da logo (cache busting).';

-- O path só pode apontar para a pasta do próprio perfil.
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_document_logo_path_valid;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_document_logo_path_valid
  CHECK (
    document_logo_path IS NULL
    OR document_logo_path ~ ('^' || id::text || '/logo\.(png|jpg|jpeg|webp)$')
  );

CREATE OR REPLACE FUNCTION public.touch_profile_document_logo_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  IF NEW.document_logo_path IS DISTINCT FROM OLD.document_logo_path THEN
    NEW.document_logo_updated_at := timezone('utc', now());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_touch_document_logo_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_touch_document_logo_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_profile_document_logo_updated_at();

-- ── 3. Bucket privado + policies do dono ─────────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'document-logos',
  'document-logos',
  false,
  2097152, -- 2 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public             = EXCLUDED.public,
      file_size_limit    = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

DROP POLICY IF EXISTS document_logos_select_own ON storage.objects;
DROP POLICY IF EXISTS document_logos_insert_own ON storage.objects;
DROP POLICY IF EXISTS document_logos_update_own ON storage.objects;
DROP POLICY IF EXISTS document_logos_delete_own ON storage.objects;

CREATE POLICY document_logos_select_own
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (
    bucket_id = 'document-logos'
    AND name ~ ('^' || auth.uid()::text || '/logo\.(png|jpg|jpeg|webp)$')
  );

-- INSERT e UPDATE com a mesma condição: o upsert do Storage avalia as duas.
-- Exigem perfil ativo que não seja paciente (só staff grava logo).
CREATE POLICY document_logos_insert_own
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'document-logos'
    AND name ~ ('^' || auth.uid()::text || '/logo\.(png|jpg|jpeg|webp)$')
    AND EXISTS (
      SELECT 1 FROM public.profiles AS me
      WHERE me.id = auth.uid() AND me.is_active IS TRUE AND me.role::text <> 'patient'
    )
  );

CREATE POLICY document_logos_update_own
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'document-logos'
    AND name ~ ('^' || auth.uid()::text || '/logo\.(png|jpg|jpeg|webp)$')
    AND EXISTS (
      SELECT 1 FROM public.profiles AS me
      WHERE me.id = auth.uid() AND me.is_active IS TRUE AND me.role::text <> 'patient'
    )
  )
  WITH CHECK (
    bucket_id = 'document-logos'
    AND name ~ ('^' || auth.uid()::text || '/logo\.(png|jpg|jpeg|webp)$')
    AND EXISTS (
      SELECT 1 FROM public.profiles AS me
      WHERE me.id = auth.uid() AND me.is_active IS TRUE AND me.role::text <> 'patient'
    )
  );

CREATE POLICY document_logos_delete_own
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'document-logos'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ── 4. Guarda de UPDATE de profiles: libera SÓ as 2 colunas da logo ──────────
-- Mesma função de 20260913120000; a única diferença é a allowlist de
-- autoatendimento (+ document_logo_path, document_logo_updated_at).
-- role, clinic_id, is_active e demais colunas continuam protegidos.
-- (Rollback: reaplicar a função de 20260913120000.)
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
      'avatar_config', 'avatar_updated_at', 'updated_at',
      'document_logo_path', 'document_logo_updated_at'
    ]) IS NOT DISTINCT FROM (to_jsonb(OLD) - ARRAY[
      'full_name', 'phone', 'avatar_url', 'avatar_type', 'avatar_path',
      'avatar_config', 'avatar_updated_at', 'updated_at',
      'document_logo_path', 'document_logo_updated_at'
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

COMMIT;
