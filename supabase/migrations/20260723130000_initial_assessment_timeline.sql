-- =============================================================================
-- Fluxo "Conhecer" — Tela 2 (Minha História / Linha do Tempo)
--
-- Estende `patient_timeline_events` em vez de criar estrutura paralela: o
-- documento exige "evitar duplicidade" entre Linha do Tempo e Genograma.
-- Já existiam: title, description, event_date, period_label, emotional_impact
-- (0–10, faixa que o documento pede). Faltavam o capítulo da vida, a idade no
-- evento, as crenças formadas e a autoria da camada dupla.
--
-- Listas de múltipla escolha são chaves validadas por CHECK (rótulos no Dart).
-- =============================================================================

ALTER TABLE public.patient_timeline_events
  ADD COLUMN life_chapter         TEXT,
  ADD COLUMN age_at_event         SMALLINT,
  ADD COLUMN belief_keys          TEXT[],
  ADD COLUMN belief_other         TEXT,
  ADD COLUMN filled_by_profile_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  ADD COLUMN filled_by_role       TEXT;

COMMENT ON COLUMN public.patient_timeline_events.life_chapter IS
  'Tela 2: capítulo da vida (Infância…Vida Hoje).';
COMMENT ON COLUMN public.patient_timeline_events.age_at_event IS
  'Tela 2: "Quantos anos você tinha?" — organiza a cronologia sem exigir data exata.';
COMMENT ON COLUMN public.patient_timeline_events.belief_keys IS
  'Tela 2: crenças formadas (múltipla escolha). Rótulos no app.';

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_life_chapter_valid
    CHECK (life_chapter IS NULL OR life_chapter IN (
      'childhood',     -- Minha Infância
      'adolescence',   -- Minha Adolescência
      'adulthood',     -- Minha Vida Adulta
      'maturity',      -- Maturidade
      'today'          -- Minha Vida Hoje
    )),
  ADD CONSTRAINT patient_timeline_events_age_at_event_range
    CHECK (age_at_event IS NULL OR (age_at_event >= 0 AND age_at_event <= 120)),
  ADD CONSTRAINT patient_timeline_events_belief_keys_valid
    CHECK (belief_keys IS NULL OR belief_keys <@ ARRAY[
      'not_important',          -- Não sou importante.
      'inadequate',             -- Sou inadequado(a).
      'must_please',            -- Preciso agradar para ser amado(a).
      'cannot_trust',           -- Não posso confiar nas pessoas.
      'must_handle_alone',      -- Tenho que resolver tudo sozinho(a).
      'must_be_perfect',        -- Preciso ser perfeito(a).
      'i_am_a_burden',          -- Sou um peso.
      'feelings_are_dangerous'  -- Mostrar sentimentos é perigoso.
    ]::text[]),
  ADD CONSTRAINT patient_timeline_events_filled_by_role_valid
    CHECK (filled_by_role IS NULL OR filled_by_role IN ('patient', 'psychologist', 'admin'));

CREATE INDEX idx_patient_timeline_events_life_chapter
  ON public.patient_timeline_events (patient_id, life_chapter);

-- -----------------------------------------------------------------------------
-- Comentários clínicos por evento — staff-only.
-- Tabela separada porque a linha do evento é legível pelo paciente.
-- -----------------------------------------------------------------------------

CREATE TABLE public.patient_timeline_event_notes (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id             UUID NOT NULL REFERENCES public.patients (id) ON DELETE CASCADE,
  event_id               UUID NOT NULL UNIQUE REFERENCES public.patient_timeline_events (id) ON DELETE CASCADE,
  clinical_comment       TEXT,
  updated_by_profile_id  UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

COMMENT ON TABLE public.patient_timeline_event_notes IS
  'Tela 2 — comentário clínico do terapeuta por evento. Exclusivo do terapeuta.';

CREATE INDEX idx_patient_timeline_event_notes_patient_id
  ON public.patient_timeline_event_notes (patient_id);

CREATE TRIGGER trg_patient_timeline_event_notes_set_updated_at
  BEFORE UPDATE ON public.patient_timeline_event_notes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.patient_timeline_event_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY patient_timeline_event_notes_all
  ON public.patient_timeline_event_notes
  FOR ALL
  TO authenticated
  USING (public.is_staff() AND public.user_can_access_patient(patient_id))
  WITH CHECK (public.is_staff() AND public.user_can_access_patient(patient_id));
