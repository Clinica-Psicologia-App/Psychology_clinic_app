-- =============================================================================
-- Padroniza o gênero das afirmações no formato "palavra(a)", decisão das
-- clientes (YAMI já usa; o Apego estava só no masculino). Só toca palavras que
-- se referem a quem responde; "parceiro" e "ex" (a outra pessoa) ficam como estão.
-- Roda depois de 20261102110000_questionnaire_text_corrections.sql.
-- =============================================================================

BEGIN;

UPDATE public.questions SET text = regexp_replace(text, '\m(afetuoso|envolvido|ansioso|satisfeito|bravo|aborrecido|nervoso|preocupado|chato|interessado|deprimido|aliviado|magoado|incompleto)\M(?!\(a\))', '\1(a)', 'g')
WHERE code IN ('ATT_002','ATT_005','ATT_012','ATT_018','ATT_024','ATT_028','ATT_029','ATT_033','ATT_034','ATT_036','ATT_037','ATT_039','ATT_042');

UPDATE public.questions SET text = replace(text, 'solitário', 'solitário(a)')
WHERE code = 'YAMI_PM2_026' AND text NOT LIKE '%solitário(a)%';

COMMIT;
