-- Camada emocional da relação no Genograma (Tela 3), fluxo unificado novo.
-- Etapas 3, 4, 7, 8, 9 e 10 da spec (§22, §23, §26, §27, §28, §29).
-- As Etapas 5 e 6 (§24 presença emocional, §25 como agia comigo) são
-- retiradas conforme a própria spec sugere — as colunas antigas
-- (emotional_presence, caregiver_traits) ficam legadas, não usadas.
--
-- Todas as colunas aqui são NOVAS: bond_quality/felt_needs/wished_needs
-- antigas pertencem à tela antiga do initial_assessment (listas diferentes)
-- e permanecem intactas até a consolidação.

-- ── Etapa 3 · Papel de cuidado (§22) ─────────────────────────────────────────
-- "Participou da sua criação...?" — 4 níveis (is_caregiver bool fica legado).
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS caregiver_role TEXT;

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_caregiver_role_valid
  CHECK (
    caregiver_role IS NULL
    OR caregiver_role IN (
      'important',   -- Sim, teve um papel importante
      'partial',     -- Sim, em alguns períodos
      'no',          -- Não
      'dont_know'    -- Não sei
    )
  );

-- ── Etapa 4 · Como era a relação (§23) ───────────────────────────────────────
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS closeness       SMALLINT,
  ADD COLUMN IF NOT EXISTS conflict        SMALLINT,
  ADD COLUMN IF NOT EXISTS bond_type       TEXT,
  ADD COLUMN IF NOT EXISTS bond_change_note TEXT;

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_closeness_range
  CHECK (closeness IS NULL OR (closeness >= 0 AND closeness <= 10));

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_conflict_range
  CHECK (conflict IS NULL OR (conflict >= 0 AND conflict <= 10));

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_bond_type_valid
  CHECK (
    bond_type IS NULL
    OR bond_type IN (
      'close_affectionate',  -- Próxima e afetiva
      'distant',             -- Distante
      'conflictual',         -- Conflituosa
      'ambivalent',          -- Ambivalente
      'broken',              -- Rompida
      'changed',             -- Mudou muito ao longo do tempo
      'other'                -- Outra
    )
  );

-- ── Etapa 7 · Como me sentia na relação (§26) ────────────────────────────────
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS felt_in_relationship TEXT[] NOT NULL DEFAULT '{}';

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_felt_in_relationship_valid
  CHECK (
    felt_in_relationship <@ ARRAY[
      'safe',                 -- Seguro(a)
      'loved',                -- Amado(a)
      'accepted',             -- Aceito(a)
      'understood',           -- Compreendido(a)
      'valued',               -- Valorizado(a)
      'respected',            -- Respeitado(a)
      'protected',            -- Protegido(a)
      'free_to_be',           -- Livre para ser quem eu era
      'free_to_speak',        -- Livre para falar do que sentia
      'encouraged_autonomy',  -- Incentivado(a) a aprender e fazer sozinho(a)
      'calm',                 -- Tranquilo(a)
      'happy',                -- Feliz
      'afraid',               -- Com medo
      'alone',                -- Sozinho(a)
      'rejected',             -- Rejeitado(a)
      'criticized',           -- Criticado(a)
      'controlled',           -- Controlado(a)
      'responsible_for_them', -- Responsável pelo bem-estar dessa pessoa
      'walking_on_eggshells', -- Precisava tomar cuidado com o que fazia/dizia
      'other'
    ]::text[]
  );

-- ── Etapas 8 e 9 · O que recebi / gostaria de ter recebido (§27–28) ──────────
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS received_needs    TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS wished_more_needs TEXT[] NOT NULL DEFAULT '{}';

-- Lista base de 18 (§27); wished_more_needs aceita também "got_what_needed".
ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_received_needs_valid
  CHECK (
    received_needs <@ ARRAY[
      'affection',           -- Carinho
      'attention',           -- Atenção
      'presence',            -- Presença
      'protection',          -- Proteção
      'safety',              -- Segurança
      'stability',           -- Estabilidade
      'understanding',       -- Compreensão
      'acceptance',          -- Aceitação
      'validation',          -- Validação do que eu sentia
      'respect',             -- Respeito
      'encouragement',       -- Incentivo
      'confidence',          -- Confiança na minha capacidade
      'freedom_to_be',       -- Liberdade para ser eu mesmo(a)
      'freedom_to_express',  -- Liberdade para expressar sentimentos e opiniões
      'space_to_learn',      -- Espaço para aprender a fazer coisas sozinho(a)
      'fair_limits',         -- Limites claros e justos
      'guidance',            -- Orientação
      'fun',                 -- Diversão e leveza
      'other'
    ]::text[]
  );

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_wished_more_needs_valid
  CHECK (
    wished_more_needs <@ ARRAY[
      'affection', 'attention', 'presence', 'protection', 'safety',
      'stability', 'understanding', 'acceptance', 'validation', 'respect',
      'encouragement', 'confidence', 'freedom_to_be', 'freedom_to_express',
      'space_to_learn', 'fair_limits', 'guidance', 'fun', 'other',
      'got_what_needed'  -- Sinto que recebi o que precisava
    ]::text[]
  );

-- ── Etapa 10 · Relação hoje (§29) ────────────────────────────────────────────
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS current_relationship      TEXT,
  ADD COLUMN IF NOT EXISTS current_relationship_note TEXT;

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_current_relationship_valid
  CHECK (
    current_relationship IS NULL
    OR current_relationship IN (
      'very_close',    -- Muito próxima
      'close',         -- Próxima
      'neutral',       -- Nem próxima nem distante
      'distant',       -- Distante
      'very_distant',  -- Muito distante
      'conflictual',   -- Conflituosa
      'broken',        -- Rompida
      'deceased',      -- Essa pessoa faleceu
      'other'
    )
  );
