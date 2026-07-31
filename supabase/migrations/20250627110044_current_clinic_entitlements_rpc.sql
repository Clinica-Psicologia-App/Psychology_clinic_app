-- Leitura segura das permissões do plano da clínica atual para o app.

CREATE OR REPLACE FUNCTION public.get_current_clinic_entitlements()
RETURNS TABLE (
  feature_key TEXT,
  feature_name TEXT,
  is_enabled BOOLEAN,
  limit_value INTEGER,
  notes TEXT
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    entitlement.feature_key,
    entitlement.feature_name,
    entitlement.is_enabled,
    entitlement.limit_value,
    entitlement.notes
  FROM public.clinic_feature_entitlements AS entitlement
  WHERE
    entitlement.clinic_id = public.current_clinic_id()
    AND public.current_role()::TEXT IN ('platform_admin', 'psychologist', 'patient');
$$;

REVOKE ALL ON FUNCTION public.get_current_clinic_entitlements() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_current_clinic_entitlements() TO authenticated;

COMMENT ON FUNCTION public.get_current_clinic_entitlements() IS
  'Retorna apenas as permissões de módulos da clínica do usuário autenticado.';
