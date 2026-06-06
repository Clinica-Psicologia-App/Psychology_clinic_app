-- =============================================================================
-- Template 02: schemas
-- Substituir placeholders ANTES de executar.
-- Pré-requisito: domínio já inserido (01_insert_domains.sql)
-- =============================================================================
--
-- Placeholders:
--   {{SCHEMA_ID}}         UUID fixo deste esquema
--   {{DOMAIN_ID}}         UUID do domínio pai
--   {{CLINIC_ID_OR_NULL}} Deve coincidir com clinic_id do domínio pai
-- =============================================================================

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
  '{{SCHEMA_ID}}'::uuid,
  '{{DOMAIN_ID}}'::uuid,
  {{CLINIC_ID_OR_NULL}},
  '{{SCHEMA_CODE}}',
  '{{SCHEMA_NAME}}',
  '{{SCHEMA_DESCRIPTION}}',
  {{SCHEMA_SORT_ORDER}},
  true
)
ON CONFLICT (id) DO NOTHING;

-- Repita para cada esquema mal-adaptativo mapeado no instrumento.
