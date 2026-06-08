-- =============================================================================
-- Migration 026: ATTACHMENT_STYLES_V1 — scoring estruturado
-- Objetivo: promover o instrumento de snapshot legado para `scoring-demo-1`
-- sem alterar o fluxo do questionário nem o motor global.
--
-- Evidências disponíveis no repositório:
-- - versão ativa já existente: `23796291-f46e-53ed-b6e1-c336c5a6e7ef`
-- - escala binária 0–1 definida em `questionnaire_versions`
-- - agrupamento já existente via `question_category_items`:
--   `ATTACHMENT_ANXIOUS`, `ATTACHMENT_SECURE`, `ATTACHMENT_AVOIDANT`
-- - pesos existentes nas categorias legado = 1
-- - não há documentação fonte para `severity_ranges`; por instrução explícita,
--   esta migration NÃO inventa faixas clínicas
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
  'c3c4ce09-ba06-4516-8bd0-7d7badada55f',
  NULL,
  'ATTACHMENT_DOMAIN_STYLES',
  'Estilos de Apego',
  'Domínio global do instrumento ATTACHMENT_STYLES_V1. Os três estilos são modelados como schemas.',
  0,
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
VALUES
  (
    '7b760c26-41af-4aa3-9020-fdef41a06c15',
    'c3c4ce09-ba06-4516-8bd0-7d7badada55f',
    NULL,
    'ATTACHMENT_STYLE_ANXIOUS',
    'Ansioso',
    'Estilo de apego ansioso mapeado a partir da categoria legado ATTACHMENT_ANXIOUS.',
    0,
    true
  ),
  (
    '75914588-6286-44d8-91d8-4ffb746cf615',
    'c3c4ce09-ba06-4516-8bd0-7d7badada55f',
    NULL,
    'ATTACHMENT_STYLE_SECURE',
    'Seguro',
    'Estilo de apego seguro mapeado a partir da categoria legado ATTACHMENT_SECURE.',
    1,
    true
  ),
  (
    'b6bdccd5-e032-4b5c-95a6-297fd343e8b3',
    'c3c4ce09-ba06-4516-8bd0-7d7badada55f',
    NULL,
    'ATTACHMENT_STYLE_AVOIDANT',
    'Evitante',
    'Estilo de apego evitante mapeado a partir da categoria legado ATTACHMENT_AVOIDANT.',
    2,
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

WITH attachment_source AS (
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
  WHERE q.questionnaire_id = 'b3faabc0-c64b-5b9b-b227-5dac19e1be71'
    AND qc.questionnaire_id = 'b3faabc0-c64b-5b9b-b227-5dac19e1be71'
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
  '23796291-f46e-53ed-b6e1-c336c5a6e7ef',
  src.question_id,
  CASE src.category_code
    WHEN 'ATTACHMENT_ANXIOUS' THEN '7b760c26-41af-4aa3-9020-fdef41a06c15'::uuid
    WHEN 'ATTACHMENT_SECURE' THEN '75914588-6286-44d8-91d8-4ffb746cf615'::uuid
    WHEN 'ATTACHMENT_AVOIDANT' THEN 'b6bdccd5-e032-4b5c-95a6-297fd343e8b3'::uuid
    ELSE NULL
  END,
  'c3c4ce09-ba06-4516-8bd0-7d7badada55f',
  COALESCE(src.weight, 1),
  false,
  NULL,
  NULL,
  src.order_index,
  jsonb_build_object(
    'source', '20250607120026_attachment_styles_scoring.sql',
    'questionnaire_code', 'ATTACHMENT_STYLES_V1',
    'category_code', src.category_code,
    'severity_ranges_defined', false
  )
FROM attachment_source src
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
-- o repositório não contém cortes clínicos documentados para o instrumento e
-- a diretriz vigente é não inventar faixas sem fonte explícita.

COMMIT;
