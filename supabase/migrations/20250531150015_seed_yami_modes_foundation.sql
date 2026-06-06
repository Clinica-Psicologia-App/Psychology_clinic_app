-- =============================================================================
-- Migration 015: YAMI — Modos Esquemáticos (ProjetoApp_questionários.xlsx)
-- Aba: YAMI-Modos Esquemáticos (2). Não altera MVP_DEMO, YSQ, seed DEMO.
-- Modos → schemas sob YAMI_DOMAIN_SCHEMA_MODES. Ver docs/scoring-engine/yami-import-report.md
-- =============================================================================

-- Migration 015: YAMI — Modos Esquemáticos
BEGIN;

INSERT INTO public.questionnaires (id, code, name, description, is_active)
VALUES ('88888888-8888-8888-8888-888888888301', 'YAMI_MODES_FOUNDATION_V1', 'YAMI — Modos Esquemáticos Foundation v1',
  '124 itens — aba YAMI-Modos Esquemáticos (SMI 1.1 na planilha). Escala 1–6.', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.schema_domains (id, clinic_id, code, name, description, sort_order, is_active)
VALUES ('88888888-8888-8888-8888-888888888601', NULL, 'YAMI_DOMAIN_SCHEMA_MODES', 'Modos esquemáticos (YAMI/SMI)',
  'Domínio único: modos mapeados em schemas (ver yami-import-report.md).', 0, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.schemas (id, domain_id, clinic_id, code, name, description, sort_order, is_active)
VALUES
  ('88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_01', 'Intimidação e Ataque', 'Modo importado YAMI.', 0, true),
  ('88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_02', 'Criança  Feliz', 'Modo importado YAMI.', 1, true),
  ('88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_03', 'Pais Punitivos', 'Modo importado YAMI.', 2, true),
  ('88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_04', 'Criança Vulnerável', 'Modo importado YAMI.', 3, true),
  ('88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_05', 'Pais Exigentes e Críticos', 'Modo importado YAMI.', 4, true),
  ('88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_06', 'Vencido Submisso', 'Modo importado YAMI.', 5, true),
  ('88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_07', 'Auto Engrandecedor', 'Modo importado YAMI.', 6, true),
  ('88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_08', 'Criança Impulsiva', 'Modo importado YAMI.', 7, true),
  ('88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_09', 'Criança Indisciplinada', 'Modo importado YAMI.', 8, true),
  ('88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_10', 'Criança Raivosa', 'Modo importado YAMI.', 9, true),
  ('88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_11', 'Criança Feliz', 'Modo importado YAMI.', 10, true),
  ('88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_12', 'Adulto Saudável', 'Modo importado YAMI.', 11, true),
  ('88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_13', 'Criança Zangada', 'Modo importado YAMI.', 12, true),
  ('88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_14', 'Protetor Desligado', 'Modo importado YAMI.', 13, true),
  ('88888888-8888-8888-8888-888888888724', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_15', 'Autoconfortador Desligado', 'Modo importado YAMI.', 14, true),
  ('88888888-8888-8888-8888-888888888725', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_16', 'Auto Confortador Desligado', 'Modo importado YAMI.', 15, true),
  ('88888888-8888-8888-8888-888888888726', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_17', 'Auto Confortador desligada', 'Modo importado YAMI.', 16, true),
  ('88888888-8888-8888-8888-888888888727', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_18', 'Ciança Vulnerável', 'Modo importado YAMI.', 17, true),
  ('88888888-8888-8888-8888-888888888728', '88888888-8888-8888-8888-888888888601', NULL, 'YAMI_MODE_19', 'Ciança Feliz', 'Modo importado YAMI.', 18, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850001', '88888888-8888-8888-8888-888888888301', 'YAMI_001', 'Eu exijo respeito ao não permitir que os outros me intimidem ou mandem em mim.', 0, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850002', '88888888-8888-8888-8888-888888888301', 'YAMI_002', 'Eu me sinto amado e aceito.', 1, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850003', '88888888-8888-8888-8888-888888888301', 'YAMI_003', 'Eu não me permito sentir prazer, pois não mereço.', 2, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850004', '88888888-8888-8888-8888-888888888301', 'YAMI_004', 'Eu me sinto fundamentalmente inadequado, falho ou defeituoso.', 3, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850005', '88888888-8888-8888-8888-888888888301', 'YAMI_005', 'Eu tenho impulsos de me punir, me machucando (p. ex., me cortando).', 4, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850006', '88888888-8888-8888-8888-888888888301', 'YAMI_006', 'Eu me sinto perdido.', 5, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850007', '88888888-8888-8888-8888-888888888301', 'YAMI_007', 'Eu sou duro comigo mesmo.', 6, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850008', '88888888-8888-8888-8888-888888888301', 'YAMI_008', 'Eu me esforço muito para agradar outras pessoas; assim, evito conflitos, confrontos ou rejeição.', 7, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850009', '88888888-8888-8888-8888-888888888301', 'YAMI_009', 'Eu não consigo me perdoar.', 8, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885000a', '88888888-8888-8888-8888-888888888301', 'YAMI_010', 'Eu faço coisas para que eu me torne o centro das atenções.', 9, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885000b', '88888888-8888-8888-8888-888888888301', 'YAMI_011', 'Eu fico irritado quando as pessoas não fazem o que eu peço.', 10, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885000c', '88888888-8888-8888-8888-888888888301', 'YAMI_012', 'Eu tenho dificuldade de controlar meus impulsos.', 11, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885000d', '88888888-8888-8888-8888-888888888301', 'YAMI_013', 'Se eu não consigo atingir um objetivo, me frustro facilmente e desisto.', 12, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885000e', '88888888-8888-8888-8888-888888888301', 'YAMI_014', 'Eu tenho acessos de raiva.', 13, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885000f', '88888888-8888-8888-8888-888888888301', 'YAMI_015', 'Eu ajo de forma impulsiva ou expresso emoções que magoam os outros ou me causam problemas.', 14, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850010', '88888888-8888-8888-8888-888888888301', 'YAMI_016', 'Quando algo ruim acontece, a culpa é minha.', 15, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850011', '88888888-8888-8888-8888-888888888301', 'YAMI_017', 'Eu me sinto contente e tranquilo.', 16, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850012', '88888888-8888-8888-8888-888888888301', 'YAMI_018', 'Eu mudo o meu jeito de ser dependendo de quem esteja comigo, assim essas pessoas gostarão de mim ou me aprovarão.', 17, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850013', '88888888-8888-8888-8888-888888888301', 'YAMI_019', 'Eu me sinto conectado às outras pessoas.', 18, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850014', '88888888-8888-8888-8888-888888888301', 'YAMI_020', 'Quando ocorrem problemas, me esforço bastante para resolvê-los eu mesmo.', 19, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850015', '88888888-8888-8888-8888-888888888301', 'YAMI_021', 'Eu não me disciplino para concluir tarefas chatas ou rotineiras.', 20, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850016', '88888888-8888-8888-8888-888888888301', 'YAMI_022', 'Se eu não brigar, as pessoas se aproveitarão de mim ou me ignorarão.', 21, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850017', '88888888-8888-8888-8888-888888888301', 'YAMI_023', 'Eu preciso cuidar das pessoas à minha volta.', 22, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850018', '88888888-8888-8888-8888-888888888301', 'YAMI_024', 'Se você permitir que as outras pessoas façam piadas ou mexam com você, você é um trouxa.', 23, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850019', '88888888-8888-8888-8888-888888888301', 'YAMI_025', 'Eu agrido as pessoas fisicamente quando estou com raiva delas.', 24, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885001a', '88888888-8888-8888-8888-888888888301', 'YAMI_026', 'Quando eu começo a ficar bravo, muitas vezes não consigo controlar a raiva e perco a cabeça.', 25, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885001b', '88888888-8888-8888-8888-888888888301', 'YAMI_027', 'Pra mim é importante ser o número 1 (p.ex. o mais popular, o mais rico, o mais poderoso, o mai bem-sucedido.', 26, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885001c', '88888888-8888-8888-8888-888888888301', 'YAMI_028', 'Eu me sinto indiferente em relação à maioria das coisas.', 27, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885001d', '88888888-8888-8888-8888-888888888301', 'YAMI_029', 'Eu consigo resolver problemas racionalmente, sem deixar que as minhas emoções tomem conta de mim.', 28, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885001e', '88888888-8888-8888-8888-888888888301', 'YAMI_030', 'É ridículo planejar como você lidará com as situações.', 29, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885001f', '88888888-8888-8888-8888-888888888301', 'YAMI_031', 'Eu não me contentarei em ficar em segundo lugar.', 30, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850020', '88888888-8888-8888-8888-888888888301', 'YAMI_032', 'Atacar é a melhor defesa.', 31, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850021', '88888888-8888-8888-8888-888888888301', 'YAMI_033', 'Eu me sinto frio e emocionalmente afastado das pessoas.', 32, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850022', '88888888-8888-8888-8888-888888888301', 'YAMI_034', 'Eu me sinto desconectado (sem contato comigo mesmo, minhas emoções e com as outras pessoas).', 33, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850023', '88888888-8888-8888-8888-888888888301', 'YAMI_035', 'Eu sigo as minhas emoções cegamente.', 34, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850024', '88888888-8888-8888-8888-888888888301', 'YAMI_036', 'Eu me sinto desesperado.', 35, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850025', '88888888-8888-8888-8888-888888888301', 'YAMI_037', 'Eu permito que outras pessoas me critiquem ou me coloquem para baixo.', 36, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850026', '88888888-8888-8888-8888-888888888301', 'YAMI_038', 'Nas relações, eu deixo a outra pessoa tomar as decisões.', 37, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850027', '88888888-8888-8888-8888-888888888301', 'YAMI_039', 'Eu me sinto distante das outras pessoas.', 38, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850028', '88888888-8888-8888-8888-888888888301', 'YAMI_040', 'Eu não penso antes de falar, isso me traz problemas ou machuca as outras pessoas.', 39, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850029', '88888888-8888-8888-8888-888888888301', 'YAMI_041', 'Eu trabalho ou pratico exercícios físicos intensamente para que não precise pensar sobre as coisas que me incomodam.', 40, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885002a', '88888888-8888-8888-8888-888888888301', 'YAMI_042', 'Eu estou bravo porque as pessoas estão tentando tirar a minha liberdade ou independência.', 41, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885002b', '88888888-8888-8888-8888-888888888301', 'YAMI_043', 'Eu não sinto nada.', 42, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885002c', '88888888-8888-8888-8888-888888888301', 'YAMI_044', 'Eu faço o que eu quero fazer, independentemente dos sentimentos e necessidades dos outros.', 43, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885002d', '88888888-8888-8888-8888-888888888301', 'YAMI_045', 'Eu não me permito relaxar ou me divertir até que tenha terminado tudo o que eu deveria fazer.', 44, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885002e', '88888888-8888-8888-8888-888888888301', 'YAMI_046', 'Eu jogo coisas (longe, no chão, na parede, etc.) quando estou com raiva.', 45, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885002f', '88888888-8888-8888-8888-888888888301', 'YAMI_047', 'Eu sinto raiva das outras pessoas.', 46, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850030', '88888888-8888-8888-8888-888888888301', 'YAMI_048', 'Eu me sinto aceito pelas outras pessoas.', 47, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850031', '88888888-8888-8888-8888-888888888301', 'YAMI_049', 'Eu tenho tanta raiva acumulada dentro de mim que preciso extravasá-la.', 48, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850032', '88888888-8888-8888-8888-888888888301', 'YAMI_050', 'Eu me sinto só.', 49, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850033', '88888888-8888-8888-8888-888888888301', 'YAMI_051', 'Eu tento dar o meu melhor em tudo.', 50, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850034', '88888888-8888-8888-8888-888888888301', 'YAMI_052', 'Eu gosto de fazer coisas animadas ou relaxantes para evitar meus sentimentos (p. ex., trabalhar, apostar, comer, fazer compras, atividade sexual, assistir TV).', 51, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850035', '88888888-8888-8888-8888-888888888301', 'YAMI_053', 'Igualdade não existe, então é melhor ser superior aos outros.', 52, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850036', '88888888-8888-8888-8888-888888888301', 'YAMI_054', 'Quando fico bravo, eu frequentemente perco o controle e ameaço as pessoas.', 53, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850037', '88888888-8888-8888-8888-888888888301', 'YAMI_055', 'Em vez de expressar as minhas próprias necessidades, eu deixo que as pessoas faças as coisas do jeito que preferem.', 54, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850038', '88888888-8888-8888-8888-888888888301', 'YAMI_056', 'Se uma pessoa não concorda comigo, ela está contra mim.', 55, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850039', '88888888-8888-8888-8888-888888888301', 'YAMI_057', 'Eu me esforço para estar sempre ocupado; assim, meus pensamentos e sentimentos incômodos me perturbam menos.', 56, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885003a', '88888888-8888-8888-8888-888888888301', 'YAMI_058', 'Quando eu sinto raiva dos outros, me considero uma pessoa má.', 57, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885003b', '88888888-8888-8888-8888-888888888301', 'YAMI_059', 'Eu não quero me envolver com as pessoas.', 58, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885003c', '88888888-8888-8888-8888-888888888301', 'YAMI_060', 'Eu sinto tanta raiva que já cheguei a machucar ou matar alguém.', 59, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885003d', '88888888-8888-8888-8888-888888888301', 'YAMI_061', 'Eu sinto que tenho bastante estabilidade e segurança na minha vida.', 60, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885003e', '88888888-8888-8888-8888-888888888301', 'YAMI_062', 'Eu sei quando expressar as minhas emoções e quando não as expressar.', 61, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885003f', '88888888-8888-8888-8888-888888888301', 'YAMI_063', 'Eu sinto raiva de uma pessoa por ela ter me deixado só ou me abandonado.', 62, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850040', '88888888-8888-8888-8888-888888888301', 'YAMI_064', 'Eu não me sinto conectado às outras pessoas.', 63, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850041', '88888888-8888-8888-8888-888888888301', 'YAMI_065', 'Eu não consigo me disciplinar para fazer coisas que acho desagradáveis, mesmo que eu saiba que são para o meu próprio bem.', 64, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850042', '88888888-8888-8888-8888-888888888301', 'YAMI_066', 'Eu desrespeito as regras e depois me arrependo.', 65, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850043', '88888888-8888-8888-8888-888888888301', 'YAMI_067', 'Eu me sinto humilhado.', 66, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850044', '88888888-8888-8888-8888-888888888301', 'YAMI_068', 'Eu confio na maioria das pessoas.', 67, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850045', '88888888-8888-8888-8888-888888888301', 'YAMI_069', 'Primeiro eu ajo, depois eu penso.', 68, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850046', '88888888-8888-8888-8888-888888888301', 'YAMI_070', 'Eu me entedio facilmente e perco o interesse nas coisas.', 69, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850047', '88888888-8888-8888-8888-888888888301', 'YAMI_071', 'Mesmo com pessoas à minha volta, eu me sinto sozinho.', 70, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850048', '88888888-8888-8888-8888-888888888301', 'YAMI_072', 'Eu não me permito fazer coisas agradáveis que as outras pessoas fazem, pois sou uma pessoa má.', 71, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850049', '88888888-8888-8888-8888-888888888301', 'YAMI_073', 'Eu expresso ou comunico o que necessito sem passar dos limites (p. ex., sem exigir demais dos outros).', 72, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885004a', '88888888-8888-8888-8888-888888888301', 'YAMI_074', 'Eu me sinto especial e melhor do que a maioria das outras pessoas.', 73, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885004b', '88888888-8888-8888-8888-888888888301', 'YAMI_075', 'Eu não me importo com nada; nada faz diferença para mim.', 74, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885004c', '88888888-8888-8888-8888-888888888301', 'YAMI_076', 'Eu fico bravo quando alguém me diz como devo me sentir ou me comportar.', 75, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885004d', '88888888-8888-8888-8888-888888888301', 'YAMI_077', 'Se você não dominar os outros, eles dominarão você.', 76, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885004e', '88888888-8888-8888-8888-888888888301', 'YAMI_078', 'Eu digo o que sinto, ou ajo impulsivamente, sem pensar nas consequências.', 77, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885004f', '88888888-8888-8888-8888-888888888301', 'YAMI_079', 'Eu sinto vontade de gritar/brigar com as pessoas pelo jeito como elas me tratam.', 78, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850050', '88888888-8888-8888-8888-888888888301', 'YAMI_080', 'Eu sou capaz de cuidar de mim mesmo.', 79, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850051', '88888888-8888-8888-8888-888888888301', 'YAMI_081', 'Eu sou bastante crítico em relação aos outros.', 80, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850052', '88888888-8888-8888-8888-888888888301', 'YAMI_082', 'Eu estou sob pressão constante para atingir objetivos e dar conta das coisas.', 81, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850053', '88888888-8888-8888-8888-888888888301', 'YAMI_083', 'Eu estou tentando não cometer erros; caso contrário, irei me criticar fortemente.', 82, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850054', '88888888-8888-8888-8888-888888888301', 'YAMI_084', 'Eu mereço ser punido.', 83, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850055', '88888888-8888-8888-8888-888888888301', 'YAMI_085', 'Eu posso aprender, crescer e mudar.', 84, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850056', '88888888-8888-8888-8888-888888888301', 'YAMI_086', 'Eu quero me distrair dos pensamentos e sentimentos que possam me deixar chateado.', 85, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850057', '88888888-8888-8888-8888-888888888301', 'YAMI_087', 'Eu estou com raiva de mim mesmo.', 86, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850058', '88888888-8888-8888-8888-888888888301', 'YAMI_088', 'Eu me sinto indiferente e apático.', 87, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850059', '88888888-8888-8888-8888-888888888301', 'YAMI_089', 'Eu preciso ser o melhor em tudo que faço.', 88, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885005a', '88888888-8888-8888-8888-888888888301', 'YAMI_090', 'Eu sacrifico prazer, saúde e felicidade para satisfazer meus próprios padrões de exigência.', 89, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885005b', '88888888-8888-8888-8888-888888888301', 'YAMI_091', 'Eu exijo bastante das outras pessoas.', 90, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885005c', '88888888-8888-8888-8888-888888888301', 'YAMI_092', 'Se eu fico com raiva, às vezes fico tão fora do controle que agrido fisicamente ou prejudico outras pessoas.', 91, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885005d', '88888888-8888-8888-8888-888888888301', 'YAMI_093', 'Eu sou inabalável.', 92, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885005e', '88888888-8888-8888-8888-888888888301', 'YAMI_094', 'Eu sou uma pessoa má.', 93, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885005f', '88888888-8888-8888-8888-888888888301', 'YAMI_095', 'Eu me sinto seguro.', 94, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850060', '88888888-8888-8888-8888-888888888301', 'YAMI_096', 'Eu me sinto ouvido, compreendido, acolhido e aceito.', 95, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850061', '88888888-8888-8888-8888-888888888301', 'YAMI_097', 'Para mim, é impossível controlar meus impulsos.', 96, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850062', '88888888-8888-8888-8888-888888888301', 'YAMI_098', 'Eu destruo coisas quando estou com raiva.', 97, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850063', '88888888-8888-8888-8888-888888888301', 'YAMI_099', 'Se você dominar as outras pessoas, nada poderá acontecer com você.', 98, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850064', '88888888-8888-8888-8888-888888888301', 'YAMI_100', 'Eu ajo de forma passiva mesmo quando não gosto do jeito que as coisas estão.', 99, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850065', '88888888-8888-8888-8888-888888888301', 'YAMI_101', 'A minha raiva sai do controle.', 100, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850066', '88888888-8888-8888-8888-888888888301', 'YAMI_102', 'Eu zombo ou intimido outras pessoas.', 101, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850067', '88888888-8888-8888-8888-888888888301', 'YAMI_103', 'Eu sinto vontade de agredir verbal ou fisicamente alguém pelo que essa pessoa fez pra mim.', 102, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850068', '88888888-8888-8888-8888-888888888301', 'YAMI_104', 'Eu sei que há uma forma “certa” e uma “errada” de fazer as coisas. Eu me esforço para fazer as coisas do jeito certo; caso contrário, eu começo a me criticar.', 103, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850069', '88888888-8888-8888-8888-888888888301', 'YAMI_105', 'Eu frequentemente me sinto sozinho no mundo.', 104, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885006a', '88888888-8888-8888-8888-888888888301', 'YAMI_106', 'Eu me sinto fraco e sem saída.', 105, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885006b', '88888888-8888-8888-8888-888888888301', 'YAMI_107', 'Eu sou preguiçoso.', 106, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885006c', '88888888-8888-8888-8888-888888888301', 'YAMI_108', 'Eu posso suportar qualquer coisa que venha das pessoas que são importantes para mim.', 107, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885006d', '88888888-8888-8888-8888-888888888301', 'YAMI_109', 'Eu fui traído ou tratado de forma injusta.', 108, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885006e', '88888888-8888-8888-8888-888888888301', 'YAMI_110', 'Se eu sinto o impulso de fazer alguma coisa, vou e faço.', 109, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885006f', '88888888-8888-8888-8888-888888888301', 'YAMI_111', 'Eu me sinto deixado de lado ou excluído.', 110, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850070', '88888888-8888-8888-8888-888888888301', 'YAMI_112', 'Eu diminuo ou menosprezo os outros.', 111, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850071', '88888888-8888-8888-8888-888888888301', 'YAMI_113', 'Eu me sinto otimista.', 112, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850072', '88888888-8888-8888-8888-888888888301', 'YAMI_114', 'Eu sinto que não deveria ter que seguir as mesmas regras que as outras pessoas seguem.', 113, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850073', '88888888-8888-8888-8888-888888888301', 'YAMI_115', 'Neste momento, minha vida se resume a iniciar e concluir tarefas do jeito certo.', 114, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850074', '88888888-8888-8888-8888-888888888301', 'YAMI_116', 'Eu me cobro para ser mais responsável do que a maioria das outras pessoas.', 115, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850075', '88888888-8888-8888-8888-888888888301', 'YAMI_117', 'Eu consigo me defender de forma adequada quando me sinto criticado injustamente, maltratado ou quando sinto que tiraram vantagem de mim.', 116, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850076', '88888888-8888-8888-8888-888888888301', 'YAMI_118', 'Eu não mereço pena, ou que os outros sejam compreensivos comigo quando algo de ruim me acontece.', 117, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850077', '88888888-8888-8888-8888-888888888301', 'YAMI_119', 'Eu sinto que ninguém me ama.', 118, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850078', '88888888-8888-8888-8888-888888888301', 'YAMI_120', 'Eu sinto que sou uma pessoa fundamentalmente boa.', 119, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-888888850079', '88888888-8888-8888-8888-888888888301', 'YAMI_121', 'Quando necessário, eu concluo tarefas chatas e rotineiras para que eu conquiste aquilo que eu valorizo.', 120, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885007a', '88888888-8888-8888-8888-888888888301', 'YAMI_122', 'Eu me sinto espontâneo e divertido.', 121, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885007b', '88888888-8888-8888-8888-888888888301', 'YAMI_123', 'Às vezes eu fico com tanta raiva que sinto que seria capaz de matar alguém.', 122, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES ('88888888-8888-8888-8888-88888885007c', '88888888-8888-8888-8888-888888888301', 'YAMI_124', 'Eu tenho uma boa noção de quem sou e do que preciso para me deixar feliz.', 123, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.questionnaire_versions (id, questionnaire_id, version, status, scoring_method, scale_min, scale_max, instructions, published_at)
VALUES ('88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888301', 'v1-foundation', 'active', 'weighted_sum', 1, 6, 'INSTRUÇÕES: Este questionário possui afirmações que as pessoas podem usar para descrever a si mesmas. Baseando-se na escala de frequência abaixo, avalie cada item escolhendo o número, entre 1 e 6, que melhor descreve a frequência com que você sente que cada afirmação se aplica a você. Ao responder cada questão, pergunte a si mesmo:', timezone('utc', now()) - interval '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890001', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850001', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 0, '{"source": "YAMI-Modos", "item_number": 1, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890002', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850002', '88888888-8888-8888-8888-888888888711', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 1, '{"source": "YAMI-Modos", "item_number": 2, "mode_name": "Criança  Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890003', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850003', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 2, '{"source": "YAMI-Modos", "item_number": 3, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890004', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850004', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 3, '{"source": "YAMI-Modos", "item_number": 4, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890005', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850005', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 4, '{"source": "YAMI-Modos", "item_number": 5, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890006', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850006', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 5, '{"source": "YAMI-Modos", "item_number": 6, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890007', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850007', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 6, '{"source": "YAMI-Modos", "item_number": 7, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890008', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850008', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 7, '{"source": "YAMI-Modos", "item_number": 8, "mode_name": "Vencido Submisso"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890009', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850009', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 8, '{"source": "YAMI-Modos", "item_number": 9, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889000a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885000a', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 9, '{"source": "YAMI-Modos", "item_number": 10, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889000b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885000b', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 10, '{"source": "YAMI-Modos", "item_number": 11, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889000c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885000c', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 11, '{"source": "YAMI-Modos", "item_number": 12, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889000d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885000d', '88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 12, '{"source": "YAMI-Modos", "item_number": 13, "mode_name": "Criança Indisciplinada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889000e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885000e', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 13, '{"source": "YAMI-Modos", "item_number": 14, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889000f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885000f', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 14, '{"source": "YAMI-Modos", "item_number": 15, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890010', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850010', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 15, '{"source": "YAMI-Modos", "item_number": 16, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890011', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850011', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 16, '{"source": "YAMI-Modos", "item_number": 17, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890012', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850012', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 17, '{"source": "YAMI-Modos", "item_number": 18, "mode_name": "Vencido Submisso"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890013', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850013', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 18, '{"source": "YAMI-Modos", "item_number": 19, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890014', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850014', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 19, '{"source": "YAMI-Modos", "item_number": 20, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890015', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850015', '88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 20, '{"source": "YAMI-Modos", "item_number": 21, "mode_name": "Criança Indisciplinada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890016', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850016', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 21, '{"source": "YAMI-Modos", "item_number": 22, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890017', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850017', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 22, '{"source": "YAMI-Modos", "item_number": 23, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890018', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850018', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 23, '{"source": "YAMI-Modos", "item_number": 24, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890019', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850019', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 24, '{"source": "YAMI-Modos", "item_number": 25, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889001a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885001a', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 25, '{"source": "YAMI-Modos", "item_number": 26, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889001b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885001b', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 26, '{"source": "YAMI-Modos", "item_number": 27, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889001c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885001c', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 27, '{"source": "YAMI-Modos", "item_number": 28, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889001d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885001d', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 28, '{"source": "YAMI-Modos", "item_number": 29, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889001e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885001e', '88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 29, '{"source": "YAMI-Modos", "item_number": 30, "mode_name": "Criança Indisciplinada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889001f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885001f', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 30, '{"source": "YAMI-Modos", "item_number": 31, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890020', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850020', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 31, '{"source": "YAMI-Modos", "item_number": 32, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890021', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850021', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 32, '{"source": "YAMI-Modos", "item_number": 33, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890022', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850022', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 33, '{"source": "YAMI-Modos", "item_number": 34, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890023', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850023', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 34, '{"source": "YAMI-Modos", "item_number": 35, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890024', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850024', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 35, '{"source": "YAMI-Modos", "item_number": 36, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890025', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850025', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 36, '{"source": "YAMI-Modos", "item_number": 37, "mode_name": "Vencido Submisso"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890026', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850026', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 37, '{"source": "YAMI-Modos", "item_number": 38, "mode_name": "Vencido Submisso"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890027', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850027', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 38, '{"source": "YAMI-Modos", "item_number": 39, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890028', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850028', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 39, '{"source": "YAMI-Modos", "item_number": 40, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890029', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850029', '88888888-8888-8888-8888-888888888724', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 40, '{"source": "YAMI-Modos", "item_number": 41, "mode_name": "Autoconfortador Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889002a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885002a', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 41, '{"source": "YAMI-Modos", "item_number": 42, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889002b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885002b', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 42, '{"source": "YAMI-Modos", "item_number": 43, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889002c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885002c', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 43, '{"source": "YAMI-Modos", "item_number": 44, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889002d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885002d', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 44, '{"source": "YAMI-Modos", "item_number": 45, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889002e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885002e', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 45, '{"source": "YAMI-Modos", "item_number": 46, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889002f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885002f', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 46, '{"source": "YAMI-Modos", "item_number": 47, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890030', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850030', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 47, '{"source": "YAMI-Modos", "item_number": 48, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890031', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850031', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 48, '{"source": "YAMI-Modos", "item_number": 49, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890032', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850032', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 49, '{"source": "YAMI-Modos", "item_number": 50, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890033', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850033', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 50, '{"source": "YAMI-Modos", "item_number": 51, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890034', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850034', '88888888-8888-8888-8888-888888888725', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 51, '{"source": "YAMI-Modos", "item_number": 52, "mode_name": "Auto Confortador Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890035', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850035', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 52, '{"source": "YAMI-Modos", "item_number": 53, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890036', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850036', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 53, '{"source": "YAMI-Modos", "item_number": 54, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890037', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850037', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 54, '{"source": "YAMI-Modos", "item_number": 55, "mode_name": "Vencido Submisso"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890038', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850038', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 55, '{"source": "YAMI-Modos", "item_number": 56, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890039', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850039', '88888888-8888-8888-8888-888888888726', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 56, '{"source": "YAMI-Modos", "item_number": 57, "mode_name": "Auto Confortador desligada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889003a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885003a', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 57, '{"source": "YAMI-Modos", "item_number": 58, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889003b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885003b', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 58, '{"source": "YAMI-Modos", "item_number": 59, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889003c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885003c', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 59, '{"source": "YAMI-Modos", "item_number": 60, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889003d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885003d', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 60, '{"source": "YAMI-Modos", "item_number": 61, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889003e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885003e', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 61, '{"source": "YAMI-Modos", "item_number": 62, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889003f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885003f', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 62, '{"source": "YAMI-Modos", "item_number": 63, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890040', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850040', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 63, '{"source": "YAMI-Modos", "item_number": 64, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890041', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850041', '88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 64, '{"source": "YAMI-Modos", "item_number": 65, "mode_name": "Criança Indisciplinada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890042', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850042', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 65, '{"source": "YAMI-Modos", "item_number": 66, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890043', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850043', '88888888-8888-8888-8888-888888888727', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 66, '{"source": "YAMI-Modos", "item_number": 67, "mode_name": "Ciança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890044', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850044', '88888888-8888-8888-8888-888888888728', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 67, '{"source": "YAMI-Modos", "item_number": 68, "mode_name": "Ciança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890045', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850045', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 68, '{"source": "YAMI-Modos", "item_number": 69, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890046', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850046', '88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 69, '{"source": "YAMI-Modos", "item_number": 70, "mode_name": "Criança Indisciplinada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890047', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850047', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 70, '{"source": "YAMI-Modos", "item_number": 71, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890048', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850048', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 71, '{"source": "YAMI-Modos", "item_number": 72, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890049', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850049', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 72, '{"source": "YAMI-Modos", "item_number": 73, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889004a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885004a', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 73, '{"source": "YAMI-Modos", "item_number": 74, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889004b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885004b', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 74, '{"source": "YAMI-Modos", "item_number": 75, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889004c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885004c', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 75, '{"source": "YAMI-Modos", "item_number": 76, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889004d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885004d', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 76, '{"source": "YAMI-Modos", "item_number": 77, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889004e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885004e', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 77, '{"source": "YAMI-Modos", "item_number": 78, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889004f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885004f', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 78, '{"source": "YAMI-Modos", "item_number": 79, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890050', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850050', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 79, '{"source": "YAMI-Modos", "item_number": 80, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890051', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850051', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 80, '{"source": "YAMI-Modos", "item_number": 81, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890052', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850052', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 81, '{"source": "YAMI-Modos", "item_number": 82, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890053', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850053', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 82, '{"source": "YAMI-Modos", "item_number": 83, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890054', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850054', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 83, '{"source": "YAMI-Modos", "item_number": 84, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890055', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850055', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 84, '{"source": "YAMI-Modos", "item_number": 85, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890056', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850056', '88888888-8888-8888-8888-888888888725', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 85, '{"source": "YAMI-Modos", "item_number": 86, "mode_name": "Auto Confortador Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890057', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850057', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 86, '{"source": "YAMI-Modos", "item_number": 87, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890058', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850058', '88888888-8888-8888-8888-888888888723', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 87, '{"source": "YAMI-Modos", "item_number": 88, "mode_name": "Protetor Desligado"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890059', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850059', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 88, '{"source": "YAMI-Modos", "item_number": 89, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889005a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885005a', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 89, '{"source": "YAMI-Modos", "item_number": 90, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889005b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885005b', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 90, '{"source": "YAMI-Modos", "item_number": 91, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889005c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885005c', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 91, '{"source": "YAMI-Modos", "item_number": 92, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889005d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885005d', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 92, '{"source": "YAMI-Modos", "item_number": 93, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889005e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885005e', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 93, '{"source": "YAMI-Modos", "item_number": 94, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889005f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885005f', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 94, '{"source": "YAMI-Modos", "item_number": 95, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890060', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850060', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 95, '{"source": "YAMI-Modos", "item_number": 96, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890061', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850061', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 96, '{"source": "YAMI-Modos", "item_number": 97, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890062', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850062', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 97, '{"source": "YAMI-Modos", "item_number": 98, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890063', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850063', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 98, '{"source": "YAMI-Modos", "item_number": 99, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890064', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850064', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 99, '{"source": "YAMI-Modos", "item_number": 100, "mode_name": "Vencido Submisso"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890065', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850065', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 100, '{"source": "YAMI-Modos", "item_number": 101, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890066', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850066', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 101, '{"source": "YAMI-Modos", "item_number": 102, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890067', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850067', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 102, '{"source": "YAMI-Modos", "item_number": 103, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890068', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850068', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 103, '{"source": "YAMI-Modos", "item_number": 104, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890069', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850069', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 104, '{"source": "YAMI-Modos", "item_number": 105, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889006a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885006a', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 105, '{"source": "YAMI-Modos", "item_number": 106, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889006b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885006b', '88888888-8888-8888-8888-888888888718', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 106, '{"source": "YAMI-Modos", "item_number": 107, "mode_name": "Criança Indisciplinada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889006c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885006c', '88888888-8888-8888-8888-888888888715', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 107, '{"source": "YAMI-Modos", "item_number": 108, "mode_name": "Vencido Submisso"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889006d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885006d', '88888888-8888-8888-8888-888888888722', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 108, '{"source": "YAMI-Modos", "item_number": 109, "mode_name": "Criança Zangada"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889006e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885006e', '88888888-8888-8888-8888-888888888717', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 109, '{"source": "YAMI-Modos", "item_number": 110, "mode_name": "Criança Impulsiva"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889006f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885006f', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 110, '{"source": "YAMI-Modos", "item_number": 111, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890070', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850070', '88888888-8888-8888-8888-888888888710', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 111, '{"source": "YAMI-Modos", "item_number": 112, "mode_name": "Intimidação e Ataque"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890071', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850071', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 112, '{"source": "YAMI-Modos", "item_number": 113, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890072', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850072', '88888888-8888-8888-8888-888888888716', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 113, '{"source": "YAMI-Modos", "item_number": 114, "mode_name": "Auto Engrandecedor"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890073', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850073', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 114, '{"source": "YAMI-Modos", "item_number": 115, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890074', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850074', '88888888-8888-8888-8888-888888888714', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 115, '{"source": "YAMI-Modos", "item_number": 116, "mode_name": "Pais Exigentes e Críticos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890075', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850075', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 116, '{"source": "YAMI-Modos", "item_number": 117, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890076', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850076', '88888888-8888-8888-8888-888888888712', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 117, '{"source": "YAMI-Modos", "item_number": 118, "mode_name": "Pais Punitivos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890077', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850077', '88888888-8888-8888-8888-888888888713', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 118, '{"source": "YAMI-Modos", "item_number": 119, "mode_name": "Criança Vulnerável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890078', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850078', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 119, '{"source": "YAMI-Modos", "item_number": 120, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-888888890079', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888850079', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 120, '{"source": "YAMI-Modos", "item_number": 121, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889007a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885007a', '88888888-8888-8888-8888-888888888720', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 121, '{"source": "YAMI-Modos", "item_number": 122, "mode_name": "Criança Feliz"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889007b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885007b', '88888888-8888-8888-8888-888888888719', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 122, '{"source": "YAMI-Modos", "item_number": 123, "mode_name": "Criança Raivosa"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-88888889007c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-88888885007c', '88888888-8888-8888-8888-888888888721', '88888888-8888-8888-8888-888888888601', 1, false, 1, 6, 123, '{"source": "YAMI-Modos", "item_number": 124, "mode_name": "Adulto Saudável"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880001', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888710', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880002', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888710', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880003', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888710', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888000b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888711', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888000c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888711', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888000d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888711', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880015', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888712', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880016', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888712', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880017', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888712', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888001f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888713', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880020', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888713', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880021', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888713', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880029', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888714', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888002a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888714', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888002b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888714', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880033', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888715', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880034', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888715', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880035', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888715', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888003d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888716', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888003e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888716', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888003f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888716', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880047', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888717', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880048', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888717', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880049', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888717', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880051', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888718', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880052', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888718', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880053', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888718', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888005b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888719', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888005c', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888719', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888005d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888719', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880065', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888720', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880066', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888720', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880067', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888720', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888006f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888721', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880070', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888721', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880071', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888721', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880079', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888722', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888007a', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888722', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888007b', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888722', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880083', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888723', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880084', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888723', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880085', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888723', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888008d', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888724', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888008e', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888724', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-08888888008f', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888724', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880097', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888725', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880098', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888725', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-088888880099', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888725', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800a1', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888726', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800a2', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888726', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800a3', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888726', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800ab', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888727', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800ac', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888727', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800ad', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888727', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800b5', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888728', NULL, 'Baixo', 1.0, 2.4, 'severity_low', 0, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800b6', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888728', NULL, 'Médio', 2.5, 3.9, 'severity_moderate', 1, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata)
VALUES ('88888888-8888-8888-8888-0888888800b7', '88888888-8888-8888-8888-888888888801', '88888888-8888-8888-8888-888888888728', NULL, 'Ativado', 4.0, 5.0, 'severity_high', 2, '{"source": "YAMI-Modos"}'::jsonb)
ON CONFLICT (id) DO NOTHING;

COMMIT;