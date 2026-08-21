-- Campos do "Aprofundar este momento" — as 5 etapas opcionais da Linha do
-- Tempo (etapa Conhecer, Tela 2), feitas depois do núcleo.
--
-- Listas literais do documento da cliente (spec ESQUEMACORE tela 2 e 3):
--   Etapa 3 (§6)  evento ou período
--   Etapa 4 (§7)  área da vida (até 2)
--   Etapa 7 (§10) do que precisava + recebeu
--   Etapa 8 (§11) significado (campo aberto único)
--   Etapa 9 (§12) e hoje (ainda influencia + áreas atuais)

-- ── Etapa 3 · Evento ou período (§6) ─────────────────────────────────────────
ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS event_recurrence TEXT,
  ADD COLUMN IF NOT EXISTS age_from         SMALLINT,
  ADD COLUMN IF NOT EXISTS age_to           SMALLINT;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_recurrence_valid
  CHECK (
    event_recurrence IS NULL
    OR event_recurrence IN (
      'once',       -- Uma vez
      'few_times',  -- Algumas vezes
      'frequent',   -- Acontecia com frequência
      'prolonged',  -- Foi uma situação que durou um período
      'unknown'     -- Não sei
    )
  );

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_age_from_range
  CHECK (age_from IS NULL OR (age_from >= 0 AND age_from <= 120));

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_age_to_range
  CHECK (age_to IS NULL OR (age_to >= 0 AND age_to <= 120));

-- ── Etapa 4 · Área da vida, até 2 (§7) ───────────────────────────────────────
-- Hoje `category` é texto único; a spec pede até 2 de uma lista de 13.
-- category_keys[] é o campo novo; a coluna antiga fica legada.
ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS category_keys TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_category_keys_valid
  CHECK (
    category_keys <@ ARRAY[
      'family',        -- Família
      'school',        -- Escola/estudos
      'friendships',   -- Amizades
      'romantic',      -- Relacionamentos amorosos
      'work',          -- Trabalho
      'health',        -- Saúde
      'life_change',   -- Mudança de vida
      'loss',          -- Perda/luto
      'arrival',       -- Nascimento ou chegada de alguém
      'achievement',   -- Conquista
      'difficult',     -- Experiência difícil
      'happy',         -- Experiência feliz
      'other'          -- Outro
    ]::text[]
    AND cardinality(category_keys) <= 2
  );

-- ── Etapa 7 · Do que precisava + recebeu (§10) ───────────────────────────────
-- emotional_need_keys já existe; realinha a lista à spec (11 opções).
ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_emotional_need_keys_valid;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_emotional_need_keys_valid
  CHECK (
    emotional_need_keys <@ ARRAY[
      'presence',       -- Sentir que alguém estaria comigo
      'safety',         -- Sentir-me seguro(a) e protegido(a)
      'affection',      -- Receber carinho e atenção
      'understanding',  -- Ser ouvido(a) e compreendido(a)
      'acceptance',     -- Ser aceito(a) como eu era
      'expression',     -- Poder falar sobre o que sentia
      'autonomy',       -- Ter liberdade para fazer minhas próprias escolhas
      'encouragement',  -- Receber incentivo e confiança
      'limits',         -- Ter limites e orientação
      'play',           -- Poder brincar, descansar ou me divertir
      'dont_know',      -- Não sei
      'other'           -- Outro
    ]::text[]
  );

-- "Você recebeu isso naquela época?"
ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS need_was_met TEXT;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_need_was_met_valid
  CHECK (
    need_was_met IS NULL
    OR need_was_met IN ('yes', 'partly', 'no', 'dont_know')
  );

-- ── Etapa 8 · Significado, campo aberto único (§11) ──────────────────────────
-- Substitui os 3 campos self/others/world_meaning (que ficam legados).
ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS meaning TEXT;

-- ── Etapa 9 · E hoje (§12) ───────────────────────────────────────────────────
-- present_influence (0–10) já existe. "Ainda influencia?" é novo.
ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS still_influences TEXT;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_still_influences_valid
  CHECK (
    still_influences IS NULL
    OR still_influences IN ('yes', 'maybe', 'no', 'dont_know')
  );

-- present_area_keys já existe; realinha à lista da spec (8 opções).
ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_present_area_keys_valid;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_present_area_keys_valid
  CHECK (
    present_area_keys <@ ARRAY[
      'self_view',      -- Como me vejo
      'relationships',  -- Meus relacionamentos
      'family',         -- Minha família
      'emotions',       -- Minhas emoções
      'work',           -- Meu trabalho ou estudos
      'choices',        -- Minhas escolhas
      'coping',         -- Minha maneira de lidar com dificuldades
      'other'           -- Outro
    ]::text[]
  );
