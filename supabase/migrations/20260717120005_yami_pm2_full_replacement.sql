-- =============================================================================
-- Migration: substitui YAMI v1 (124 itens, 15 modos) pelo YAMI-PM2
--            (186 itens, 10 modos), fiel à planilha clínica do cliente.
--
-- Passos:
-- 1. Desativa schemas (modos) que não existem no YAMI-PM2
-- 2. Atualiza / cria schemas para os 10 modos do YAMI-PM2
-- 3. Desativa as 124 perguntas da versão anterior
-- 4. Insere 186 novas perguntas
-- 5. Cria question_scoring_rules ligando cada pergunta ao seu modo
-- 6. Recria severity_ranges para os 10 modos
-- =============================================================================

BEGIN;

-- ── 0. Atualiza instruções da versão ─────────────────────────────────────────
UPDATE public.questionnaire_versions
SET instructions = 'INSTRUÇÕES: Abaixo estão listadas frases que as pessoas podem usar para se descrever. Para cada item, por favor, classifique com que frequência você acreditou ou sentiu cada uma das frases durante o último mês, usando a escala de 6 pontos abaixo.'
WHERE id = '88888888-8888-8888-8888-888888888801';

-- ── 1. Desativa modos não presentes no YAMI-PM2 ─────────────────────────────
UPDATE public.schemas SET is_active = false
WHERE id IN ('88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888724');

-- ── 2. Atualiza / cria os 10 modos do YAMI-PM2 ─────────────────────────────
INSERT INTO public.schemas (id, domain_id, clinic_id, code, name, description, sort_order, is_active)
VALUES
  ('88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_01', 'Protetor Desligado', 'Modo esquemático: Protetor Desligado.', 0, true),
  ('88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_02', 'Criança Vulnerável', 'Modo esquemático: Criança Vulnerável.', 1, true),
  ('88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_03', 'Pai Punitivo', 'Modo esquemático: Pai Punitivo.', 2, true),
  ('88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_04', 'Criança Zangada', 'Modo esquemático: Criança Zangada.', 3, true),
  ('88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_05', 'Adulto Feliz', 'Modo esquemático: Adulto Feliz.', 4, true),
  ('88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_06', 'Vencido Submisso', 'Modo esquemático: Vencido Submisso.', 5, true),
  ('c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_07', 'Hipercompensador', 'Modo esquemático: Hipercompensador.', 6, true),
  ('88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_08', 'Criança Impulsiva', 'Modo esquemático: Criança Impulsiva.', 7, true),
  ('c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_09', 'Supercontrolador', 'Modo esquemático: Supercontrolador.', 8, true),
  ('88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_PM2_MODE_10', 'Criança Satisfeita', 'Modo esquemático: Criança Satisfeita.', 9, true)
ON CONFLICT (id) DO UPDATE SET
  domain_id  = EXCLUDED.domain_id,
  code       = EXCLUDED.code,
  name       = EXCLUDED.name,
  description= EXCLUDED.description,
  sort_order = EXCLUDED.sort_order,
  is_active  = EXCLUDED.is_active;

-- ── 3. Desativa as perguntas da versão anterior ─────────────────────────────
UPDATE public.questions SET is_active = false
WHERE questionnaire_id = '88888888-8888-8888-8888-888888888301';

-- ── 4. Insere 186 novas perguntas (YAMI-PM2) ──────────────────────────────
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860001', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_001', 'Eu me sinto entediado(a)', 0, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860002', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_002', 'Eu me sinto vazio(a)', 1, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860003', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_003', 'Eu me sinto anestesiado(a)', 2, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860004', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_004', 'Eu me sinto desinteressado(a)', 3, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860005', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_005', 'Eu me sinto insosso(a)', 4, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860006', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_006', 'Eu me sinto "no ar"', 5, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860007', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_007', 'Não ligo para nada; nada importa para mim', 6, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860008', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_008', 'Eu me sinto indiferente', 7, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860009', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_009', 'Não sinto nada', 8, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886000a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_010', 'Eu me sinto fora de mim mesmo(a) ou arrancado(a) de mim mesmo(a)', 9, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886000b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_011', 'Não me sinto conectado(a) a outras pessoas', 10, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886000c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_012', 'Não quero me envolver com pessoas', 11, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886000d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_013', 'Eu me sinto distante das pessoas', 12, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886000e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_014', 'Eu me sinto frio(a) em relação às outras pessoas', 13, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886000f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_015', 'Quero ficar sozinho(a)', 14, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860010', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_016', 'É melhor não me aproximar ou me sentir apegado(a) a outras pessoas', 15, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860011', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_017', 'Não sei o que eu quero ou preciso', 16, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860012', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_018', 'Não quero sentir nada', 17, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860013', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_019', 'Se eu me permitir sentir minhas emoções, posso perder o controle', 18, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860014', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_020', 'É melhor não expressar minhas necessidades, sentimentos ou opiniões para os outros', 19, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860015', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_021', 'Tenho impulsos de me ferir (por ex., me cortar) assim não vou sentir emoções perturbadoras', 20, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860016', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_022', 'Estou com vontade de usar drogas ou álcool para anestesiar meus sentimentos', 21, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860017', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_023', 'Queria fazer alguma coisa excitante ou relaxante para evitar meus sentimentos (por ex., trabalhar, jogar, comer, fazer compras, atividades sexuais, assistir televisão)', 22, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860018', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_024', 'Não quero pensar em meus sentimentos porque eles me aborrecem', 23, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860019', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_025', 'Quero me distrair dos pensamentos e sentimentos perturbadores', 24, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886001a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_026', 'Eu me sinto solitário', 25, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886001b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_027', 'Sinto que ninguém me ama', 26, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886001c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_028', 'Sinto que não sou digno(a) de ser amado', 27, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886001d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_029', 'Eu me sinto fundamentalmente inadequado(a), inútil ou cheio(a) de defeitos', 28, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886001e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_030', 'Eu me sinto fraco(a) e desamparado(a)', 29, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886001f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_031', 'Eu me sinto triste', 30, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860020', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_032', 'Eu me sinto perdido(a)', 31, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860021', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_033', 'Eu me sinto carente', 32, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860022', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_034', 'Eu me sinto desesperado(a)', 33, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860023', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_035', 'Eu me sinto deixado(a) de fora ou excluído(a)', 34, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860024', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_036', 'Eu me sinto sem esperança', 35, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860025', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_037', 'Eu me sinto amedrontado(a), assustado(a) ou ansioso(a)', 36, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860026', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_038', 'Fico preocupado(a) que as pessoas me abandonem ou morram', 37, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860027', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_039', 'Fico preocupado(a) que as pessoas me magoem, abusem de mim ou me castiguem', 38, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860028', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_040', 'Tenho medo das pessoas', 39, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860029', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_041', 'Queria ter alguém para me abraçar ou estar perto de mim', 40, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886002a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_042', 'Queria ter alguém com quem me sentisse conectado(a)', 41, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886002b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_043', 'Não tem ninguém que realmente me escute ou me entenda', 42, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886002c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_044', 'Fico preocupado(a) que alguma coisa ruim me aconteça', 43, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886002d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_045', 'Fico preocupado(a) que outras pessoas riam de mim ou me humilhem', 44, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886002e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_046', 'Preciso que outras pessoas restaurem minha confiança muitas vezes', 45, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886002f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_047', 'Queria ter alguém que me sustentasse ou me protegesse', 46, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860030', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_048', 'Eu me sinto envergonhado(a)', 47, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860031', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_049', 'Estou com raiva de mim mesmo(a)', 48, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860032', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_050', 'Sou uma pessoa ruim', 49, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860033', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_051', 'Não consigo me perdoar', 50, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860034', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_052', 'Estou com raiva de mim mesmo(a) por ser fraco(a)', 51, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860035', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_053', 'Tenho um impulso de me castigar me ferindo (por ex., me cortando)', 52, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860036', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_054', 'Eu mereço ser castigado(a)', 53, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860037', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_055', 'Estou com vontade de castigar alguém por ter feito algo errado', 54, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860038', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_056', 'Estou com raiva de mim mesmo(a) por me sentir carente', 55, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860039', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_057', 'Nego qualquer prazer a mim mesmo(a), pois não mereço sentir prazer', 56, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886003a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_058', 'Serei mau se expressar minhas necessidades, sentimentos ou opiniões para outras pessoas', 57, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886003b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_059', 'Serei mau se ficar bravo(a) com outras pessoas', 58, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886003c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_060', 'É minha culpa quando algo de ruim acontece', 59, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886003d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_061', 'Minhas necessidades ou sentimentos são errados', 60, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886003e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_062', 'Não mereço solidariedade quando algo de ruim acontece comigo', 61, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886003f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_063', 'Eu me sinto culpado(a)', 62, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860040', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_064', 'Eu me odeio ou me desprezo', 63, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860041', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_065', 'Não me permito fazer coisas prazerosas que outras pessoas fazem, pois sou mau', 64, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860042', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_066', 'Sou egoísta', 65, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860043', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_067', 'Sou preguiçoso(a)', 66, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860044', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_068', 'Sou burro(a)', 67, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860045', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_069', 'Estou pensando nos erros que cometi e estou com raiva de mim mesmo(a)', 68, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860046', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_070', 'Existem pessoas que me magoaram, mas não consigo "perdoar e esquecer"', 69, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860047', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_071', 'Não importa porque cometi um erro; quando faço algo errado, tenho que pagar o preço', 70, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860048', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_072', 'Fico aborrecido(a) quando acho que alguém "livrou a cara" muito facilmente', 71, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860049', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_073', 'Fico com raiva quando as pessoas ficam procurando desculpas ou culpam outras pessoas por seus problemas', 72, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886004a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_074', 'Estou furioso com alguém', 73, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886004b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_075', 'Estou com raiva de alguém por me deixar sozinho(a) ou me abandonar', 74, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886004c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_076', 'Estou com vontade de bater em alguém ou feri-la pelo que fez comigo', 75, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886004d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_077', 'Estou com raiva por alguém não estar me dando o amor, atenção e carinho que preciso', 76, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886004e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_078', 'Tenho muita raiva dentro de mim que tenho que liberar', 77, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886004f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_079', 'Fui traído(a) ou tratado(a) de maneira injusta', 78, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860050', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_080', 'Fico com raiva quando alguém diz como devo me sentir ou me comportar', 79, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860051', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_081', 'Estou com raiva porque as pessoas estão tentando tirar minha liberdade ou independência', 80, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860052', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_082', 'Eu me sinto frustrado(a) por outras pessoas', 81, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860053', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_083', 'Estou com vontade de repreender pessoas por causa do jeito que me trataram', 82, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860054', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_084', 'Minha raiva parece fora de controle', 83, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860055', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_085', 'Sinto impulsos violentos contra outras pessoas que me magoaram', 84, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860056', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_086', 'Consigo expressar meus sentimentos espontaneamente quando isso é apropriado', 85, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860057', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_087', 'Eu me permito sentir o prazer da vida e das coisas boas para mim mesmo(a)', 86, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860058', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_088', 'Eu mereço coisas boas tanto quanto as outras pessoas', 87, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860059', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_089', 'Eu aceito minhas próprias limitações e as limitações de outras pessoas sem sentir raiva ou ficar frustrado(a)', 88, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886005a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_090', 'Eu consigo resolver problemas de maneira racional sem deixar que minhas emoções me dominem', 89, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886005b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_091', 'Tenho bom controle das minhas emoções, inclusive da raiva', 90, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886005c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_092', 'Eu enfrento meus problemas ao invés de evitá-los', 91, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886005d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_093', 'Eu consigo pedir a outras pessoas para satisfazer minhas necessidades', 92, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886005e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_094', 'Tenho o direito de expressar minhas opiniões', 93, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886005f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_095', 'Sou capaz de cuidar de mim mesmo(a)', 94, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860060', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_096', 'Eu consigo discutir meus sentimentos com outras pessoas', 95, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860061', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_097', 'Eu aceito ajuda quando não consigo resolver um problema', 96, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860062', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_098', 'Tenho relacionamentos saudáveis com amigos e outras pessoas que conheço', 97, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860063', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_099', 'Faço as coisas que gosto de fazer, e não apenas as coisas que tenho que fazer', 98, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860064', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_100', 'Quando há problemas, tento muito resolvê-los', 99, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860065', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_101', 'Sei quando expressar ou não minhas emoções', 100, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860066', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_102', 'Eu reivindico o que preciso sem "passar dos limites"', 101, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860067', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_103', 'Na maior parte do tempo, gosto de mim e me aceito como sou', 102, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860068', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_104', 'Tenho uma boa noção de quem eu sou e do que preciso para me sentir feliz', 103, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860069', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_105', 'Eu consigo me defender quando me sinto criticado(a) injustamente ou quando abusam ou se aproveitam de mim', 104, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886006a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_106', 'Eu me certifico de que tanto as minhas necessidades quanto as necessidades das outras pessoas sejam levadas em conta quando tomo alguma decisão', 105, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886006b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_107', 'Tenho um bom equilíbrio entre cuidar das outras pessoas e ter minhas próprias necessidades satisfeitas', 106, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886006c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_108', 'Quando cometo erros, consigo me perdoar', 107, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886006d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_109', 'Não sinto uma necessidade forte de impressionar outras pessoas ou me esforçar para outras pessoas gostarem de mim', 108, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886006e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_110', 'Eu me sinto confortável expressando minhas emoções (por ex., chorar, sentir raiva, alegria) na medida em que é adequado para a situação', 109, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886006f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_111', 'Gosto de fazer as coisas bem, mas não exijo tanto de mim que não consiga relaxar ou me divertir', 110, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860070', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_112', 'Quando necessário, conduzo tarefas chatas e rotineiras a fim de realizar coisas que valorizo', 111, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860071', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_113', 'Eu deixo outras pessoas fazerem do jeito delas ao invés de expressar minhas próprias necessidades', 112, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860072', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_114', 'Nos relacionamentos, deixo a outra pessoa ter o controle', 113, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860073', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_115', 'Eu tento muito agradar as outras pessoas para evitar conflitos, confronto ou rejeição', 114, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860074', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_116', 'Eu dou mais aos outros do que recebo em troca', 115, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860075', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_117', 'Eu ajo de modo passivo, mesmo quando não gosto das coisas como elas são', 116, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860076', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_118', 'Eu fico tempo demais em situações que não são saudáveis para mim ou nas quais minhas necessidades não estão sendo satisfeitas', 117, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860077', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_119', 'Eu mudo dependendo das pessoas com quem estou, assim elas vão gostar de mim ou me aprovar', 118, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860078', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_120', 'Eu procuro outras pessoas para me ajudarem, pois não confio em meu próprio julgamento ou decisão', 119, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860079', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_121', 'Permito que outras pessoas me critiquem ou me coloquem para baixo', 120, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886007a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_122', 'Permaneço em relacionamento com pessoas que são instáveis ou que não assumem compromisso comigo', 121, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886007b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_123', 'Acho difícil sair de relacionamentos nos quais estou sofrendo abuso ou sendo maltratado(a)', 122, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886007c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_124', 'Em muitos dos meus relacionamentos importantes, não tenho muito amor, atenção, apoio ou empatia.', 123, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886007d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_125', 'Faço muitas coisas com desleixo ou sem entusiasmo porque espero que elas deem errado ou que ficarei decepcionado(a)', 124, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886007e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_126', 'Estou tão ocupado(a) fazendo coisas para outras pessoas que não tenho muito tempo para mim mesmo(a)', 125, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886007f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_127', 'Deixo outras pessoas cuidarem de mim porque não me sinto capaz de enfrentar bem sozinho(a)', 126, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860080', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_128', 'Desconto minhas frustrações nas pessoas que estão ao meu redor', 127, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860081', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_129', 'Tenho a tendência de culpar os outros quando as coisas dão errado', 128, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860082', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_130', 'Eu me esforço para que as outras pessoas me admirem por minhas realizações e conquistas', 129, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860083', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_131', 'Eu compro coisas para que os outros vejam que sou bem sucedido(a) (por ex., carros caros, roupas de marca, uma bela casa)', 130, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860084', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_132', 'É importante para mim ser o "número 1" (por ex., o(a) mais popular, o(a) mais bem sucedido(a), o(a) mais rico(a), o(a) mais poderoso(a)', 131, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860085', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_133', 'Eu faço coisas para ser o centro das atenções', 132, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860086', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_134', 'Eu tendo mais do que a maioria das outras pessoas ter ordem em minha vida (por ex., organização, estrutura, planejamento, rotina)', 133, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860087', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_135', 'Sou bastante controlador(a) em relação às pessoas ao meu redor', 134, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860088', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_136', 'Eu não me deixo ser dependente de ninguém', 135, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860089', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_137', 'Eu normalmente coloco minhas próprias necessidades antes dos outros', 136, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886008a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_138', 'Sou exigente com outras pessoas', 137, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886008b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_139', 'Sou "rebelde" de muitas maneiras e vou contra a autoridade estabelecida', 138, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886008c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_140', 'Sinto que não deveria seguir as mesmas regras que as outras pessoas', 139, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886008d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_141', 'Sou muito possessivo(a) ou ligado(a)  às pessoas que valorize', 140, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886008e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_142', 'Eu manipulo para atingir meus objetivos', 141, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886008f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_143', 'Procuro maneiras de ser mais esperto(a) que as pessoas para que elas não se aproveitem de mim ou me enganem', 142, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860090', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_144', 'Faço o que quero, independentemente das necessidades ou sentimentos das outras pessoas', 143, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860091', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_145', 'Critico bastante as outras pessoas', 144, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860092', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_146', 'Fico irritado(a) quando as pessoas não fazem o que peço para elas fazerem', 145, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860093', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_147', 'Eu me sinto especial - melhor do eu a maioria das outras pessoas', 146, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860094', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_148', 'Eu afasto as pessoas se elas tentam se aproximar demais de mim ou se intrometer em minha vida', 147, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860095', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_149', 'Eu não me forço a concluir tarefas chatas e rotineiras', 148, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860096', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_150', 'Eu ajo impulsivamente ou expresso emoções que criam problemas para mim ou magoam outras pessoas', 149, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860097', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_151', 'Se não consigo atingir um objetivo, fio facilmente frustrado(a) e desisto', 150, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860098', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_152', 'depois que comecei a ficar com raiva, muitas vezes não me controlo e perco a cabeça', 151, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888860099', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_153', 'Eu faço repetidamente coisas que são prazerosas, mesmo quando sei que não me fazem bem (por ex., beber, fumar, usar drogas, comer demais, sexo, jogar)', 152, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886009a', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_154', 'Eu fico facilmente entediado(a) e perco interesse nas coisas', 153, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886009b', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_155', 'Para mim, é difícil conseguir me controlar', 154, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886009c', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_156', 'Eu digo o que sinto ou faço coisas impulsivamente sem pensar nas consequências', 155, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886009d', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_157', 'Eu quebro as regras e acabo me arrependendo', 156, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886009e', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_158', 'Eu entro em encrencas mais do que outras pessoas', 157, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888886009f', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_159', 'Eu me forço a ser mais responsável do que a maioria das outras pessoas', 158, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a0', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_160', 'Não estou me permitindo relaxar ou me divertir até que termine de fazer tudo o que tenho que fazer', 159, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a1', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_161', 'Estou tentando dar o melhor de mim em tudo que experimento', 160, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a2', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_162', 'Estou tentando não cometer erros, senão vou me decepcionar comigo mesmo(a)', 161, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a3', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_163', 'Estou sacrificando prazer, saúde ou felicidade para satisfazer meus próprios padrões', 162, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a4', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_164', 'Meus relacionamentos estão sofrendo porque estou me pressionando muito', 163, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a5', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_165', 'Estou em constante pressão para conquistar e ter as coisas feitas', 164, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a6', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_166', 'Sou duro(a) comigo mesmo(a)', 165, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a7', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_167', 'Sei que existe um jeito "certo" e um jeito "errado" de fazer as coisas; estou tentando muito fazer as coisas do jeito certo ou então vou começar a me criticar', 166, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a8', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_168', 'Tenho um rígido código de ética e moral que estou dando duro para seguir', 167, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600a9', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_169', 'Minha vida neste momento se resume a fazer as coisas acontecerem e fazê-las do jeito "certo"', 168, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600aa', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_170', 'Eu me sinto levado(a) a realizar coisas', 169, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600ab', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_171', 'Eu me sinto amado(a) e aceito(a)', 170, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600ac', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_172', 'Eu me sinto satisfeito(a) e em paz', 171, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600ad', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_173', 'Eu me sinto conectado(a) a outras pessoas', 172, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600ae', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_174', 'Sinto que sou ouvido(a), compreendido(a) e validado(a)', 173, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600af', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_175', 'Eu me sinto espontâneo(a) e divertido(a)', 174, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b0', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_176', 'Eu me sinto otimista', 175, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b1', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_177', 'Sinto que sou basicamente uma boa pessoa', 176, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b2', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_178', 'Sinto que normalmente tenho sucesso naquilo que tento alcançar', 177, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b3', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_179', 'Tenho uma boa noção de quem eu sou, do que preciso e do que sinto', 178, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b4', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_180', 'Sinto que tenho bastante estabilidade e segurança em minha vida', 179, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b5', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_181', 'Sinto que me encaixo com outras pessoas', 180, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b6', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_182', 'Eu me sinto confiante de que consigo ter a maioria das minhas necessidades importantes satisfeitas', 181, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b7', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_183', 'Eu me sinto seguro(a)', 182, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b8', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_184', 'Sinto que normalmente tenho atenção suficiente das outras pessoas', 183, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600b9', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_185', 'Confio na maioria das outras pessoas', 184, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;
INSERT INTO public.questions (id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-8888888600ba', '88888888-8888-8888-8888-888888888301', '88888888-8888-8888-8888-888888888801', 'YAMI_PM2_186', 'Sinto que consigo tomar boas decisões e exercitar bom discernimento', 185, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  code        = EXCLUDED.code,
  text        = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  is_active   = EXCLUDED.is_active;

-- ── 5. Remove regras antigas e insere as novas ─────────────────────────────
DELETE FROM public.question_scoring_rules
WHERE questionnaire_version_id = '88888888-8888-8888-8888-888888888801';

INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870001', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860001', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870002', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860002', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870003', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860003', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870004', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860004', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 3, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870005', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860005', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 4, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870006', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860006', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 5, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870007', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860007', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 6, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870008', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860008', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 7, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870009', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860009', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 8, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887000a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886000a', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 9, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887000b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886000b', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 10, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887000c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886000c', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 11, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887000d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886000d', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 12, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887000e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886000e', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 13, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887000f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886000f', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 14, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870010', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860010', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 15, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870011', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860011', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 16, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870012', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860012', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 17, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870013', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860013', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 18, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870014', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860014', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 19, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870015', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860015', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 20, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870016', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860016', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 21, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870017', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860017', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 22, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870018', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860018', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 23, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870019', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860019', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 24, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887001a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886001a', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 25, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887001b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886001b', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 26, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887001c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886001c', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 27, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887001d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886001d', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 28, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887001e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886001e', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 29, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887001f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886001f', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 30, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870020', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860020', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 31, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870021', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860021', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 32, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870022', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860022', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 33, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870023', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860023', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 34, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870024', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860024', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 35, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870025', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860025', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 36, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870026', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860026', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 37, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870027', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860027', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 38, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870028', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860028', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 39, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870029', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860029', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 40, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887002a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886002a', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 41, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887002b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886002b', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 42, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887002c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886002c', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 43, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887002d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886002d', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 44, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887002e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886002e', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 45, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887002f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886002f', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 46, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870030', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860030', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 47, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870031', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860031', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 48, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870032', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860032', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 49, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870033', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860033', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 50, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870034', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860034', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 51, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870035', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860035', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 52, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870036', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860036', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 53, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870037', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860037', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 54, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870038', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860038', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 55, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870039', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860039', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 56, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887003a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886003a', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 57, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887003b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886003b', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 58, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887003c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886003c', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 59, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887003d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886003d', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 60, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887003e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886003e', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 61, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887003f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886003f', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 62, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870040', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860040', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 63, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870041', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860041', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 64, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870042', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860042', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 65, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870043', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860043', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 66, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870044', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860044', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 67, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870045', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860045', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 68, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870046', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860046', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 69, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870047', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860047', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 70, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870048', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860048', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 71, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870049', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860049', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 72, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887004a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886004a', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 73, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887004b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886004b', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 74, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887004c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886004c', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 75, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887004d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886004d', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 76, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887004e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886004e', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 77, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887004f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886004f', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 78, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870050', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860050', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 79, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870051', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860051', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 80, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870052', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860052', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 81, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870053', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860053', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 82, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870054', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860054', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 83, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870055', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860055', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 84, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870056', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860056', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 85, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870057', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860057', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 86, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870058', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860058', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 87, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870059', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860059', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 88, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887005a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886005a', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 89, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887005b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886005b', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 90, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887005c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886005c', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 91, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887005d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886005d', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 92, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887005e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886005e', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 93, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887005f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886005f', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 94, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870060', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860060', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 95, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870061', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860061', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 96, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870062', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860062', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 97, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870063', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860063', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 98, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870064', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860064', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 99, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870065', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860065', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 100, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870066', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860066', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 101, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870067', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860067', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 102, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870068', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860068', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 103, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870069', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860069', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 104, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887006a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886006a', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 105, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887006b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886006b', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 106, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887006c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886006c', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 107, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887006d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886006d', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 108, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887006e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886006e', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 109, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887006f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886006f', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 110, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870070', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860070', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 111, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870071', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860071', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 112, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870072', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860072', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 113, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870073', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860073', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 114, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870074', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860074', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 115, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870075', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860075', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 116, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870076', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860076', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 117, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870077', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860077', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 118, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870078', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860078', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 119, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870079', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860079', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 120, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887007a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886007a', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 121, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887007b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886007b', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 122, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887007c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886007c', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 123, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887007d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886007d', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 124, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887007e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886007e', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 125, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887007f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886007f', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 126, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870080', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860080', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 127, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870081', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860081', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 128, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870082', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860082', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 129, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870083', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860083', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 130, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870084', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860084', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 131, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870085', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860085', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 132, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870086', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860086', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 133, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870087', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860087', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 134, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870088', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860088', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 135, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870089', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860089', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 136, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887008a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886008a', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 137, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887008b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886008b', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 138, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887008c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886008c', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 139, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887008d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886008d', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 140, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887008e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886008e', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 141, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887008f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886008f', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 142, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870090', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860090', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 143, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870091', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860091', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 144, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870092', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860092', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 145, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870093', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860093', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 146, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870094', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860094', 'c3000001-0000-4000-a000-000000000001', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 147, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870095', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860095', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 148, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870096', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860096', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 149, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870097', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860097', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 150, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870098', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860098', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 151, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888870099', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888860099', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 152, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887009a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886009a', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 153, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887009b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886009b', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 154, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887009c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886009c', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 155, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887009d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886009d', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 156, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887009e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886009e', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 157, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888887009f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888886009f', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 158, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a0', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a0', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 159, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a1', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a1', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 160, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a2', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a2', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 161, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a3', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a3', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 162, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a4', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a4', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 163, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a5', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a5', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 164, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a6', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a6', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 165, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a7', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a7', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 166, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a8', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a8', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 167, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700a9', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600a9', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 168, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700aa', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600aa', 'c3000001-0000-4000-a000-000000000002', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 169, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700ab', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600ab', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 170, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700ac', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600ac', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 171, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700ad', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600ad', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 172, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700ae', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600ae', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 173, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700af', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600af', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 174, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b0', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b0', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 175, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b1', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b1', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 176, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b2', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b2', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 177, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b3', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b3', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 178, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b4', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b4', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 179, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b5', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b5', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 180, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b6', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b6', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 181, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b7', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b7', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 182, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b8', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b8', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 183, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700b9', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600b9', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 184, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-8888888700ba', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-8888888600ba', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1.0, false, 1, 6, 185, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO UPDATE SET
  schema_id  = EXCLUDED.schema_id,
  domain_id  = EXCLUDED.domain_id,
  sort_order = EXCLUDED.sort_order;

-- ── 6. Recria severity_ranges para os 10 modos ─────────────────────────────
DELETE FROM public.severity_ranges
WHERE questionnaire_version_id = '88888888-8888-8888-8888-888888888801';

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000001', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888723', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000002', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888723', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000003', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888723', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000004', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888713', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000005', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888713', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000006', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888713', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000007', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888712', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000008', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888712', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000009', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888712', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400000a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888722', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400000b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888722', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400000c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888722', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400000d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888721', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400000e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888721', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400000f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888721', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000010', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888715', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000011', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888715', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000012', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888715', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000013', '88888888-8888-8888-8888-888888888801', 'c3000001-0000-4000-a000-000000000001', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000014', '88888888-8888-8888-8888-888888888801', 'c3000001-0000-4000-a000-000000000001', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000015', '88888888-8888-8888-8888-888888888801', 'c3000001-0000-4000-a000-000000000001', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000016', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888717', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000017', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888717', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000018', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888717', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c4000019', '88888888-8888-8888-8888-888888888801', 'c3000001-0000-4000-a000-000000000002', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400001a', '88888888-8888-8888-8888-888888888801', 'c3000001-0000-4000-a000-000000000002', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400001b', '88888888-8888-8888-8888-888888888801', 'c3000001-0000-4000-a000-000000000002', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400001c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888711', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400001d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888711', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('00000000-0000-0000-0000-0000c400001e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888711', NULL, 'Ativado', 4.0, 6.0, 'severity_high', 2, '{"source": "YAMI-PM2"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

COMMIT;