-- =============================================================================
-- Migration 028: YRAI_FOUNDATION_V1 — scoring estruturado
-- Objetivo: promover o instrumento de snapshot legado para `scoring-demo-1`
-- sem alterar o fluxo do questionário nem o motor global.
--
-- Evidências disponíveis no repositório:
-- - versão ativa já existente: `8cab086f-0eb5-5c79-b4f3-23e5831d9289`
-- - escala Likert 1–6 definida em `questionnaire_versions`
-- - agrupamento já existente via `question_category_items`:
--   `YRAI_TOTAL` (`YRAI Geral`)
-- - pesos existentes nas categorias legado = 1
-- - não há documentação fonte para subestilos do YRAI nem `severity_ranges`;
--   por instrução explícita, esta migration NÃO inventa granularidade clínica
--   adicional nem faixas de severidade
-- =============================================================================

BEGIN;

INSERT INTO public.schema_domains (
  id,
  clinic_id,
  code,
  name,
  description,
  sort_order,
  is_active
)
VALUES (
  '6cbd846d-24ce-47a2-b7ae-0fa95afcc9a2',
  NULL,
  'COPING_DOMAIN_STYLES',
  'Estilos de Enfrentamento',
  'Domínio global para instrumentos de coping/enfrentamento. Nesta etapa, o YRAI é modelado apenas com o agrupamento geral documentado no repositório.',
  1,
  true
)
ON CONFLICT (id) DO UPDATE SET
  clinic_id = EXCLUDED.clinic_id,
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  sort_order = EXCLUDED.sort_order,
  is_active = EXCLUDED.is_active;

INSERT INTO public.schemas (
  id,
  domain_id,
  clinic_id,
  code,
  name,
  description,
  sort_order,
  is_active
)
VALUES (
  '00831455-0b3f-438f-b8d6-9fd2aed9478d',
  '6cbd846d-24ce-47a2-b7ae-0fa95afcc9a2',
  NULL,
  'YRAI_TOTAL',
  'YRAI Geral',
  'Apuração geral do inventário YRAI. O repositório atual não documenta subestilos clínicos adicionais para este instrumento.',
  1,
  true
)
ON CONFLICT (id) DO UPDATE SET
  domain_id = EXCLUDED.domain_id,
  clinic_id = EXCLUDED.clinic_id,
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  sort_order = EXCLUDED.sort_order,
  is_active = EXCLUDED.is_active;

WITH yrai_source AS (
  SELECT
    q.id AS question_id,
    q.order_index,
    qci.weight,
    qc.code AS category_code
  FROM public.questions q
  JOIN public.question_category_items qci
    ON qci.question_id = q.id
  JOIN public.question_categories qc
    ON qc.id = qci.category_id
  WHERE q.questionnaire_id = '24ca2f90-40b6-5f74-b7f7-7de4321588fe'
    AND qc.questionnaire_id = '24ca2f90-40b6-5f74-b7f7-7de4321588fe'
)
INSERT INTO public.question_scoring_rules (
  id,
  questionnaire_version_id,
  question_id,
  schema_id,
  domain_id,
  weight,
  reverse_score,
  min_value,
  max_value,
  sort_order,
  metadata
)
SELECT
  gen_random_uuid(),
  '8cab086f-0eb5-5c79-b4f3-23e5831d9289',
  src.question_id,
  '00831455-0b3f-438f-b8d6-9fd2aed9478d',
  '6cbd846d-24ce-47a2-b7ae-0fa95afcc9a2',
  COALESCE(src.weight, 1),
  false,
  NULL,
  NULL,
  src.order_index,
  jsonb_build_object(
    'source', '20250607124028_yrai_scoring.sql',
    'questionnaire_code', 'YRAI_FOUNDATION_V1',
    'category_code', src.category_code,
    'schema_modeling', 'single_schema_from_legacy_total',
    'severity_ranges_defined', false
  )
FROM yrai_source src
ON CONFLICT (questionnaire_version_id, question_id) DO UPDATE SET
  schema_id = EXCLUDED.schema_id,
  domain_id = EXCLUDED.domain_id,
  weight = EXCLUDED.weight,
  reverse_score = EXCLUDED.reverse_score,
  min_value = EXCLUDED.min_value,
  max_value = EXCLUDED.max_value,
  sort_order = EXCLUDED.sort_order,
  metadata = EXCLUDED.metadata;

-- Não inserir `severity_ranges` nesta etapa:
-- o repositório não contém cortes clínicos documentados para YRAI e a diretriz
-- vigente é não inventar faixas sem fonte explícita.

COMMIT;
