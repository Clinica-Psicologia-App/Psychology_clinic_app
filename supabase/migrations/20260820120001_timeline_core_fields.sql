-- Campos do núcleo do novo fluxo da Linha do Tempo (etapa Conhecer, Tela 2).
-- Núcleo = "quando, o quê, quem, como se sentiu" (as 4 etapas essenciais).
--
-- Fatia 0, parte do núcleo. As listas aqui vêm direto do documento da
-- cliente (spec ESQUEMACORE tela 2 e 3): emoções da seção 9, períodos da
-- seção 4. Os campos do "aprofundar" (área, necessidade, significado, hoje)
-- ficam para uma migração posterior, após a validação clínica das listas.

-- ── Emoções (Etapa 6 · seção 9) ──────────────────────────────────────────────
-- Hoje emotions_felt é texto livre; a spec quer checkbox de 12 opções.
-- A coluna antiga fica legada (dado de teste, descartável); o fluxo novo
-- escreve em emotion_keys.
ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS emotion_keys  TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS emotion_other TEXT;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_emotion_keys_valid
  CHECK (
    emotion_keys <@ ARRAY[
      'sad',        -- Triste
      'afraid',     -- Com medo
      'angry',      -- Com raiva
      'alone',      -- Sozinho(a)
      'ashamed',    -- Envergonhado(a)
      'guilty',     -- Culpado(a)
      'confused',   -- Confuso(a)
      'relieved',   -- Aliviado(a)
      'happy',      -- Feliz
      'loved',      -- Amado(a)
      'proud',      -- Orgulhoso(a)
      'safe',       -- Seguro(a)
      'other'       -- Outro (texto em emotion_other)
    ]::text[]
  );

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_emotion_other_required
  CHECK (
    NOT ('other' = ANY (emotion_keys))
    OR NULLIF(TRIM(COALESCE(emotion_other, '')), '') IS NOT NULL
  );

-- ── Precisão da idade (Etapa 1 · seção 4) ────────────────────────────────────
-- "Quantos anos você tinha?" com opção "Não lembro exatamente".
-- exact: idade informada em age_at_event; approximate: só a faixa
-- (life_chapter) foi indicada.
ALTER TABLE public.patient_timeline_events
  ADD COLUMN IF NOT EXISTS age_precision TEXT;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_age_precision_valid
  CHECK (
    age_precision IS NULL
    OR age_precision IN ('exact', 'approximate')
  );

-- ── Período da vida (Etapa 1 · seção 4) ──────────────────────────────────────
-- Realinha life_chapter às 6 opções da spec. Mantém 'maturity' (valor antigo,
-- sem correspondente na spec) só para não rejeitar dado legado — a UI nova
-- oferece apenas as 6 da spec.
ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_life_chapter_valid;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_life_chapter_valid
  CHECK (
    life_chapter IS NULL
    OR life_chapter IN (
      'early_years',    -- Primeiros anos
      'childhood',      -- Infância
      'adolescence',    -- Adolescência
      'adulthood',      -- Vida adulta
      'today',          -- Momento atual
      'cannot_locate',  -- Não consigo localizar exatamente
      'maturity'        -- legado (não oferecido na UI nova)
    )
  );
