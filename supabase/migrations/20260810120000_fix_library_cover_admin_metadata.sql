-- Fecha uma brecha de escalonamento de privilégio em is_library_cover_admin().
--
-- A versão anterior (20260809120000) aceitava o role vindo de
-- `user_metadata`, que é editável pelo próprio usuário (auth.updateUser).
-- Assim, qualquer autenticado poderia se declarar admin e escrever no bucket
-- `library-covers`. Aqui removemos esse fallback: fica só o current_role()
-- (tabela profiles, fonte de verdade) e o app_metadata (só o service role edita).
--
-- As policies do bucket já usam esta função — basta redefini-la.

CREATE OR REPLACE FUNCTION public.is_library_cover_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    public.current_role()::TEXT IN ('platform_admin', 'admin'),
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('platform_admin', 'admin'),
    false
  );
$$;

REVOKE ALL ON FUNCTION public.is_library_cover_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_library_cover_admin() TO authenticated;
