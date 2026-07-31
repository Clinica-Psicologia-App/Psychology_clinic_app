-- =============================================================================
-- Migration: garante que o YAMI-PM2 tenha uma categoria "TOTAL" e que todos os
--            186 itens ativos estejam ligados a ela.
--
-- Contexto: a função finish-questionnaire só persiste resultados iterando sobre
-- as question_categories do instrumento. O YAMI (clinical_status = 'approved')
-- nunca teve categoria criada — o trigger automático só atua em draft/validation
-- — então nenhum resultado era gravado. Sem esta categoria, a tela de resultados
-- não exibiria os 10 modos. A camada estruturada (schemas/severity_ranges) segue
-- sendo a fonte dos modos; a categoria TOTAL apenas garante que o snapshot seja
-- salvo.
-- =============================================================================

BEGIN;

-- 1. Cria a categoria TOTAL do YAMI (necessária para persistir o resultado)
INSERT INTO public.question_categories (questionnaire_id, code, name, description)
VALUES (
  '88888888-8888-8888-8888-888888888301',
  'TOTAL',
  'Resultado total',
  'Pontuação agregada de todas as perguntas do instrumento.'
)
ON CONFLICT (questionnaire_id, lower(code)) DO NOTHING;

-- 2. Liga os 186 itens ativos à categoria TOTAL (peso 1)
INSERT INTO public.question_category_items (question_id, category_id, weight)
SELECT qu.id, qc.id, 1
FROM public.questions qu
JOIN public.question_categories qc
  ON qc.questionnaire_id = qu.questionnaire_id AND lower(qc.code) = 'total'
WHERE qu.questionnaire_id = '88888888-8888-8888-8888-888888888301'
  AND qu.is_active = true
ON CONFLICT (question_id, category_id) DO NOTHING;

COMMIT;
