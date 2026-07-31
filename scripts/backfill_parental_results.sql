-- =============================================================================
-- Backfill: corrige snapshots de Estilos Parentais corrompidos pelo bug
--           answerMap.length (sempre 0) → answerMap.size (correto)
--
-- Campos corrigidos em questionnaire_results.snapshot:
--   snapshot.answer_count                         (soma entre contextos)
--   snapshot.contexts[i].answer_count
--   snapshot.contexts[i].completion_ratio
--   snapshot.contexts[i].summary.answered_items
--   snapshot.contexts[i].summary.average_score
--
-- Campos preservados (já estavam corretos):
--   snapshot.contexts[i].summary.raw_score
--   snapshot.contexts[i].summary.weighted_score
--   snapshot.contexts[i].summary.max_possible_score
--   snapshot.contexts[i].schemas   (usava agg.items.length, não answerMap.size)
--
-- Pré-requisito: aplicar o fix no código (answerMap.size) antes de rodar isto,
--               para que novas respostas já sejam gravadas corretamente.
--
-- Como executar:
--   LOCAL:   psql "postgresql://postgres:postgres@localhost:54322/postgres" \
--              -f scripts/backfill_parental_results.sql
--
--   REMOTO:  psql "$SUPABASE_DB_URL" -f scripts/backfill_parental_results.sql
--            (obter SUPABASE_DB_URL em: Dashboard → Settings → Database → Connection string)
-- =============================================================================

BEGIN;

-- ── Diagnóstico ──────────────────────────────────────────────────────────────

DO $$
DECLARE
  total_corrupted INT;
  total_contexts  INT;
BEGIN
  SELECT COUNT(*) INTO total_corrupted
  FROM public.questionnaire_results
  WHERE snapshot->>'category_code' = 'PARENTAL_CONTEXTS'
    AND (snapshot->>'answer_count')::INT = 0;

  SELECT COALESCE(SUM(jsonb_array_length(snapshot->'contexts')), 0) INTO total_contexts
  FROM public.questionnaire_results
  WHERE snapshot->>'category_code' = 'PARENTAL_CONTEXTS'
    AND (snapshot->>'answer_count')::INT = 0;

  RAISE NOTICE '=== BACKFILL: Estilos Parentais ===';
  RAISE NOTICE 'Resultados corrompidos encontrados : %', total_corrupted;
  RAISE NOTICE 'Snapshots de contexto a corrigir  : %', total_contexts;
END;
$$;

-- ── Backfill ─────────────────────────────────────────────────────────────────

WITH fixed_contexts AS (
  SELECT
    qr.id                         AS result_id,
    SUM(cnt.answer_count)::INT    AS total_answered,
    jsonb_agg(
      -- Recalcula os 4 campos corrompidos dentro de cada contexto
      jsonb_set(
        jsonb_set(
          jsonb_set(
            jsonb_set(
              ctx.value,
              '{answer_count}',
              to_jsonb(cnt.answer_count::INT)
            ),
            '{completion_ratio}',
            to_jsonb(
              CASE
                WHEN (ctx.value->>'total_questions')::INT > 0
                  THEN cnt.answer_count::NUMERIC
                       / (ctx.value->>'total_questions')::INT
                ELSE 0::NUMERIC
              END
            )
          ),
          '{summary,answered_items}',
          to_jsonb(cnt.answer_count::INT)
        ),
        '{summary,average_score}',
        CASE
          WHEN cnt.answer_count > 0
            THEN to_jsonb(
              (ctx.value->'summary'->>'raw_score')::NUMERIC
              / cnt.answer_count
            )
          ELSE 'null'::JSONB
        END
      )
      ORDER BY ctx.ordinality    -- preserva ordem original dos contextos
    ) AS new_contexts
  FROM public.questionnaire_results qr
  -- Expande o array de contextos, mantendo posição para reordenar depois
  CROSS JOIN LATERAL
    jsonb_array_elements(qr.snapshot->'contexts')
    WITH ORDINALITY AS ctx(value, ordinality)
  -- Conta respostas reais para cada contexto parental
  CROSS JOIN LATERAL (
    SELECT COUNT(*) AS answer_count
    FROM public.questionnaire_answers qa
    WHERE qa.response_id          = qr.response_id
      AND qa.response_context_id  = (ctx.value->>'id')::UUID
      AND qa.answer_value         IS NOT NULL
  ) cnt
  WHERE qr.snapshot->>'category_code' = 'PARENTAL_CONTEXTS'
    AND (qr.snapshot->>'answer_count')::INT = 0
  GROUP BY qr.id
)
UPDATE public.questionnaire_results qr
SET snapshot = jsonb_set(
  jsonb_set(
    qr.snapshot,
    '{answer_count}',
    to_jsonb(fc.total_answered)
  ),
  '{contexts}',
  fc.new_contexts
)
FROM fixed_contexts fc
WHERE qr.id = fc.result_id;

-- ── Verificação pós-backfill ──────────────────────────────────────────────────

DO $$
DECLARE
  remaining INT;
  fixed     INT;
BEGIN
  SELECT COUNT(*) INTO remaining
  FROM public.questionnaire_results
  WHERE snapshot->>'category_code' = 'PARENTAL_CONTEXTS'
    AND (snapshot->>'answer_count')::INT = 0;

  IF remaining = 0 THEN
    RAISE NOTICE 'Backfill concluído com sucesso. Nenhum registro corrompido restante.';
  ELSE
    RAISE WARNING
      '% registros ainda com answer_count = 0 após backfill — verifique manualmente.',
      remaining;
  END IF;
END;
$$;

COMMIT;
