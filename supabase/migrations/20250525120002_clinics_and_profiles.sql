-- =============================================================================
-- Migration 002: clínicas e perfis de usuário
-- =============================================================================

-- -----------------------------------------------------------------------------
-- clinics — tenant raiz; agrupa dados da clínica
-- -----------------------------------------------------------------------------

CREATE TABLE public.clinics (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  document    TEXT,
  email       TEXT,
  phone       TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT clinics_name_not_empty CHECK (char_length(trim(name)) > 0)
);

COMMENT ON TABLE public.clinics IS
  'Clínica (tenant). Raiz de isolamento de dados para pacientes, perfis e recursos.';

COMMENT ON COLUMN public.clinics.document IS
  'CNPJ ou documento fiscal da clínica.';

COMMENT ON COLUMN public.clinics.is_active IS
  'Indica se a clínica pode operar na plataforma.';

CREATE INDEX idx_clinics_is_active ON public.clinics (is_active);

-- -----------------------------------------------------------------------------
-- profiles — usuários da plataforma vinculados a uma clínica
-- Profissionais (admin, psychologist) e pacientes compartilham esta tabela.
-- -----------------------------------------------------------------------------

CREATE TABLE public.profiles (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  full_name   TEXT NOT NULL,
  email       TEXT NOT NULL,
  phone       TEXT,
  role        public.profile_role NOT NULL,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT profiles_full_name_not_empty CHECK (char_length(trim(full_name)) > 0),
  CONSTRAINT profiles_email_not_empty CHECK (char_length(trim(email)) > 0)
);

COMMENT ON TABLE public.profiles IS
  'Perfil de usuário por clínica. Substitui tabela separada de profissionais: admin e psychologist são roles aqui. Futuro: id pode ser igual a auth.users.id.';

COMMENT ON COLUMN public.profiles.role IS
  'admin: gestão da clínica; psychologist: profissional; patient: login do paciente.';

CREATE INDEX idx_profiles_clinic_id ON public.profiles (clinic_id);
CREATE INDEX idx_profiles_clinic_role ON public.profiles (clinic_id, role);
CREATE UNIQUE INDEX idx_profiles_clinic_email ON public.profiles (clinic_id, lower(email));
