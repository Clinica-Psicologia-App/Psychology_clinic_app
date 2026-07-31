-- =============================================================================
-- Evolução do avatar de perfil: tipo, configuração e versionamento.
--
-- Esta migration é ADITIVA e IDEMPOTENTE. Ela é segura de aplicar tenha ou não
-- a migration 20260730140000_profile_avatar.sql já sido aplicada.
--
-- 1. avatar_type       → qual fonte está ativa (initials | photo | custom)
-- 2. avatar_path       → path no bucket, sem host; a URL é montada na aplicação
-- 3. avatar_config     → configuração do avatar geométrico (JSONB versionado)
-- 4. avatar_updated_at → carimbo usado para cache busting da URL
--
-- avatar_url é PRESERVADO como fallback de leitura para registros antigos.
-- Nenhuma coluna é removida e nenhum dado é destruído.
-- =============================================================================

-- ── 1. Colunas ───────────────────────────────────────────────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url        TEXT,
  ADD COLUMN IF NOT EXISTS avatar_type       TEXT NOT NULL DEFAULT 'initials',
  ADD COLUMN IF NOT EXISTS avatar_path       TEXT,
  ADD COLUMN IF NOT EXISTS avatar_config     JSONB,
  ADD COLUMN IF NOT EXISTS avatar_updated_at TIMESTAMPTZ;

COMMENT ON COLUMN public.profiles.avatar_url IS
  'LEGADO — URL pública completa. Mantida como fallback de leitura. Novas gravações usam avatar_path.';
COMMENT ON COLUMN public.profiles.avatar_type IS
  'Fonte ativa do avatar: initials (iniciais do nome), photo (foto real) ou custom (avatar geométrico via avatar_config).';
COMMENT ON COLUMN public.profiles.avatar_path IS
  'Path do arquivo dentro do bucket avatars, sem host. Ex.: {uid}/profile/photo.webp';
COMMENT ON COLUMN public.profiles.avatar_config IS
  'Configuração do avatar geométrico, renderizado no cliente. JSONB versionado por schemaVersion.';
COMMENT ON COLUMN public.profiles.avatar_updated_at IS
  'Última alteração do avatar. Usado para cache busting da URL da foto.';

-- ── 2. Constraints ───────────────────────────────────────────────────────────

-- Impede valores arbitrários vindos do cliente.
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_avatar_type_valid;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_avatar_type_valid
  CHECK (avatar_type IN ('initials', 'photo', 'custom'));

-- avatar_config só pode ser objeto JSON, nunca array/escalar, e é limitado em
-- tamanho para impedir que o cliente use a coluna como armazenamento genérico.
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_avatar_config_shape;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_avatar_config_shape
  CHECK (
    avatar_config IS NULL
    OR (
      jsonb_typeof(avatar_config) = 'object'
      AND length(avatar_config::text) <= 2048
    )
  );

-- ── 3. Trigger de avatar_updated_at ──────────────────────────────────────────
-- Carimba automaticamente quando qualquer fonte de avatar muda. Isso garante o
-- cache busting mesmo que a aplicação esqueça de enviar o campo.

CREATE OR REPLACE FUNCTION public.touch_profile_avatar_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.avatar_type   IS DISTINCT FROM OLD.avatar_type
    OR NEW.avatar_path IS DISTINCT FROM OLD.avatar_path
    OR NEW.avatar_url  IS DISTINCT FROM OLD.avatar_url
    OR NEW.avatar_config IS DISTINCT FROM OLD.avatar_config THEN
    NEW.avatar_updated_at := timezone('utc', now());
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_profiles_touch_avatar_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_touch_avatar_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.touch_profile_avatar_updated_at();

-- ── 4. Backfill de registros existentes ──────────────────────────────────────
-- Quem já tem avatar_url passa a ser 'photo'; o resto fica em 'initials'.

UPDATE public.profiles
SET avatar_type = 'photo'
WHERE avatar_url IS NOT NULL
  AND trim(avatar_url) <> ''
  AND avatar_type = 'initials';

-- ── 5. Bucket ────────────────────────────────────────────────────────────────
-- Idempotente: cria se a migration anterior não rodou, ou reafirma a config.

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5 MB (proteção de borda; a app envia ~100 KB)
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public             = EXCLUDED.public,
      file_size_limit    = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ── 6. Policies de Storage ───────────────────────────────────────────────────
-- Endurecidas: além de exigir que a primeira pasta seja o uid do usuário, agora
-- restringem o path exato permitido. Isso impede que a pasta do usuário vire um
-- storage genérico e bloqueia nomes de arquivo arbitrários.
--
-- Path autorizado: {auth.uid()}/profile/photo.{jpg|jpeg|png|webp}
--
-- O avatar geométrico NÃO usa Storage — ele mora em avatar_config e é
-- renderizado no cliente, então não há arquivo a proteger.

DROP POLICY IF EXISTS avatars_public_read       ON storage.objects;
DROP POLICY IF EXISTS avatars_insert_own_folder ON storage.objects;
DROP POLICY IF EXISTS avatars_update_own_folder ON storage.objects;
DROP POLICY IF EXISTS avatars_delete_own_folder ON storage.objects;

CREATE POLICY avatars_public_read
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'avatars');

-- INSERT e UPDATE são policies separadas de propósito: um upsert do Storage
-- executa INSERT ... ON CONFLICT DO UPDATE, e o Postgres avalia o WITH CHECK de
-- ambas. Manter as duas com a mesma condição garante que o upsert não contorne
-- a validação de path.
CREATE POLICY avatars_insert_own_photo
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND name ~ ('^' || auth.uid()::text || '/profile/photo\.(jpg|jpeg|png|webp)$')
  );

CREATE POLICY avatars_update_own_photo
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND name ~ ('^' || auth.uid()::text || '/profile/photo\.(jpg|jpeg|png|webp)$')
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND name ~ ('^' || auth.uid()::text || '/profile/photo\.(jpg|jpeg|png|webp)$')
  );

-- DELETE continua permitindo qualquer arquivo dentro da própria pasta, para que
-- o usuário consiga limpar arquivos gravados sob a convenção antiga
-- ({uid}/avatar.jpg) sem ficar com órfãos presos no bucket.
CREATE POLICY avatars_delete_own_folder
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
