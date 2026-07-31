-- =============================================================================
-- Migration: fecha os buracos das faixas de severidade.
--
-- Bug: faixas "Baixo 1.0–2.4 / Médio 2.5–3.9 / Ativado 4.0–6.0" deixam médias
-- como 2.44 ou 3.96 sem classificação (o classificador é inclusivo em ambas as
-- pontas). Ex.: YAMI do Roberto — Protetor Desligado 3.96 → severidade NULL.
--
-- Correção: Baixo passa a terminar em 2.4999 e Médio em 3.9999 (os scores são
-- arredondados a 4 casas, então nada escapa). Aplica a TODOS os instrumentos
-- que usam esse padrão de faixas.
-- =============================================================================

BEGIN;

UPDATE public.severity_ranges SET max_score = 2.4999 WHERE max_score = 2.4;
UPDATE public.severity_ranges SET max_score = 3.9999 WHERE max_score = 3.9;

COMMIT;
