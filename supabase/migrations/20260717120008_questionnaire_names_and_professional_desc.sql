-- =============================================================================
-- Migration:
--   #2  Padroniza os nomes dos 5 instrumentos (sigla + nome em português no
--       título; nome em inglês + nº de alternativas na descrição).
--   #1  Separa a descrição em dois níveis:
--        - description               → intro curta e acessível (também ao paciente)
--        - professional_description  → explicação clínica (somente ao terapeuta)
--
-- Os textos de professional_description são um rascunho clínico inicial; a
-- terapeuta pode refiná-los depois.
-- =============================================================================

BEGIN;

-- ── Nova coluna (explicação clínica, só para o terapeuta) ─────────────────────
ALTER TABLE public.questionnaires
  ADD COLUMN IF NOT EXISTS professional_description TEXT;

COMMENT ON COLUMN public.questionnaires.professional_description IS
  'Explicação clínica do que o instrumento avalia. Exibida apenas ao terapeuta.';

-- ── YSQ ──────────────────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  name = 'YSQ-L3 — Questionário de Esquemas de Young',
  description = 'Ajuda a entender crenças e sentimentos profundos sobre você mesmo e sobre suas relações.',
  professional_description = 'Young Schema Questionnaire — Long Form 3 (90 alternativas). Avalia os 18 Esquemas Iniciais Desadaptativos, organizados em 5 domínios, formados a partir de necessidades emocionais não atendidas na infância.'
WHERE code = 'YSQ_FOUNDATION_V1';

-- ── YPI ──────────────────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  name = 'YPI — Inventário de Estilos Parentais de Young',
  description = 'Sobre como você percebeu o comportamento e o cuidado das figuras parentais na sua infância.',
  professional_description = 'Young Parenting Inventory (72 alternativas). Avalia a percepção das origens parentais dos esquemas, respondido separadamente para cada cuidador (mãe, pai ou terceiro).'
WHERE code = 'PARENTAL_STYLES_V1';

-- ── YAMI ─────────────────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  name = 'YAMI — Inventário de Modos Esquemáticos de Young',
  description = 'Sobre como você tende a reagir e se sentir em diferentes situações do dia a dia.',
  professional_description = 'Young-Atkinson Mode Inventory (186 alternativas). Avalia a frequência dos modos esquemáticos — estados emocionais e estratégias de enfrentamento — ativados no último mês.'
WHERE code = 'YAMI_MODES_FOUNDATION_V1';

-- ── YCI ──────────────────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  name = 'YCI — Inventário de Compensação de Young',
  description = 'Sobre estratégias que você usa para lidar com situações difíceis.',
  professional_description = 'Young Compensation Inventory (48 alternativas). Avalia estratégias de sobrecompensação usadas para lutar contra os Esquemas Iniciais Desadaptativos.'
WHERE code = 'YCI_FOUNDATION_V1';

-- ── YRAI ─────────────────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  name = 'YRAI — Inventário de Evitação de Young-Rygh',
  description = 'Sobre formas de evitar emoções ou pensamentos desconfortáveis.',
  professional_description = 'Young-Rygh Avoidance Inventory (40 alternativas). Avalia estratégias de evitação esquemática — cognitiva, emocional, comportamental e somática — usadas para não ativar os esquemas.'
WHERE code = 'YRAI_FOUNDATION_V1';

COMMIT;
