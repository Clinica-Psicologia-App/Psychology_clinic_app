-- Tabela de junção pessoa ↔ evento: liga uma pessoa do genograma a um
-- acontecimento da linha do tempo. É o "elo entre as duas telas" da spec
-- (Etapa Conhecer, Telas 2 e 3): uma pessoa participa de vários eventos e
-- um evento envolve várias pessoas, sem duplicar o registro da pessoa.
--
-- Alimenta:
--   Linha do Tempo · Etapa 5  — "Quem fez parte desse momento?"
--   Genograma      · Etapa 1  — "Maria aparece em N momentos da sua história"
--   Genograma      · Etapa 11 — "Momentos da nossa história com Maria"
--
-- Fatia 0 da unificação Genograma + Linha do Tempo. Estrutural: não depende
-- das listas de opções clínicas que estão em validação.

CREATE TABLE public.timeline_event_people (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  clinic_id   UUID NOT NULL REFERENCES public.clinics (id) ON DELETE RESTRICT,
  patient_id  UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  event_id    UUID NOT NULL REFERENCES public.patient_timeline_events (id) ON DELETE CASCADE,
  person_id   UUID NOT NULL REFERENCES public.genogram_people (id) ON DELETE CASCADE,
  created_by  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),

  -- Uma pessoa aparece no máximo uma vez por evento.
  CONSTRAINT timeline_event_people_unique UNIQUE (event_id, person_id)
);

COMMENT ON TABLE public.timeline_event_people IS
  'Junção pessoa (genogram_people) ↔ evento (patient_timeline_events): o elo entre a Linha do Tempo e o Genograma.';

CREATE INDEX idx_timeline_event_people_clinic_id  ON public.timeline_event_people (clinic_id);
CREATE INDEX idx_timeline_event_people_patient_id ON public.timeline_event_people (patient_id);
CREATE INDEX idx_timeline_event_people_event_id   ON public.timeline_event_people (event_id);
CREATE INDEX idx_timeline_event_people_person_id  ON public.timeline_event_people (person_id);

-- Consistência: o evento e a pessoa precisam pertencer ao mesmo paciente e
-- à mesma clínica da própria junção — impede ligar dado de pacientes
-- diferentes. Mesmo padrão de validate_genogram_relationship_consistency.
CREATE OR REPLACE FUNCTION public.validate_timeline_event_person_consistency()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_event_patient  UUID;
  v_event_clinic   UUID;
  v_person_patient UUID;
  v_person_clinic  UUID;
BEGIN
  SELECT patient_id, clinic_id
    INTO v_event_patient, v_event_clinic
    FROM public.patient_timeline_events
    WHERE id = NEW.event_id;

  SELECT patient_id, clinic_id
    INTO v_person_patient, v_person_clinic
    FROM public.genogram_people
    WHERE id = NEW.person_id;

  IF v_event_patient IS NULL OR v_person_patient IS NULL THEN
    RAISE EXCEPTION 'Evento e pessoa da junção devem existir';
  END IF;

  IF v_event_patient <> NEW.patient_id
     OR v_person_patient <> NEW.patient_id THEN
    RAISE EXCEPTION 'Evento e pessoa devem pertencer ao mesmo paciente da junção';
  END IF;

  IF v_event_clinic <> NEW.clinic_id OR v_person_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'clinic_id da junção deve coincidir com evento e pessoa';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_timeline_event_people_validate
  BEFORE INSERT OR UPDATE ON public.timeline_event_people
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_timeline_event_person_consistency();

-- RLS: mesmo modelo das demais tabelas do genograma/timeline. O paciente
-- cria e remove as próprias ligações; staff opera nas de pacientes que
-- pode acessar. Não há UPDATE — uma ligação é criada ou removida.
ALTER TABLE public.timeline_event_people ENABLE ROW LEVEL SECURITY;

CREATE POLICY timeline_event_people_select
  ON public.timeline_event_people
  FOR SELECT
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );

CREATE POLICY timeline_event_people_insert
  ON public.timeline_event_people
  FOR INSERT
  TO authenticated
  WITH CHECK (
    clinic_id = public.current_clinic_id()
    AND (
      (
        public.current_role() = 'patient'
        AND patient_id = public.current_patient_id()
        AND (created_by IS NULL OR created_by = auth.uid())
      )
      OR (
        public.is_staff()
        AND public.user_can_access_patient(patient_id)
      )
    )
  );

CREATE POLICY timeline_event_people_delete
  ON public.timeline_event_people
  FOR DELETE
  TO authenticated
  USING (
    clinic_id = public.current_clinic_id()
    AND public.user_can_access_patient(patient_id)
  );
