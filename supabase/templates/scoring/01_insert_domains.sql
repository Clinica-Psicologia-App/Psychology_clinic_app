-- =============================================================================
-- Template 01: schema_domains
-- Substituir placeholders ANTES de executar. Não commitar dados clínicos reais.
-- Ordem: executar antes de 02_insert_schemas.sql
-- =============================================================================
--
-- Placeholders:
--   {{DOMAIN_ID}}         UUID fixo deste domínio
--   {{CLINIC_ID_OR_NULL}} NULL (catálogo global) ou UUID da clínica
--
-- Preencher com valores aprovados pela equipe clínica:
--   code, name, description, sort_order
-- =============================================================================

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
  '{{DOMAIN_ID}}'::uuid,
  {{CLINIC_ID_OR_NULL}},  -- literal NULL ou 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'::uuid
  '{{DOMAIN_CODE}}',      -- ex.: código estável, único no escopo (global ou clínica)
  '{{DOMAIN_NAME}}',      -- nome de exibição validado
  '{{DOMAIN_DESCRIPTION}}',  -- opcional; NULL se não houver
  {{DOMAIN_SORT_ORDER}},  -- inteiro >= 0
  true
)
ON CONFLICT (id) DO NOTHING;

-- Repita o bloco INSERT para cada domínio do instrumento (novo {{DOMAIN_ID}} por linha).
