-- Adiciona categoria âncora para YSQ_FOUNDATION_V1.
--
-- O finish-questionnaire itera sobre question_categories para criar linhas em
-- questionnaire_results. Sem ao menos uma categoria, nenhum resultado é
-- gravado e hasResults fica falso, invisibilizando o YSQ no mapa mental e no
-- perfil esquemático consolidado.
--
-- Uma única categoria "YSQ_GERAL" serve de âncora; o scoring engine já
-- computa os 18 esquemas individualmente via question_scoring_rules e os
-- embute no campo JSONB snapshot da linha de resultado.

INSERT INTO question_categories (questionnaire_id, code, name)
SELECT
  q.id,
  'YSQ_GERAL',
  'YSQ — Pontuação Geral'
FROM questionnaires q
WHERE q.code = 'YSQ_FOUNDATION_V1'
ON CONFLICT DO NOTHING;
