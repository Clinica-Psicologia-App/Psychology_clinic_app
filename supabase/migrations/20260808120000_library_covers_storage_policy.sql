-- Permite ao admin de plataforma enviar/atualizar/remover capas no bucket
-- `library-covers` diretamente pelo app. A leitura continua pública (bucket
-- público). O upload usa a sessão autenticada do admin (anon key + JWT).

DROP POLICY IF EXISTS library_covers_admin_insert ON storage.objects;
CREATE POLICY library_covers_admin_insert
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'library-covers'
    AND public.current_role()::TEXT IN ('platform_admin', 'admin')
  );

DROP POLICY IF EXISTS library_covers_admin_update ON storage.objects;
CREATE POLICY library_covers_admin_update
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'library-covers'
    AND public.current_role()::TEXT IN ('platform_admin', 'admin')
  )
  WITH CHECK (
    bucket_id = 'library-covers'
    AND public.current_role()::TEXT IN ('platform_admin', 'admin')
  );

DROP POLICY IF EXISTS library_covers_admin_delete ON storage.objects;
CREATE POLICY library_covers_admin_delete
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'library-covers'
    AND public.current_role()::TEXT IN ('platform_admin', 'admin')
  );
