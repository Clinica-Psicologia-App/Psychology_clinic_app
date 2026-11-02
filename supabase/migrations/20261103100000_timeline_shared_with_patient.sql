-- =============================================================================
-- Linha do tempo: acontecimentos autorizados para o infográfico do paciente
-- (reunião de 31/10/2026, item F4).
--
-- Regra: todo acontecimento nasce ESCONDIDO do infográfico do paciente. Só o
-- psicólogo (staff com vínculo) pode marcar `shared_with_patient = true`.
-- O infográfico do paciente lê apenas pela RPC abaixo, que devolve só os
-- acontecimentos autorizados. A política de leitura da tabela não muda: o
-- paciente continua vendo na tela "Minha história" o que ele mesmo escreveu.
-- =============================================================================

BEGIN;

ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS shared_with_patient boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.patient_timeline_events.shared_with_patient IS
  'Autorização do psicólogo para o acontecimento aparecer no infográfico do paciente. Padrão: false.';

-- Só staff altera a autorização. Para o paciente, a coluna é imutável:
-- no INSERT nasce false; no UPDATE mantém o valor anterior.
CREATE OR REPLACE FUNCTION public.guard_timeline_shared_with_patient()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  IF public.current_role() = 'patient' THEN
    IF TG_OP = 'INSERT' THEN
      NEW.shared_with_patient := false;
    ELSE
      NEW.shared_with_patient := OLD.shared_with_patient;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_timeline_guard_shared_with_patient
  ON public.patient_timeline_events;
CREATE TRIGGER trg_timeline_guard_shared_with_patient
  BEFORE INSERT OR UPDATE ON public.patient_timeline_events
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_timeline_shared_with_patient();

-- Linha do tempo do infográfico do paciente: só o que foi autorizado.
-- SECURITY INVOKER: as políticas de RLS (clínica e vínculo) continuam valendo;
-- o filtro de autorização é aplicado em cima delas.
CREATE OR REPLACE FUNCTION public.get_patient_infographic_timeline(p_patient_id uuid)
RETURNS TABLE (
  id uuid,
  title text,
  period_label text,
  event_date date,
  life_chapter text,
  age_at_event smallint,
  age_to smallint
)
LANGUAGE sql
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT e.id, e.title, e.period_label, e.event_date, e.life_chapter,
         e.age_at_event, e.age_to
  FROM public.patient_timeline_events e
  WHERE e.patient_id = p_patient_id
    AND e.clinic_id = public.current_clinic_id()
    AND e.shared_with_patient = true
    AND public.user_can_access_patient(e.patient_id);
$$;

REVOKE ALL ON FUNCTION public.get_patient_infographic_timeline(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_patient_infographic_timeline(uuid) TO authenticated;

COMMIT;
