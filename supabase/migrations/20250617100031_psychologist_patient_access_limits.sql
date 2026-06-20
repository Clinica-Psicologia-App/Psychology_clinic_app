-- Controle operacional de quantos pacientes cada psicólogo pode receber.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS can_receive_patients BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS patient_assignment_limit INTEGER;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_patient_assignment_limit_check;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_patient_assignment_limit_check
  CHECK (patient_assignment_limit IS NULL OR patient_assignment_limit >= 0);

COMMENT ON COLUMN public.profiles.can_receive_patients IS
  'Quando false, o profissional não pode receber novos pacientes ou convites.';

COMMENT ON COLUMN public.profiles.patient_assignment_limit IS
  'Limite máximo de pacientes atribuídos ao psicólogo; NULL significa sem limite.';

CREATE INDEX IF NOT EXISTS idx_profiles_patient_access_limits
  ON public.profiles (clinic_id, role, can_receive_patients);
