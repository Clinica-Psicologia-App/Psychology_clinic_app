-- B-4: Permite que platform_admin crie convites de pacientes.
-- O trigger validate_patient_invitation restringia invited_by apenas a
-- psychologist, bloqueando admins com HTTP 403 mesmo quando a edge function
-- for atualizada para aceitar platform_admin.

CREATE OR REPLACE FUNCTION public.validate_patient_invitation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_invited_by_role    public.profile_role;
  v_invited_by_clinic  UUID;
  v_responsible_role   public.profile_role;
  v_responsible_clinic UUID;
BEGIN
  NEW.email      := lower(trim(NEW.email));
  NEW.full_name  := NULLIF(trim(COALESCE(NEW.full_name, '')), '');
  NEW.phone      := NULLIF(trim(COALESCE(NEW.phone, '')), '');

  SELECT role, clinic_id
    INTO v_invited_by_role, v_invited_by_clinic
  FROM public.profiles
  WHERE id = NEW.invited_by;

  -- Permite psychologist ou platform_admin como criador do convite.
  IF v_invited_by_role NOT IN ('psychologist', 'platform_admin')
    OR v_invited_by_clinic IS DISTINCT FROM NEW.clinic_id THEN
    RAISE EXCEPTION 'invited_by deve ser psicologo ou admin da clinica do convite';
  END IF;

  SELECT role, clinic_id
    INTO v_responsible_role, v_responsible_clinic
  FROM public.profiles
  WHERE id = NEW.responsible_psychologist_id;

  IF v_responsible_role IS DISTINCT FROM 'psychologist'::public.profile_role
    OR v_responsible_clinic IS DISTINCT FROM NEW.clinic_id THEN
    RAISE EXCEPTION 'responsible_psychologist_id deve ser psicologo da clinica';
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
