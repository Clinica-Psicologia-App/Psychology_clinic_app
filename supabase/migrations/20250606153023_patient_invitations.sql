-- =============================================================================
-- Migration 023 (FH-02): convites de paciente e primeiro acesso
-- =============================================================================

CREATE TABLE public.patient_invitations (
  id                           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id                    UUID NOT NULL REFERENCES public.clinics (id) ON DELETE CASCADE,
  invited_by                   UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  responsible_psychologist_id  UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  email                        TEXT NOT NULL,
  full_name                    TEXT,
  phone                        TEXT,
  token_hash                   TEXT NOT NULL,
  status                       TEXT NOT NULL DEFAULT 'pending',
  expires_at                   TIMESTAMPTZ NOT NULL,
  accepted_at                  TIMESTAMPTZ,
  patient_profile_id           UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  patient_id                   UUID REFERENCES public.patients (id) ON DELETE SET NULL,
  created_at                   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at                   TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  CONSTRAINT patient_invitations_status_check
    CHECK (status IN ('pending', 'accepted', 'expired', 'revoked'))
);

COMMENT ON TABLE public.patient_invitations IS
  'Convites mínimos enviados por staff para o paciente concluir o primeiro acesso.';

COMMENT ON COLUMN public.patient_invitations.token_hash IS
  'Hash SHA-256 do token de convite. O token puro nunca é salvo no banco.';

COMMENT ON COLUMN public.patient_invitations.status IS
  'Estado do convite: pending, accepted, expired ou revoked.';

CREATE UNIQUE INDEX idx_patient_invitations_unique_pending_email
  ON public.patient_invitations (clinic_id, lower(email))
  WHERE status = 'pending';

CREATE INDEX idx_patient_invitations_clinic_id
  ON public.patient_invitations (clinic_id);

CREATE INDEX idx_patient_invitations_email
  ON public.patient_invitations (lower(email));

CREATE INDEX idx_patient_invitations_token_hash
  ON public.patient_invitations (token_hash);

CREATE INDEX idx_patient_invitations_status
  ON public.patient_invitations (status);

CREATE INDEX idx_patient_invitations_responsible_psychologist_id
  ON public.patient_invitations (responsible_psychologist_id);

CREATE OR REPLACE FUNCTION public.validate_patient_invitation()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_invited_by_role public.profile_role;
  v_invited_by_clinic UUID;
  v_responsible_role public.profile_role;
  v_responsible_clinic UUID;
BEGIN
  NEW.email := lower(trim(NEW.email));
  NEW.full_name := NULLIF(trim(COALESCE(NEW.full_name, '')), '');
  NEW.phone := NULLIF(trim(COALESCE(NEW.phone, '')), '');

  SELECT role, clinic_id
    INTO v_invited_by_role, v_invited_by_clinic
  FROM public.profiles
  WHERE id = NEW.invited_by;

  IF v_invited_by_role IS NULL THEN
    RAISE EXCEPTION 'invited_by inválido para patient_invitations';
  END IF;

  IF v_invited_by_role NOT IN ('admin', 'psychologist') THEN
    RAISE EXCEPTION 'invited_by deve ser admin ou psychologist';
  END IF;

  IF v_invited_by_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'invited_by deve pertencer à mesma clínica do convite';
  END IF;

  SELECT role, clinic_id
    INTO v_responsible_role, v_responsible_clinic
  FROM public.profiles
  WHERE id = NEW.responsible_psychologist_id;

  IF v_responsible_role IS NULL THEN
    RAISE EXCEPTION 'responsible_psychologist_id inválido para patient_invitations';
  END IF;

  IF v_responsible_role NOT IN ('admin', 'psychologist') THEN
    RAISE EXCEPTION 'responsible_psychologist_id deve ser admin ou psychologist';
  END IF;

  IF v_responsible_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'responsible_psychologist_id deve pertencer à mesma clínica do convite';
  END IF;

  IF NEW.status = 'pending' AND NEW.expires_at <= timezone('utc', now()) THEN
    RAISE EXCEPTION 'expires_at deve estar no futuro para convites pendentes';
  END IF;

  IF NEW.status = 'accepted' AND NEW.accepted_at IS NULL THEN
    NEW.accepted_at := timezone('utc', now());
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_invitations_set_updated_at
  BEFORE UPDATE ON public.patient_invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_patient_invitations_validate
  BEFORE INSERT OR UPDATE ON public.patient_invitations
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_patient_invitation();

ALTER TABLE public.patient_invitations ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_invitations_select_admin
  ON public.patient_invitations
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY patient_invitations_select_psychologist
  ON public.patient_invitations
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'psychologist'
    AND responsible_psychologist_id = auth.uid()
  );

CREATE POLICY patient_invitations_insert_admin
  ON public.patient_invitations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY patient_invitations_insert_psychologist
  ON public.patient_invitations
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'psychologist'
    AND invited_by = auth.uid()
    AND responsible_psychologist_id = auth.uid()
  );

CREATE POLICY patient_invitations_update_admin
  ON public.patient_invitations
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY patient_invitations_update_psychologist
  ON public.patient_invitations
  FOR UPDATE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'psychologist'
    AND responsible_psychologist_id = auth.uid()
  )
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'psychologist'
    AND responsible_psychologist_id = auth.uid()
  );

CREATE POLICY patient_invitations_delete_admin
  ON public.patient_invitations
  FOR DELETE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE POLICY patient_invitations_delete_psychologist
  ON public.patient_invitations
  FOR DELETE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'psychologist'
    AND responsible_psychologist_id = auth.uid()
  );
