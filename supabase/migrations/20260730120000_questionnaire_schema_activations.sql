-- Psychologist manual schema activations
-- Stores schemas the therapist explicitly activates (overriding the automatic
-- score >= 4.0 threshold) so the patient sees them as psi-activated (◎ symbol).
--
-- activated_by_profile_id and clinic_id default to the authenticated session so
-- Flutter only needs to provide questionnaire_response_id, schema_code,
-- schema_name, and optionally psi_observation.

CREATE TABLE questionnaire_schema_activations (
  id                        UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  questionnaire_response_id UUID        NOT NULL
    REFERENCES questionnaire_responses(id) ON DELETE CASCADE,
  schema_code               TEXT        NOT NULL,
  schema_name               TEXT        NOT NULL,
  psi_observation           TEXT,
  activated_by_profile_id   UUID        NOT NULL DEFAULT auth.uid()
    REFERENCES profiles(id),
  clinic_id                 UUID        NOT NULL DEFAULT current_clinic_id()
    REFERENCES clinics(id),
  created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE (questionnaire_response_id, schema_code)
);

ALTER TABLE questionnaire_schema_activations ENABLE ROW LEVEL SECURITY;

-- Staff: full management within their clinic
CREATE POLICY "qsa_staff_all"
  ON questionnaire_schema_activations
  FOR ALL
  TO authenticated
  USING  (is_staff() AND clinic_id = current_clinic_id())
  WITH CHECK (is_staff() AND clinic_id = current_clinic_id());

-- Patients: read-only for their own reviewed responses (psi_observation stays private
-- by never being SELECTed in Flutter's query for the patient role)
CREATE POLICY "qsa_patient_select"
  ON questionnaire_schema_activations
  FOR SELECT
  TO authenticated
  USING (
    NOT is_staff()
    AND clinic_id = current_clinic_id()
    AND EXISTS (
      SELECT 1
      FROM   questionnaire_responses qr
      WHERE  qr.id = questionnaire_schema_activations.questionnaire_response_id
        AND  user_can_access_patient(qr.patient_id)
        AND  qr.reviewed_at IS NOT NULL
    )
  );
