-- =============================================================================
-- Perfil do usuário — foto de perfil.
--
-- 1. Coluna avatar_url em profiles (URL pública do arquivo no Storage, ou a
--    foto vinda de um provedor OAuth como o Google).
-- 2. Bucket público `avatars` no Supabase Storage.
-- 3. Policies: leitura pública; escrita restrita à própria pasta do usuário
--    (convenção de path: avatars/{auth.uid()}/arquivo.jpg).
--
-- A policy profiles_update_self_or_admin já permite ao usuário atualizar a
-- própria linha, e o trigger prevent_profile_privilege_escalation continua
-- bloqueando role/clinic_id/is_active — avatar_url e phone ficam liberados.
-- =============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

COMMENT ON COLUMN public.profiles.avatar_url IS
  'URL pública da foto de perfil (Supabase Storage ou provedor OAuth). NULL = usa as iniciais do nome.';

-- ── Bucket ───────────────────────────────────────────────────────────────────
-- Público na leitura para que a URL possa ser usada direto no <img>/NetworkImage.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public             = EXCLUDED.public,
      file_size_limit    = EXCLUDED.file_size_limit,
      allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ── Policies em storage.objects ──────────────────────────────────────────────

DROP POLICY IF EXISTS avatars_public_read ON storage.objects;
CREATE POLICY avatars_public_read
  ON storage.objects
  FOR SELECT
  TO public
  USING (bucket_id = 'avatars');

DROP POLICY IF EXISTS avatars_insert_own_folder ON storage.objects;
CREATE POLICY avatars_insert_own_folder
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS avatars_update_own_folder ON storage.objects;
CREATE POLICY avatars_update_own_folder
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  )
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS avatars_delete_own_folder ON storage.objects;
CREATE POLICY avatars_delete_own_folder
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
