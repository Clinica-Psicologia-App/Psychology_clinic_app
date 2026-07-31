-- Planos, status comercial e permissões por clínica.

CREATE TABLE IF NOT EXISTS public.platform_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  monthly_price_cents INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  default_limits JSONB NOT NULL DEFAULT '{}'::jsonb,
  default_features JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT platform_plans_code_not_empty CHECK (btrim(code) <> ''),
  CONSTRAINT platform_plans_name_not_empty CHECK (btrim(name) <> ''),
  CONSTRAINT platform_plans_monthly_price_non_negative CHECK (monthly_price_cents >= 0)
);

CREATE TABLE IF NOT EXISTS public.clinic_plan_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics (id) ON DELETE CASCADE,
  plan_id UUID REFERENCES public.platform_plans (id) ON DELETE SET NULL,
  commercial_status TEXT NOT NULL DEFAULT 'trial',
  starts_at DATE NOT NULL DEFAULT CURRENT_DATE,
  ends_at DATE,
  notes TEXT,
  updated_by UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT clinic_plan_assignments_clinic_unique UNIQUE (clinic_id),
  CONSTRAINT clinic_plan_assignments_status_check CHECK (
    commercial_status IN ('trial', 'active', 'past_due', 'suspended', 'cancelled')
  ),
  CONSTRAINT clinic_plan_assignments_dates_check CHECK (
    ends_at IS NULL OR ends_at >= starts_at
  )
);

CREATE TABLE IF NOT EXISTS public.clinic_feature_entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics (id) ON DELETE CASCADE,
  feature_key TEXT NOT NULL,
  feature_name TEXT NOT NULL,
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  limit_value INTEGER,
  notes TEXT,
  updated_by UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT clinic_feature_entitlements_unique UNIQUE (clinic_id, feature_key),
  CONSTRAINT clinic_feature_entitlements_key_not_empty CHECK (btrim(feature_key) <> ''),
  CONSTRAINT clinic_feature_entitlements_name_not_empty CHECK (btrim(feature_name) <> ''),
  CONSTRAINT clinic_feature_entitlements_limit_non_negative CHECK (
    limit_value IS NULL OR limit_value >= 0
  )
);

CREATE INDEX IF NOT EXISTS idx_clinic_plan_assignments_plan_id
  ON public.clinic_plan_assignments (plan_id);

CREATE INDEX IF NOT EXISTS idx_clinic_plan_assignments_status
  ON public.clinic_plan_assignments (commercial_status);

CREATE INDEX IF NOT EXISTS idx_clinic_feature_entitlements_clinic
  ON public.clinic_feature_entitlements (clinic_id, is_enabled);

ALTER TABLE public.platform_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_plan_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clinic_feature_entitlements ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS platform_plans_select_platform_admin ON public.platform_plans;
CREATE POLICY platform_plans_select_platform_admin
  ON public.platform_plans
  FOR SELECT TO authenticated
  USING (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS platform_plans_write_platform_admin ON public.platform_plans;
CREATE POLICY platform_plans_write_platform_admin
  ON public.platform_plans
  FOR ALL TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS clinic_plan_assignments_select_platform_admin ON public.clinic_plan_assignments;
CREATE POLICY clinic_plan_assignments_select_platform_admin
  ON public.clinic_plan_assignments
  FOR SELECT TO authenticated
  USING (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS clinic_plan_assignments_write_platform_admin ON public.clinic_plan_assignments;
CREATE POLICY clinic_plan_assignments_write_platform_admin
  ON public.clinic_plan_assignments
  FOR ALL TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS clinic_feature_entitlements_select_platform_admin ON public.clinic_feature_entitlements;
CREATE POLICY clinic_feature_entitlements_select_platform_admin
  ON public.clinic_feature_entitlements
  FOR SELECT TO authenticated
  USING (public.current_role()::text = 'platform_admin');

DROP POLICY IF EXISTS clinic_feature_entitlements_write_platform_admin ON public.clinic_feature_entitlements;
CREATE POLICY clinic_feature_entitlements_write_platform_admin
  ON public.clinic_feature_entitlements
  FOR ALL TO authenticated
  USING (public.current_role()::text = 'platform_admin')
  WITH CHECK (public.current_role()::text = 'platform_admin');

DROP TRIGGER IF EXISTS trg_platform_plans_set_updated_at ON public.platform_plans;
CREATE TRIGGER trg_platform_plans_set_updated_at
  BEFORE UPDATE ON public.platform_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_clinic_plan_assignments_set_updated_at ON public.clinic_plan_assignments;
CREATE TRIGGER trg_clinic_plan_assignments_set_updated_at
  BEFORE UPDATE ON public.clinic_plan_assignments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_clinic_feature_entitlements_set_updated_at ON public.clinic_feature_entitlements;
CREATE TRIGGER trg_clinic_feature_entitlements_set_updated_at
  BEFORE UPDATE ON public.clinic_feature_entitlements
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

INSERT INTO public.platform_plans (code, name, description, monthly_price_cents, default_limits, default_features)
VALUES
  (
    'starter',
    'Starter',
    'Plano inicial para profissionais individuais e clínicas em validação.',
    0,
    '{"psychologists": 2, "active_patients": 50, "questionnaires": 5}'::jsonb,
    '{"patients": true, "questionnaires": true, "reports": false, "audit": false, "resources": false}'::jsonb
  ),
  (
    'professional',
    'Professional',
    'Plano recomendado para clínicas em operação.',
    0,
    '{"psychologists": 10, "active_patients": 300, "questionnaires": 20}'::jsonb,
    '{"patients": true, "questionnaires": true, "reports": true, "audit": true, "resources": true}'::jsonb
  ),
  (
    'enterprise',
    'Enterprise',
    'Plano avançado com limites personalizados.',
    0,
    '{"psychologists": null, "active_patients": null, "questionnaires": null}'::jsonb,
    '{"patients": true, "questionnaires": true, "reports": true, "audit": true, "resources": true, "advanced_governance": true}'::jsonb
  )
ON CONFLICT (code) DO UPDATE
SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  default_limits = EXCLUDED.default_limits,
  default_features = EXCLUDED.default_features,
  updated_at = timezone('utc', now());

INSERT INTO public.clinic_plan_assignments (clinic_id, plan_id, commercial_status, starts_at)
SELECT clinic.id, plan.id, 'trial', CURRENT_DATE
FROM public.clinics AS clinic
CROSS JOIN LATERAL (
  SELECT id FROM public.platform_plans WHERE code = 'starter' LIMIT 1
) AS plan
ON CONFLICT (clinic_id) DO NOTHING;

INSERT INTO public.clinic_feature_entitlements (clinic_id, feature_key, feature_name, is_enabled, limit_value)
SELECT clinic.id, feature.key, feature.name, feature.is_enabled, feature.limit_value
FROM public.clinics AS clinic
CROSS JOIN (
  VALUES
    ('patients', 'Pacientes', true, NULL::INTEGER),
    ('questionnaires', 'Questionários', true, NULL::INTEGER),
    ('reports', 'Relatórios', false, NULL::INTEGER),
    ('audit', 'Auditoria', false, NULL::INTEGER),
    ('resources', 'Recursos terapêuticos', false, NULL::INTEGER)
) AS feature(key, name, is_enabled, limit_value)
ON CONFLICT (clinic_id, feature_key) DO NOTHING;

COMMENT ON TABLE public.platform_plans IS
  'Planos comerciais disponíveis para clínicas/clientes da plataforma.';

COMMENT ON TABLE public.clinic_plan_assignments IS
  'Plano e status comercial atual por clínica.';

COMMENT ON TABLE public.clinic_feature_entitlements IS
  'Permissões e limites específicos de módulos por clínica.';
