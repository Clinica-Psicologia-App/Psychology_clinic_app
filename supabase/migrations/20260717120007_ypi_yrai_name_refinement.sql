-- =============================================================================
-- Migration: refina os nomes do YPI e do YRAI conforme a nomenclatura final
--            do cliente (inclui os rótulos "Estilos Parentais" e "Inventário
--            de Evitação de Young").
-- =============================================================================

BEGIN;

-- YPI — inclui "Estilos Parentais" no nome
UPDATE public.questionnaires
SET name = 'YPI — Young Parenting Inventory (Estilos Parentais)'
WHERE code = 'PARENTAL_STYLES_V1';

-- YRAI — inclui "Inventário de Evitação de Young" no nome
UPDATE public.questionnaires
SET name = 'YRAI — Young-Rygh Avoidance Inventory (Inventário de Evitação de Young)'
WHERE code = 'YRAI_FOUNDATION_V1';

COMMIT;
