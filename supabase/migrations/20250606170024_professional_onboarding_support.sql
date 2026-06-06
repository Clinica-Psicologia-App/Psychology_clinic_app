-- =============================================================================
-- Migration 024 (FH-01): onboarding de profissional com clínica opcional
-- =============================================================================

ALTER TABLE public.clinics
  ADD COLUMN IF NOT EXISTS clinic_type TEXT NOT NULL DEFAULT 'clinic',
  ADD COLUMN IF NOT EXISTS owner_profile_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL;

ALTER TABLE public.clinics
  ADD CONSTRAINT clinics_clinic_type_check
  CHECK (clinic_type IN ('clinic', 'personal'))
  NOT VALID;

COMMENT ON COLUMN public.clinics.clinic_type IS
  'Tipo da clínica: clinic para equipe/clínica tradicional, personal para clínica pessoal de profissional autônomo.';

COMMENT ON COLUMN public.clinics.owner_profile_id IS
  'Perfil proprietário da clínica pessoal ou criador inicial da clínica.';

CREATE INDEX IF NOT EXISTS idx_clinics_clinic_type
  ON public.clinics (clinic_type);

CREATE INDEX IF NOT EXISTS idx_clinics_owner_profile_id
  ON public.clinics (owner_profile_id);

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS crp TEXT;

COMMENT ON COLUMN public.profiles.crp IS
  'Registro profissional (CRP) quando aplicável ao perfil.';
