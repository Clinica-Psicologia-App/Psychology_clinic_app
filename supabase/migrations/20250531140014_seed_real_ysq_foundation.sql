-- =============================================================================
-- Migration 014: carga YSQ-Esquemas (ProjetoApp_questionários.xlsx)
-- Fonte: aba YSQ-Esquemas — não altera MVP_DEMO nem seed §16 (6666…).
-- Questionário: YSQ_FOUNDATION_V1 | 5 domínios | 18 esquemas | 90 itens
-- =============================================================================

BEGIN;

-- Questionário
INSERT INTO public.questionnaires (id, code, name, description, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777301',
  'YSQ_FOUNDATION_V1',
  'YSQ — Fundação (Esquemas)',
  '90 afirmações da aba YSQ-Esquemas (ProjetoApp_questionários.xlsx). Escala Likert 1–6. Requer validação clínica/licenciamento antes de uso terapêutico oficial.',
  true
)
ON CONFLICT (id) DO NOTHING;

-- Domínios (schema_domains)
INSERT INTO public.schema_domains (id, clinic_id, code, name, description, sort_order, is_active)
VALUES
  ('77777777-7777-7777-7777-777777777601', NULL, 'YSQ_DOMAIN_DISCONNECTION_REJECTION', 'Primeiro Domínio-Desconexão e rejeição', 'Domínio importado da planilha YSQ-Esquemas.', 0, true),
  ('77777777-7777-7777-7777-777777777602', NULL, 'YSQ_DOMAIN_IMPAIRED_AUTONOMY', 'Segundo Domínio-Autonomia e Desempenho prejudicados', 'Domínio importado da planilha YSQ-Esquemas.', 1, true),
  ('77777777-7777-7777-7777-777777777603', NULL, 'YSQ_DOMAIN_IMPAIRED_LIMITS', 'Terceiro Domínio-Limites prejudicados', 'Domínio importado da planilha YSQ-Esquemas.', 2, true),
  ('77777777-7777-7777-7777-777777777604', NULL, 'YSQ_DOMAIN_OTHER_DIRECTEDNESS', 'Quarto Domínio-Direcionamento para o outro', 'Domínio importado da planilha YSQ-Esquemas.', 3, true),
  ('77777777-7777-7777-7777-777777777605', NULL, 'YSQ_DOMAIN_OVERVIGILANCE_INHIBITION', 'Quinto Domínio-Supervigilância e Inibição', 'Domínio importado da planilha YSQ-Esquemas.', 4, true)
ON CONFLICT (id) DO NOTHING;

-- Esquemas (schemas)
INSERT INTO public.schemas (id, domain_id, clinic_id, code, name, description, sort_order, is_active)
VALUES
  ('77777777-7777-7777-7777-777777777710', '77777777-7777-7777-7777-777777777601', NULL, 'YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 'Abandono/Instabilidade', 'Esquema importado da planilha YSQ-Esquemas.', 0, true),
  ('77777777-7777-7777-7777-777777777711', '77777777-7777-7777-7777-777777777601', NULL, 'YSQ_SCHEMA_MISTRUST_ABUSE', 'Desconfiança/Abuso', 'Esquema importado da planilha YSQ-Esquemas.', 1, true),
  ('77777777-7777-7777-7777-777777777712', '77777777-7777-7777-7777-777777777601', NULL, 'YSQ_SCHEMA_EMOTIONAL_DEPRIVATION', 'Privação emocional', 'Esquema importado da planilha YSQ-Esquemas.', 2, true),
  ('77777777-7777-7777-7777-777777777713', '77777777-7777-7777-7777-777777777601', NULL, 'YSQ_SCHEMA_DEFECTIVENESS_SHAME', 'Defectividade/Vergonha', 'Esquema importado da planilha YSQ-Esquemas.', 3, true),
  ('77777777-7777-7777-7777-777777777714', '77777777-7777-7777-7777-777777777601', NULL, 'YSQ_SCHEMA_SOCIAL_ISOLATION', 'Isolamento social/Alienação', 'Esquema importado da planilha YSQ-Esquemas.', 4, true),
  ('77777777-7777-7777-7777-777777777715', '77777777-7777-7777-7777-777777777602', NULL, 'YSQ_SCHEMA_DEPENDENCE_INCOMPETENCE', 'Dependência/Incompetência', 'Esquema importado da planilha YSQ-Esquemas.', 0, true),
  ('77777777-7777-7777-7777-777777777716', '77777777-7777-7777-7777-777777777602', NULL, 'YSQ_SCHEMA_VULNERABILITY', 'Vulnerabilidade ao dano ou doença', 'Esquema importado da planilha YSQ-Esquemas.', 1, true),
  ('77777777-7777-7777-7777-777777777717', '77777777-7777-7777-7777-777777777602', NULL, 'YSQ_SCHEMA_ENMESHMENT_UNDEVELOPED_SELF', 'Emaranhamento/Self subdesenvolvido', 'Esquema importado da planilha YSQ-Esquemas.', 2, true),
  ('77777777-7777-7777-7777-777777777718', '77777777-7777-7777-7777-777777777602', NULL, 'YSQ_SCHEMA_FAILURE', 'Fracasso', 'Esquema importado da planilha YSQ-Esquemas.', 3, true),
  ('77777777-7777-7777-7777-777777777719', '77777777-7777-7777-7777-777777777603', NULL, 'YSQ_SCHEMA_ENTITLEMENT_GRANDIOSITY', 'Merecimento/Grandiosidade', 'Esquema importado da planilha YSQ-Esquemas.', 0, true),
  ('77777777-7777-7777-7777-777777777720', '77777777-7777-7777-7777-777777777603', NULL, 'YSQ_SCHEMA_INSUFFICIENT_SELF_CONTROL', 'Autocontrole/Autodisciplina insuficientes', 'Esquema importado da planilha YSQ-Esquemas.', 1, true),
  ('77777777-7777-7777-7777-777777777721', '77777777-7777-7777-7777-777777777604', NULL, 'YSQ_SCHEMA_SUBJUGATION', 'Subjugação', 'Esquema importado da planilha YSQ-Esquemas.', 0, true),
  ('77777777-7777-7777-7777-777777777722', '77777777-7777-7777-7777-777777777604', NULL, 'YSQ_SCHEMA_SELF_SACRIFICE', 'Autos sacrifico', 'Esquema importado da planilha YSQ-Esquemas.', 1, true),
  ('77777777-7777-7777-7777-777777777723', '77777777-7777-7777-7777-777777777604', NULL, 'YSQ_SCHEMA_APPROVAL_SEEKING', 'Busca de aprovação/Reconhecimento', 'Esquema importado da planilha YSQ-Esquemas.', 2, true),
  ('77777777-7777-7777-7777-777777777724', '77777777-7777-7777-7777-777777777605', NULL, 'YSQ_SCHEMA_NEGATIVISM_PESSIMISM', 'Negativismo/Pessimismo', 'Esquema importado da planilha YSQ-Esquemas.', 0, true),
  ('77777777-7777-7777-7777-777777777725', '77777777-7777-7777-7777-777777777605', NULL, 'YSQ_SCHEMA_EMOTIONAL_INHIBITION', 'Inibição emocional', 'Esquema importado da planilha YSQ-Esquemas.', 1, true),
  ('77777777-7777-7777-7777-777777777726', '77777777-7777-7777-7777-777777777605', NULL, 'YSQ_SCHEMA_UNRELENTING_STANDARDS', 'Padrões inflexíveis/Crítica exagerada', 'Esquema importado da planilha YSQ-Esquemas.', 2, true),
  ('77777777-7777-7777-7777-777777777727', '77777777-7777-7777-7777-777777777605', NULL, 'YSQ_SCHEMA_PUNITIVENESS', 'Postura punitiva', 'Esquema importado da planilha YSQ-Esquemas.', 3, true)
ON CONFLICT (id) DO NOTHING;

-- Perguntas (90 afirmações)
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777501', '77777777-7777-7777-7777-777777777301', 'YSQ_01', 'Tenho medo de que pessoas importantes para mim vão embora.', 0, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777502', '77777777-7777-7777-7777-777777777301', 'YSQ_02', 'Fico muito ansioso(a) quando alguém próximo se afasta.', 1, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777503', '77777777-7777-7777-7777-777777777301', 'YSQ_03', 'Sinto que meus relacionamentos nunca são totalmente seguros.', 2, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777504', '77777777-7777-7777-7777-777777777301', 'YSQ_04', 'Pequenos sinais de distância me deixam muito preocupado(a).', 3, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777505', '77777777-7777-7777-7777-777777777301', 'YSQ_05', 'Tenho receio de ficar sozinho(a).', 4, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777506', '77777777-7777-7777-7777-777777777301', 'YSQ_06', 'Costumo esperar que as pessoas me magoem ou enganem.', 5, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777507', '77777777-7777-7777-7777-777777777301', 'YSQ_07', 'Tenho dificuldade em confiar plenamente nos outros.', 6, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777508', '77777777-7777-7777-7777-777777777301', 'YSQ_08', 'Fico sempre atento(a) para não ser passado(a) para trás.', 7, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777509', '77777777-7777-7777-7777-777777777301', 'YSQ_09', 'Acredito que as pessoas costumam agir por interesse.', 8, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777510', '77777777-7777-7777-7777-777777777301', 'YSQ_10', 'Evito me abrir para não ser ferido(a).', 9, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777511', '77777777-7777-7777-7777-777777777301', 'YSQ_11', 'Sinto que ninguém realmente entende o que eu sinto.', 10, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777512', '77777777-7777-7777-7777-777777777301', 'YSQ_12', 'Falta alguém que cuide de mim emocionalmente.', 11, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777513', '77777777-7777-7777-7777-777777777301', 'YSQ_13', 'Aprendi a não esperar apoio dos outros.', 12, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777514', '77777777-7777-7777-7777-777777777301', 'YSQ_14', 'Mesmo em relacionamentos, sinto um vazio emocional.', 13, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777515', '77777777-7777-7777-7777-777777777301', 'YSQ_15', 'Minhas necessidades emocionais costumam ficar em segundo plano.', 14, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777516', '77777777-7777-7777-7777-777777777301', 'YSQ_16', 'Sinto que há algo errado comigo.', 15, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777517', '77777777-7777-7777-7777-777777777301', 'YSQ_17', 'Tenho medo de que, se me conhecerem de verdade, não gostem de mim.', 16, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777518', '77777777-7777-7777-7777-777777777301', 'YSQ_18', 'Me sinto inferior às outras pessoas.', 17, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777519', '77777777-7777-7777-7777-777777777301', 'YSQ_19', 'Costumo sentir vergonha de quem eu sou.', 18, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777520', '77777777-7777-7777-7777-777777777301', 'YSQ_20', 'Acredito que não sou bom(a) o suficiente.', 19, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777521', '77777777-7777-7777-7777-777777777301', 'YSQ_21', 'Sinto que não pertenço a lugar nenhum.', 20, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777522', '77777777-7777-7777-7777-777777777301', 'YSQ_22', 'Me vejo como diferente das outras pessoas.', 21, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777523', '77777777-7777-7777-7777-777777777301', 'YSQ_23', 'Tenho dificuldade em me sentir parte de grupos.', 22, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777524', '77777777-7777-7777-7777-777777777301', 'YSQ_24', 'Costumo me sentir deslocado(a).', 23, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777525', '77777777-7777-7777-7777-777777777301', 'YSQ_25', 'Acredito que os outros se encaixam melhor do que eu.', 24, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777526', '77777777-7777-7777-7777-777777777301', 'YSQ_26', 'Tenho dificuldade em tomar decisões sozinho(a).', 25, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777527', '77777777-7777-7777-7777-777777777301', 'YSQ_27', 'Sinto que preciso de alguém para me orientar.', 26, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777528', '77777777-7777-7777-7777-777777777301', 'YSQ_28', 'Tenho medo de não dar conta das responsabilidades.', 27, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777529', '77777777-7777-7777-7777-777777777301', 'YSQ_29', 'Me sinto inseguro(a) quando preciso agir por conta própria.', 28, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777530', '77777777-7777-7777-7777-777777777301', 'YSQ_30', 'Evito situações em que preciso assumir controle.', 29, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777531', '77777777-7777-7777-7777-777777777301', 'YSQ_31', 'Vivo com medo de que algo ruim aconteça.', 30, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777532', '77777777-7777-7777-7777-777777777301', 'YSQ_32', 'Preocupo-me excessivamente com doenças ou acidentes.', 31, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777533', '77777777-7777-7777-7777-777777777301', 'YSQ_33', 'Tenho dificuldade em relaxar porque espero problemas.', 32, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777534', '77777777-7777-7777-7777-777777777301', 'YSQ_34', 'Pequenos sinais já me fazem imaginar o pior.', 33, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777535', '77777777-7777-7777-7777-777777777301', 'YSQ_35', 'Sinto que o mundo é um lugar perigoso.', 34, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777536', '77777777-7777-7777-7777-777777777301', 'YSQ_36', 'Tenho dificuldade em saber o que eu realmente quero.', 35, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777537', '77777777-7777-7777-7777-777777777301', 'YSQ_37', 'Minhas decisões são muito influenciadas por pessoas próximas.', 36, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777538', '77777777-7777-7777-7777-777777777301', 'YSQ_38', 'Tenho medo de me afastar emocionalmente de quem amo.', 37, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777539', '77777777-7777-7777-7777-777777777301', 'YSQ_39', 'Sinto que minha identidade depende dos outros.', 38, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777540', '77777777-7777-7777-7777-777777777301', 'YSQ_40', 'Me sinto perdido(a) quando estou sozinho(a).', 39, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777541', '77777777-7777-7777-7777-777777777301', 'YSQ_41', 'Acredito que vou falhar no que tento fazer.', 40, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777542', '77777777-7777-7777-7777-777777777301', 'YSQ_42', 'Me comparo negativamente com outras pessoas.', 41, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777543', '77777777-7777-7777-7777-777777777301', 'YSQ_43', 'Evito desafios por medo de fracassar.', 42, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777544', '77777777-7777-7777-7777-777777777301', 'YSQ_44', 'Sinto que não sou tão capaz quanto os outros.', 43, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777545', '77777777-7777-7777-7777-777777777301', 'YSQ_45', 'Tenho dificuldade em reconhecer minhas conquistas.', 44, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777546', '77777777-7777-7777-7777-777777777301', 'YSQ_46', 'Fico muito frustrado(a) quando as coisas não saem como quero.', 45, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777547', '77777777-7777-7777-7777-777777777301', 'YSQ_47', 'Tenho dificuldade em aceitar regras ou limites.', 46, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777548', '77777777-7777-7777-7777-777777777301', 'YSQ_48', 'Acredito que mereço tratamento especial.', 47, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777549', '77777777-7777-7777-7777-777777777301', 'YSQ_49', 'Me irrito quando sou contrariado(a).', 48, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777550', '77777777-7777-7777-7777-777777777301', 'YSQ_50', 'Acho difícil lidar com frustrações.', 49, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777551', '77777777-7777-7777-7777-777777777301', 'YSQ_51', 'Tenho dificuldade em manter esforços por muito tempo.', 50, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777552', '77777777-7777-7777-7777-777777777301', 'YSQ_52', 'Costumo agir por impulso.', 51, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777553', '77777777-7777-7777-7777-777777777301', 'YSQ_53', 'Procrastino mesmo sabendo das consequências.', 52, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777554', '77777777-7777-7777-7777-777777777301', 'YSQ_54', 'Evito tarefas que exigem persistência.', 53, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777555', '77777777-7777-7777-7777-777777777301', 'YSQ_55', 'Tenho dificuldade em lidar com frustrações.', 54, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777556', '77777777-7777-7777-7777-777777777301', 'YSQ_56', 'Evito discordar para não gerar conflitos.', 55, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777557', '77777777-7777-7777-7777-777777777301', 'YSQ_57', 'Costumo colocar a vontade dos outros acima da minha.', 56, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777558', '77777777-7777-7777-7777-777777777301', 'YSQ_58', 'Tenho dificuldade em dizer “não”.', 57, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777559', '77777777-7777-7777-7777-777777777301', 'YSQ_59', 'Engulo o que sinto para manter a paz.', 58, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777560', '77777777-7777-7777-7777-777777777301', 'YSQ_60', 'Sinto que minhas necessidades não importam tanto.', 59, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777561', '77777777-7777-7777-7777-777777777301', 'YSQ_61', 'Costumo cuidar mais dos outros do que de mim.', 60, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777562', '77777777-7777-7777-7777-777777777301', 'YSQ_62', 'Me sinto culpado(a) quando priorizo minhas necessidades.', 61, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777563', '77777777-7777-7777-7777-777777777301', 'YSQ_63', 'Coloco as necessidades dos outros em primeiro lugar.', 62, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777564', '77777777-7777-7777-7777-777777777301', 'YSQ_64', 'Me sinto responsável pelo bem-estar alheio.', 63, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777565', '77777777-7777-7777-7777-777777777301', 'YSQ_65', 'Acabo me esquecendo de mim.', 64, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777566', '77777777-7777-7777-7777-777777777301', 'YSQ_66', 'Preciso da aprovação dos outros para me sentir bem.', 65, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777567', '77777777-7777-7777-7777-777777777301', 'YSQ_67', 'Fico muito mal quando sou criticado(a).', 66, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777568', '77777777-7777-7777-7777-777777777301', 'YSQ_68', 'Minha autoestima depende do que pensam de mim.', 67, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777569', '77777777-7777-7777-7777-777777777301', 'YSQ_69', 'Me esforço para agradar e ser reconhecido(a).', 68, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777570', '77777777-7777-7777-7777-777777777301', 'YSQ_70', 'Tenho medo de decepcionar.', 69, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777571', '77777777-7777-7777-7777-777777777301', 'YSQ_71', 'Costumo esperar que as coisas deem errado.', 70, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777572', '77777777-7777-7777-7777-777777777301', 'YSQ_72', 'Foco mais nos problemas do que nas coisas boas.', 71, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777573', '77777777-7777-7777-7777-777777777301', 'YSQ_73', 'Tenho dificuldade em sentir esperança.', 72, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777574', '77777777-7777-7777-7777-777777777301', 'YSQ_74', 'Sempre imagino cenários negativos.', 73, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777575', '77777777-7777-7777-7777-777777777301', 'YSQ_75', 'Me preocupo excessivamente com o futuro.', 74, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777576', '77777777-7777-7777-7777-777777777301', 'YSQ_76', 'Evito demonstrar o que sinto.', 75, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777577', '77777777-7777-7777-7777-777777777301', 'YSQ_77', 'Tenho dificuldade em expressar emoções.', 76, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777578', '77777777-7777-7777-7777-777777777301', 'YSQ_78', 'Costumo me controlar demais emocionalmente.', 77, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777579', '77777777-7777-7777-7777-777777777301', 'YSQ_79', 'Tenho medo de parecer fraco(a) se mostrar sentimentos.', 78, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777580', '77777777-7777-7777-7777-777777777301', 'YSQ_80', 'Me sinto travado(a) emocionalmente.', 79, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777581', '77777777-7777-7777-7777-777777777301', 'YSQ_81', 'Me cobro muito para ser perfeito(a).', 80, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777582', '77777777-7777-7777-7777-777777777301', 'YSQ_82', 'Sinto que nunca faço o suficiente.', 81, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777583', '77777777-7777-7777-7777-777777777301', 'YSQ_83', 'Tenho padrões muito altos para mim.', 82, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777584', '77777777-7777-7777-7777-777777777301', 'YSQ_84', 'Fico frustrado(a) quando não atinjo expectativas.', 83, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777585', '77777777-7777-7777-7777-777777777301', 'YSQ_85', 'Tenho dificuldade em relaxar e aproveitar.', 84, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777586', '77777777-7777-7777-7777-777777777301', 'YSQ_86', 'Acho que erros devem ser duramente punidos.', 85, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777587', '77777777-7777-7777-7777-777777777301', 'YSQ_87', 'Tenho dificuldade em perdoar a mim mesmo(a).', 86, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777588', '77777777-7777-7777-7777-777777777301', 'YSQ_88', 'Sou muito rígido(a) com falhas.', 87, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777589', '77777777-7777-7777-7777-777777777301', 'YSQ_89', 'Me culpo intensamente quando erro.', 88, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.questions (id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active)
VALUES (
  '77777777-7777-7777-7777-777777777590', '77777777-7777-7777-7777-777777777301', 'YSQ_90', 'Acredito que as pessoas merecem punição quando erram.', 89, 'likert_scale', 1, 6, true
)
ON CONFLICT (id) DO NOTHING;

-- Versão ativa (regras de pontuação)
INSERT INTO public.questionnaire_versions (
  id, questionnaire_id, version, status, scoring_method, scale_min, scale_max, instructions, published_at
) VALUES (
  '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777301', 'v1-foundation', 'active', 'weighted_sum', 1, 6,
  'Abaixo estão frases sobre sentimentos, pensamentos e comportamentos. Leia com atenção e indique o quanto cada frase se parece com você na maior parte da sua vida, não apenas no momento atual. Quando não tiver certeza, baseie sua resposta no que você sente emocionalmente.',
  timezone('utc', now()) - interval '1 day'
)
ON CONFLICT (id) DO NOTHING;

-- Regras de pontuação (1 item → 1 esquema; peso 1; reverse não indicado na planilha)
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777901', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777501', '77777777-7777-7777-7777-777777777710', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 0, '{"source": "YSQ-Esquemas", "item_number": 1}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777902', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777502', '77777777-7777-7777-7777-777777777710', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 1, '{"source": "YSQ-Esquemas", "item_number": 2}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777903', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777503', '77777777-7777-7777-7777-777777777710', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 2, '{"source": "YSQ-Esquemas", "item_number": 3}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777904', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777504', '77777777-7777-7777-7777-777777777710', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 3, '{"source": "YSQ-Esquemas", "item_number": 4}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777905', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777505', '77777777-7777-7777-7777-777777777710', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 4, '{"source": "YSQ-Esquemas", "item_number": 5}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777906', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777506', '77777777-7777-7777-7777-777777777711', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 5, '{"source": "YSQ-Esquemas", "item_number": 6}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777907', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777507', '77777777-7777-7777-7777-777777777711', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 6, '{"source": "YSQ-Esquemas", "item_number": 7}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777908', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777508', '77777777-7777-7777-7777-777777777711', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 7, '{"source": "YSQ-Esquemas", "item_number": 8}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777909', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777509', '77777777-7777-7777-7777-777777777711', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 8, '{"source": "YSQ-Esquemas", "item_number": 9}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777910', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777510', '77777777-7777-7777-7777-777777777711', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 9, '{"source": "YSQ-Esquemas", "item_number": 10}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777911', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777511', '77777777-7777-7777-7777-777777777712', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 10, '{"source": "YSQ-Esquemas", "item_number": 11}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777912', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777512', '77777777-7777-7777-7777-777777777712', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 11, '{"source": "YSQ-Esquemas", "item_number": 12}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777913', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777513', '77777777-7777-7777-7777-777777777712', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 12, '{"source": "YSQ-Esquemas", "item_number": 13}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777914', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777514', '77777777-7777-7777-7777-777777777712', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 13, '{"source": "YSQ-Esquemas", "item_number": 14}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777915', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777515', '77777777-7777-7777-7777-777777777712', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 14, '{"source": "YSQ-Esquemas", "item_number": 15}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777916', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777516', '77777777-7777-7777-7777-777777777713', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 15, '{"source": "YSQ-Esquemas", "item_number": 16}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777917', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777517', '77777777-7777-7777-7777-777777777713', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 16, '{"source": "YSQ-Esquemas", "item_number": 17}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777918', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777518', '77777777-7777-7777-7777-777777777713', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 17, '{"source": "YSQ-Esquemas", "item_number": 18}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777919', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777519', '77777777-7777-7777-7777-777777777713', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 18, '{"source": "YSQ-Esquemas", "item_number": 19}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777920', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777520', '77777777-7777-7777-7777-777777777713', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 19, '{"source": "YSQ-Esquemas", "item_number": 20}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777921', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777521', '77777777-7777-7777-7777-777777777714', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 20, '{"source": "YSQ-Esquemas", "item_number": 21}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777922', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777522', '77777777-7777-7777-7777-777777777714', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 21, '{"source": "YSQ-Esquemas", "item_number": 22}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777923', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777523', '77777777-7777-7777-7777-777777777714', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 22, '{"source": "YSQ-Esquemas", "item_number": 23}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777924', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777524', '77777777-7777-7777-7777-777777777714', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 23, '{"source": "YSQ-Esquemas", "item_number": 24}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777925', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777525', '77777777-7777-7777-7777-777777777714', '77777777-7777-7777-7777-777777777601',
  1, false, 1, 6, 24, '{"source": "YSQ-Esquemas", "item_number": 25}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777926', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777526', '77777777-7777-7777-7777-777777777715', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 25, '{"source": "YSQ-Esquemas", "item_number": 26}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777927', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777527', '77777777-7777-7777-7777-777777777715', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 26, '{"source": "YSQ-Esquemas", "item_number": 27}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777928', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777528', '77777777-7777-7777-7777-777777777715', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 27, '{"source": "YSQ-Esquemas", "item_number": 28}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777929', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777529', '77777777-7777-7777-7777-777777777715', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 28, '{"source": "YSQ-Esquemas", "item_number": 29}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777930', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777530', '77777777-7777-7777-7777-777777777715', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 29, '{"source": "YSQ-Esquemas", "item_number": 30}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777931', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777531', '77777777-7777-7777-7777-777777777716', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 30, '{"source": "YSQ-Esquemas", "item_number": 31}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777932', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777532', '77777777-7777-7777-7777-777777777716', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 31, '{"source": "YSQ-Esquemas", "item_number": 32}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777933', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777533', '77777777-7777-7777-7777-777777777716', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 32, '{"source": "YSQ-Esquemas", "item_number": 33}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777934', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777534', '77777777-7777-7777-7777-777777777716', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 33, '{"source": "YSQ-Esquemas", "item_number": 34}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777935', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777535', '77777777-7777-7777-7777-777777777716', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 34, '{"source": "YSQ-Esquemas", "item_number": 35}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777936', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777536', '77777777-7777-7777-7777-777777777717', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 35, '{"source": "YSQ-Esquemas", "item_number": 36}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777937', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777537', '77777777-7777-7777-7777-777777777717', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 36, '{"source": "YSQ-Esquemas", "item_number": 37}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777938', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777538', '77777777-7777-7777-7777-777777777717', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 37, '{"source": "YSQ-Esquemas", "item_number": 38}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777939', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777539', '77777777-7777-7777-7777-777777777717', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 38, '{"source": "YSQ-Esquemas", "item_number": 39}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777940', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777540', '77777777-7777-7777-7777-777777777717', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 39, '{"source": "YSQ-Esquemas", "item_number": 40}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777941', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777541', '77777777-7777-7777-7777-777777777718', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 40, '{"source": "YSQ-Esquemas", "item_number": 41}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777942', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777542', '77777777-7777-7777-7777-777777777718', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 41, '{"source": "YSQ-Esquemas", "item_number": 42}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777943', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777543', '77777777-7777-7777-7777-777777777718', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 42, '{"source": "YSQ-Esquemas", "item_number": 43}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777944', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777544', '77777777-7777-7777-7777-777777777718', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 43, '{"source": "YSQ-Esquemas", "item_number": 44}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777945', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777545', '77777777-7777-7777-7777-777777777718', '77777777-7777-7777-7777-777777777602',
  1, false, 1, 6, 44, '{"source": "YSQ-Esquemas", "item_number": 45}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777946', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777546', '77777777-7777-7777-7777-777777777719', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 45, '{"source": "YSQ-Esquemas", "item_number": 46}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777947', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777547', '77777777-7777-7777-7777-777777777719', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 46, '{"source": "YSQ-Esquemas", "item_number": 47}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777948', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777548', '77777777-7777-7777-7777-777777777719', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 47, '{"source": "YSQ-Esquemas", "item_number": 48}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777949', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777549', '77777777-7777-7777-7777-777777777719', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 48, '{"source": "YSQ-Esquemas", "item_number": 49}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777950', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777550', '77777777-7777-7777-7777-777777777719', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 49, '{"source": "YSQ-Esquemas", "item_number": 50}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777951', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777551', '77777777-7777-7777-7777-777777777720', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 50, '{"source": "YSQ-Esquemas", "item_number": 51}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777952', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777552', '77777777-7777-7777-7777-777777777720', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 51, '{"source": "YSQ-Esquemas", "item_number": 52}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777953', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777553', '77777777-7777-7777-7777-777777777720', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 52, '{"source": "YSQ-Esquemas", "item_number": 53}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777954', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777554', '77777777-7777-7777-7777-777777777720', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 53, '{"source": "YSQ-Esquemas", "item_number": 54}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777955', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777555', '77777777-7777-7777-7777-777777777720', '77777777-7777-7777-7777-777777777603',
  1, false, 1, 6, 54, '{"source": "YSQ-Esquemas", "item_number": 55}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777956', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777556', '77777777-7777-7777-7777-777777777721', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 55, '{"source": "YSQ-Esquemas", "item_number": 56}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777957', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777557', '77777777-7777-7777-7777-777777777721', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 56, '{"source": "YSQ-Esquemas", "item_number": 57}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777958', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777558', '77777777-7777-7777-7777-777777777721', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 57, '{"source": "YSQ-Esquemas", "item_number": 58}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777959', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777559', '77777777-7777-7777-7777-777777777721', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 58, '{"source": "YSQ-Esquemas", "item_number": 59}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777960', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777560', '77777777-7777-7777-7777-777777777721', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 59, '{"source": "YSQ-Esquemas", "item_number": 60}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777961', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777561', '77777777-7777-7777-7777-777777777722', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 60, '{"source": "YSQ-Esquemas", "item_number": 61}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777962', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777562', '77777777-7777-7777-7777-777777777722', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 61, '{"source": "YSQ-Esquemas", "item_number": 62}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777963', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777563', '77777777-7777-7777-7777-777777777722', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 62, '{"source": "YSQ-Esquemas", "item_number": 63}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777964', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777564', '77777777-7777-7777-7777-777777777722', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 63, '{"source": "YSQ-Esquemas", "item_number": 64}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777965', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777565', '77777777-7777-7777-7777-777777777722', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 64, '{"source": "YSQ-Esquemas", "item_number": 65}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777966', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777566', '77777777-7777-7777-7777-777777777723', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 65, '{"source": "YSQ-Esquemas", "item_number": 66}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777967', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777567', '77777777-7777-7777-7777-777777777723', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 66, '{"source": "YSQ-Esquemas", "item_number": 67}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777968', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777568', '77777777-7777-7777-7777-777777777723', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 67, '{"source": "YSQ-Esquemas", "item_number": 68}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777969', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777569', '77777777-7777-7777-7777-777777777723', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 68, '{"source": "YSQ-Esquemas", "item_number": 69}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777970', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777570', '77777777-7777-7777-7777-777777777723', '77777777-7777-7777-7777-777777777604',
  1, false, 1, 6, 69, '{"source": "YSQ-Esquemas", "item_number": 70}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777971', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777571', '77777777-7777-7777-7777-777777777724', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 70, '{"source": "YSQ-Esquemas", "item_number": 71}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777972', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777572', '77777777-7777-7777-7777-777777777724', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 71, '{"source": "YSQ-Esquemas", "item_number": 72}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777973', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777573', '77777777-7777-7777-7777-777777777724', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 72, '{"source": "YSQ-Esquemas", "item_number": 73}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777974', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777574', '77777777-7777-7777-7777-777777777724', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 73, '{"source": "YSQ-Esquemas", "item_number": 74}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777975', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777575', '77777777-7777-7777-7777-777777777724', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 74, '{"source": "YSQ-Esquemas", "item_number": 75}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777976', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777576', '77777777-7777-7777-7777-777777777725', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 75, '{"source": "YSQ-Esquemas", "item_number": 76}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777977', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777577', '77777777-7777-7777-7777-777777777725', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 76, '{"source": "YSQ-Esquemas", "item_number": 77}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777978', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777578', '77777777-7777-7777-7777-777777777725', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 77, '{"source": "YSQ-Esquemas", "item_number": 78}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777979', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777579', '77777777-7777-7777-7777-777777777725', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 78, '{"source": "YSQ-Esquemas", "item_number": 79}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777980', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777580', '77777777-7777-7777-7777-777777777725', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 79, '{"source": "YSQ-Esquemas", "item_number": 80}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777981', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777581', '77777777-7777-7777-7777-777777777726', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 80, '{"source": "YSQ-Esquemas", "item_number": 81}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777982', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777582', '77777777-7777-7777-7777-777777777726', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 81, '{"source": "YSQ-Esquemas", "item_number": 82}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777983', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777583', '77777777-7777-7777-7777-777777777726', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 82, '{"source": "YSQ-Esquemas", "item_number": 83}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777984', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777584', '77777777-7777-7777-7777-777777777726', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 83, '{"source": "YSQ-Esquemas", "item_number": 84}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777985', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777585', '77777777-7777-7777-7777-777777777726', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 84, '{"source": "YSQ-Esquemas", "item_number": 85}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777986', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777586', '77777777-7777-7777-7777-777777777727', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 85, '{"source": "YSQ-Esquemas", "item_number": 86}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777987', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777587', '77777777-7777-7777-7777-777777777727', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 86, '{"source": "YSQ-Esquemas", "item_number": 87}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777988', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777588', '77777777-7777-7777-7777-777777777727', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 87, '{"source": "YSQ-Esquemas", "item_number": 88}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777989', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777589', '77777777-7777-7777-7777-777777777727', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 88, '{"source": "YSQ-Esquemas", "item_number": 89}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.question_scoring_rules (
  id, questionnaire_version_id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-777777777990', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777590', '77777777-7777-7777-7777-777777777727', '77777777-7777-7777-7777-777777777605',
  1, false, 1, 6, 89, '{"source": "YSQ-Esquemas", "item_number": 90}'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- Faixas de severidade (planilha: 1,0–2,4 Baixo; 2,5–3,9 Médio; 4,0–5,0 Ativado) — por esquema
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770101', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777710', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770102', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777710', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770103', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777710', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770201', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777711', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770202', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777711', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770203', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777711', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770301', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777712', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770302', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777712', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770303', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777712', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770401', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777713', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770402', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777713', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770403', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777713', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770501', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777714', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770502', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777714', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770503', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777714', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770601', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777715', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770602', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777715', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770603', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777715', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770701', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777716', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770702', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777716', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770703', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777716', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770801', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777717', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770802', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777717', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770803', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777717', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770901', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777718', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770902', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777718', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777770903', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777718', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771001', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777719', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771002', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777719', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771003', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777719', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771101', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777720', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771102', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777720', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771103', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777720', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771201', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777721', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771202', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777721', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771203', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777721', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771301', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777722', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771302', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777722', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771303', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777722', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771401', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777723', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771402', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777723', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771403', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777723', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771501', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777724', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771502', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777724', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771503', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777724', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771601', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777725', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771602', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777725', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771603', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777725', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771701', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777726', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771702', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777726', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771703', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777726', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771801', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777727', NULL,
  'Baixo', 1.0, 2.4, 'severity_low', 0,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771802', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777727', NULL,
  'Médio', 2.5, 3.9, 'severity_moderate', 1,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
INSERT INTO public.severity_ranges (
  id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order, metadata
) VALUES (
  '77777777-7777-7777-7777-077777771803', '77777777-7777-7777-7777-777777777801', '77777777-7777-7777-7777-777777777727', NULL,
  'Ativado', 4.0, 5.0, 'severity_high', 2,
  '{"source": "YSQ-Esquemas"}'::jsonb
)
ON CONFLICT (id) DO NOTHING;
COMMIT;
