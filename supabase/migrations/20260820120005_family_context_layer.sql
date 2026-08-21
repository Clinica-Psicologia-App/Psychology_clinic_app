-- Clima e padrões familiares no Genograma (Tela 3) — perguntas sobre a
-- família como um todo (spec §32, §33). Etapas 12 e 13.
--
-- Colunas NOVAS em patient_family_context: as antigas (family_climate,
-- transgenerational_patterns) pertencem à tela antiga do initial_assessment
-- (listas menores) e ficam intactas. Aqui a spec unifica clima + padrões
-- numa fonte só, visível ao paciente.

-- ── Etapa 12 · Clima da família (§32) ────────────────────────────────────────
ALTER TABLE public.patient_family_context
  ADD COLUMN IF NOT EXISTS climate_traits TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS climate_note   TEXT;

ALTER TABLE public.patient_family_context
  ADD CONSTRAINT patient_family_context_climate_traits_valid
  CHECK (
    climate_traits <@ ARRAY[
      'showed_affection',       -- Demonstrávamos carinho
      'talked_feelings',        -- Conversávamos sobre nossos sentimentos
      'could_ask_help',         -- Podíamos pedir ajuda
      'support_when_needed',    -- Havia apoio quando alguém precisava
      'opinions_respected',     -- As opiniões eram respeitadas
      'could_disagree',         -- Podíamos discordar
      'conflicts_resolved',     -- Os conflitos eram conversados e resolvidos
      'room_to_play',           -- Havia espaço para brincar e se divertir
      'clear_rules',            -- Existiam regras claras
      'safe_to_err',            -- Era seguro cometer erros
      'many_criticisms',        -- Havia muitas críticas
      'had_to_be_perfect',      -- Era preciso fazer tudo muito bem
      'much_pressure',          -- Havia muita cobrança
      'comparison',             -- Havia comparação entre irmãos/outras pessoas
      'avoided_emotions',       -- Era comum evitar emoções
      'kept_feelings_in',       -- As pessoas guardavam o que sentiam
      'forbidden_topics',       -- Alguns assuntos não podiam ser falados
      'much_control',           -- Havia muito controle
      'frequent_fights',        -- As brigas eram frequentes
      'unpredictable_reactions',-- Nunca sabíamos como alguém iria reagir
      'little_affection',       -- Havia pouco carinho ou proximidade
      'kids_cared_for_adults',  -- As crianças precisavam cuidar dos adultos
      'adults_needs_first',     -- Necessidades dos adultos vinham antes
      'other'
    ]::text[]
  );

-- ── Etapa 13 · Padrões transgeracionais (§33) ────────────────────────────────
ALTER TABLE public.patient_family_context
  ADD COLUMN IF NOT EXISTS has_patterns        TEXT,
  ADD COLUMN IF NOT EXISTS pattern_traits      TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS pattern_generations TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS patterns_note       TEXT;

ALTER TABLE public.patient_family_context
  ADD CONSTRAINT patient_family_context_has_patterns_valid
  CHECK (
    has_patterns IS NULL
    OR has_patterns IN ('yes', 'maybe', 'dont_know', 'no')
  );

ALTER TABLE public.patient_family_context
  ADD CONSTRAINT patient_family_context_pattern_traits_valid
  CHECK (
    pattern_traits <@ ARRAY[
      -- Relacionamentos e rupturas
      'frequent_separations',   -- Separações frequentes
      'abandonment',            -- Abandono ou afastamento entre familiares
      'very_conflictual',       -- Relações muito conflituosas
      'abusive_relationships',  -- Relacionamentos abusivos
      'family_violence',        -- Violência familiar
      'hard_to_keep_bonds',     -- Dificuldade de manter vínculos próximos
      -- Formas de se relacionar
      'much_control',           -- Muito controle
      'frequent_criticism',     -- Críticas frequentes
      'perfectionism',          -- Cobrança ou perfeccionismo
      'little_affection_shown', -- Pouca demonstração de afeto
      'hard_to_talk_feelings',  -- Dificuldade de falar sobre sentimentos
      'over_caretakers',        -- Pessoas que cuidam muito e esquecem de si
      'early_responsibility',   -- Assumem responsabilidades muito cedo
      'ruptures_no_contact',    -- Rompimentos e longos períodos sem contato
      -- Dificuldades importantes
      'alcohol_problems',       -- Problemas relacionados ao álcool
      'drug_problems',          -- Problemas relacionados a outras drogas
      'psychological_suffering',-- Sofrimento psicológico/psiquiátrico importante
      'suicidal_behavior',      -- Comportamento suicida ou tentativas
      'serious_illness',        -- Doenças graves recorrentes
      'financial_crises',       -- Crises financeiras significativas
      'other'
    ]::text[]
  );

ALTER TABLE public.patient_family_context
  ADD CONSTRAINT patient_family_context_pattern_generations_valid
  CHECK (
    pattern_generations <@ ARRAY[
      'grandparents',          -- Avós ou gerações anteriores
      'parents_uncles',        -- Pais/tios
      'my_generation',         -- Minha geração
      'multiple_generations',  -- Mais de uma geração
      'dont_know'              -- Não sei
    ]::text[]
  );
