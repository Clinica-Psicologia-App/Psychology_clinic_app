-- Production governance: legal consent, clinical release status and audit log.

ALTER TABLE public.questionnaires
  ADD COLUMN IF NOT EXISTS clinical_status TEXT NOT NULL DEFAULT 'validation',
  ADD COLUMN IF NOT EXISTS clinically_approved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS clinically_approved_by UUID
    REFERENCES public.profiles (id) ON DELETE SET NULL;

ALTER TABLE public.questionnaires
  DROP CONSTRAINT IF EXISTS questionnaires_clinical_status_check;

ALTER TABLE public.questionnaires
  ADD CONSTRAINT questionnaires_clinical_status_check
  CHECK (clinical_status IN ('draft', 'validation', 'approved', 'suspended'));

COMMENT ON COLUMN public.questionnaires.clinical_status IS
  'Governança de uso: somente approved pode ser aplicado em produção.';

CREATE TABLE IF NOT EXISTS public.legal_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID NOT NULL REFERENCES public.clinics (id) ON DELETE CASCADE,
  profile_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  document_version TEXT NOT NULL,
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  source TEXT NOT NULL DEFAULT 'app',
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT legal_consents_document_type_check
    CHECK (document_type IN ('terms', 'privacy')),
  CONSTRAINT legal_consents_unique
    UNIQUE (profile_id, document_type, document_version)
);

CREATE INDEX IF NOT EXISTS idx_legal_consents_clinic
  ON public.legal_consents (clinic_id, accepted_at DESC);
CREATE INDEX IF NOT EXISTS idx_legal_consents_profile
  ON public.legal_consents (profile_id, accepted_at DESC);

ALTER TABLE public.legal_consents ENABLE ROW LEVEL SECURITY;

CREATE POLICY legal_consents_select_own_or_admin
  ON public.legal_consents
  FOR SELECT
  TO authenticated
  USING (
    profile_id = auth.uid()
    OR (
      clinic_id = public.current_clinic_id()
      AND public.current_role() = 'admin'
    )
  );

CREATE POLICY legal_consents_insert_own
  ON public.legal_consents
  FOR INSERT
  TO authenticated
  WITH CHECK (
    profile_id = auth.uid()
    AND clinic_id = public.current_clinic_id()
  );

CREATE TABLE IF NOT EXISTS public.audit_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id UUID REFERENCES public.clinics (id) ON DELETE SET NULL,
  actor_profile_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT NOT NULL,
  entity_id UUID,
  patient_id UUID REFERENCES public.patients (id) ON DELETE SET NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_audit_events_clinic_time
  ON public.audit_events (clinic_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_patient_time
  ON public.audit_events (patient_id, occurred_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_events_actor_time
  ON public.audit_events (actor_profile_id, occurred_at DESC);

ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_events_select_admin
  ON public.audit_events
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.current_role() = 'admin'
  );

CREATE OR REPLACE FUNCTION public.audit_sensitive_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row JSONB;
  v_clinic_id UUID;
  v_patient_id UUID;
  v_entity_id UUID;
BEGIN
  v_row := CASE WHEN TG_OP = 'DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
  v_clinic_id := NULLIF(v_row ->> 'clinic_id', '')::UUID;
  v_entity_id := NULLIF(v_row ->> 'id', '')::UUID;
  v_patient_id := CASE
    WHEN TG_TABLE_NAME = 'patients' THEN v_entity_id
    ELSE NULLIF(v_row ->> 'patient_id', '')::UUID
  END;

  INSERT INTO public.audit_events (
    clinic_id,
    actor_profile_id,
    action,
    entity_type,
    entity_id,
    patient_id,
    metadata
  )
  VALUES (
    v_clinic_id,
    auth.uid(),
    lower(TG_OP),
    TG_TABLE_NAME,
    v_entity_id,
    v_patient_id,
    jsonb_build_object('source', 'database_trigger')
  );

  RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END;
$$;

DO $$
DECLARE
  table_name TEXT;
BEGIN
  FOREACH table_name IN ARRAY ARRAY[
    'patients',
    'questionnaire_responses',
    'questionnaire_results',
    'patient_resource_access',
    'daily_monitors',
    'patient_check_ins',
    'patient_problems',
    'therapy_goals',
    'patient_timeline_events',
    'genogram_people',
    'genogram_relationships'
  ]
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS %I ON public.%I',
      'trg_' || table_name || '_audit',
      table_name
    );
    EXECUTE format(
      'CREATE TRIGGER %I AFTER INSERT OR UPDATE OR DELETE ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.audit_sensitive_change()',
      'trg_' || table_name || '_audit',
      table_name
    );
  END LOOP;
END;
$$;

REVOKE ALL ON public.audit_events FROM anon, authenticated;
GRANT SELECT ON public.audit_events TO authenticated;
GRANT SELECT, INSERT ON public.legal_consents TO authenticated;

