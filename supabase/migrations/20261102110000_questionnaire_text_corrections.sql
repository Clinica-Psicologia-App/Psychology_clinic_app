-- =============================================================================
-- Correções de português e padronização do ponto final (YAMI e Estilos de
-- Apego). Lista aprovada em docs/qa/correcoes-portugues-instrumentos.md.
--
-- Só altera questions.text; as respostas ligam por question_id e não mudam.
-- O gênero ("(a)" x masculino) NÃO é alterado: aguarda decisão das clientes.
-- =============================================================================

BEGIN;

-- ── YAMI: pedidas pelas clientes ─────────────────────────────────────────────
UPDATE public.questions SET text = 'Sou muito possessivo(a) ou ligado(a) às pessoas que me valorizam'
WHERE code = 'YAMI_PM2_141';
UPDATE public.questions SET text = 'Se eu não consigo atingir um objetivo, fico facilmente frustrado(a) e desisto'
WHERE code = 'YAMI_PM2_151';
UPDATE public.questions SET text = 'Depois que comecei a ficar com raiva, muitas vezes não me controlo e perco a cabeça'
WHERE code = 'YAMI_PM2_152';

-- ── YAMI: encontrada na varredura (parêntese sem fechar) ─────────────────────
UPDATE public.questions SET text = text || ')'
WHERE code = 'YAMI_PM2_132'
  AND length(text) - length(replace(text, '(', '')) > length(text) - length(replace(text, ')', ''));

-- ── Apego: pedidas pelas clientes ────────────────────────────────────────────
UPDATE public.questions SET text = replace(text, 'Sinto-me a vontade', 'Sinto-me à vontade')
WHERE code IN ('ATT_008', 'ATT_022');
UPDATE public.questions SET text = replace(text, 'me sinto a vontade', 'me sinto à vontade')
WHERE code = 'ATT_031';
UPDATE public.questions SET text = replace(text, 'eu ficare imagoado a principio', 'eu ficarei magoado a princípio')
WHERE code = 'ATT_039';

-- ── Apego: encontradas na varredura ──────────────────────────────────────────
UPDATE public.questions SET text = replace(text, 'estados de animo', 'estados de ânimo') WHERE code = 'ATT_019';
UPDATE public.questions SET text = replace(text, 'sexo intimo', 'sexo íntimo') WHERE code = 'ATT_021';
UPDATE public.questions SET text = replace(text, 'mais intimo', 'mais íntimo') WHERE code = 'ATT_027';
UPDATE public.questions SET text = replace(text, 'distancia', 'distância') WHERE code = 'ATT_037';
UPDATE public.questions SET text = replace(text, 'olhando com atenção outras pessoas', 'olhando com atenção para outras pessoas')
WHERE code IN ('ATT_034', 'ATT_042');
UPDATE public.questions SET text = replace(replace(text, 'esta olhando', 'está olhando'), 'pessoas fico aliviado –significa', 'pessoas, fico aliviado – significa')
WHERE code = 'ATT_042';

-- ── Ponto final em todas as afirmações (as que já terminam em . ? ! ficam) ───
UPDATE public.questions SET text = rtrim(text) || '.'
WHERE (code LIKE 'YAMI\_PM2\_1%' ESCAPE '\' OR code LIKE 'YAMI\_PM2\_0%' ESCAPE '\' OR code LIKE 'ATT\_%' ESCAPE '\')
  AND code NOT LIKE '%MODE%'
  AND rtrim(text) !~ '[.?!]$';

COMMIT;
