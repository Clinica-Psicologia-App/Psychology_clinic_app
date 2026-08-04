-- Bucket público para as capas das obras da Biblioteca.
--
-- Leitura pública (as capas aparecem via URL em library_works.cover_url).
-- O upload é feito pelo dashboard/serviço (service_role), que ignora RLS.

INSERT INTO storage.buckets (id, name, public)
VALUES ('library-covers', 'library-covers', true)
ON CONFLICT (id) DO UPDATE SET public = EXCLUDED.public;
