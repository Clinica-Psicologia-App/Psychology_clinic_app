-- Questionários YCI e YRAI modelados no catálogo padrão do app.
-- Fonte: planilha clínica enviada pelo usuário (abas YCI e YRAI).

BEGIN;

INSERT INTO public.questionnaires (id, code, name, description, is_active)
VALUES
  ('82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_FOUNDATION_V1', 'YCI', 'Inventário YCI com escala Likert de 1 a 6 para apoio à formulação de estilos de enfrentamento.', true)
ON CONFLICT (id) DO UPDATE SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active;

INSERT INTO public.questionnaire_versions (
  id, questionnaire_id, version, status, scoring_method, scale_min, scale_max, instructions, published_at, reference_period
)
VALUES
  ('06574dd1-63b7-5a5f-9184-b96c2284a64f', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'v1', 'active', 'legacy_category_average', 1, 6, 'Responda o quanto cada afirmação descreve você usando a escala de 1 a 6.', timezone('utc', now()), 'unspecified')
ON CONFLICT (id) DO UPDATE SET
  questionnaire_id = EXCLUDED.questionnaire_id,
  version = EXCLUDED.version,
  status = EXCLUDED.status,
  scoring_method = EXCLUDED.scoring_method,
  scale_min = EXCLUDED.scale_min,
  scale_max = EXCLUDED.scale_max,
  instructions = EXCLUDED.instructions,
  published_at = EXCLUDED.published_at,
  reference_period = EXCLUDED.reference_period;

INSERT INTO public.question_categories (id, questionnaire_id, code, name, description)
VALUES
  ('4702af8c-6a76-55f3-9168-e59cfa3111ff', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_TOTAL', 'YCI Geral', 'Apuração geral do inventário YCI.')
ON CONFLICT (id) DO UPDATE SET
  questionnaire_id = EXCLUDED.questionnaire_id,
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description;

INSERT INTO public.questions (
  id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active
)
VALUES
  ('e27aebdd-8ff7-5b38-b7a5-490629a0ef78', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_001', 'Descarrego minhas frustrações nas pessoas que me rodeiam', 0, 'likert_scale', 1, 6, true),
  ('b52290bf-ff02-502b-9fb7-197677ac60cf', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_002', 'Muitas vezes culpo os outros quando as coisas vão mal', 1, 'likert_scale', 1, 6, true),
  ('f3b4844d-6118-5ad1-94c2-22f9e295d33f', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_003', 'Demonstro estar zangado(a) quando as pessoas me decepcionam ou me traem', 2, 'likert_scale', 1, 6, true),
  ('bb57d87e-f6d6-5225-ad0c-2cdbfe375537', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_004', 'Quando fico ofendido(a), não descanso enquanto não me vingo', 3, 'likert_scale', 1, 6, true),
  ('ca2821d6-f93e-5700-8dd9-00c0be39b512', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_005', 'Quando alguém me critica, fico na defensiva', 4, 'likert_scale', 1, 6, true),
  ('ed19aa00-828f-508b-8488-c54f9d5f3af2', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_006', 'É importante que os outros admirem aquilo que eu faço', 5, 'likert_scale', 1, 6, true),
  ('291c1cba-7a48-580a-958b-0064886535f0', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_007', 'Os sinais visíveis de sucesso (ex., carros, roupas, casa) são importantes para mim', 6, 'likert_scale', 1, 6, true),
  ('7ade4cd1-0db5-53cb-9137-5bf8b6527d59', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_008', 'Trabalho muito para estar entre os melhores ou os mais bem-sucedidos', 7, 'likert_scale', 1, 6, true),
  ('7d353e91-3c59-5639-9fee-ddf4f8c371a4', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_009', 'Para mim é importante ser popular', 8, 'likert_scale', 1, 6, true),
  ('952fe40b-ad46-5d35-b252-d3b61ec6e82f', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_010', 'Muitas vezes tenho fantasias de sucesso, fama, riqueza, poder ou popularidade', 9, 'likert_scale', 1, 6, true),
  ('54d354d8-4b33-537a-9dba-96e1c95abff7', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_011', 'Gosto de ser o centro das atenções', 10, 'likert_scale', 1, 6, true),
  ('2f231d13-556d-5181-a8f8-92e68b103d70', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_012', 'Sou mais sedutor do que a média das pessoas', 11, 'likert_scale', 1, 6, true),
  ('6e7f2a49-5883-5716-8544-20de48f05b1c', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_013', 'Esforço-me muito para ter minha vida em ordem (ex., organização, estrutura, planejamento, rotina)', 12, 'likert_scale', 1, 6, true),
  ('5af08b26-abee-5467-8558-23f450fbee6a', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_014', 'Esforço-me muito para que as coisas não andem mal', 13, 'likert_scale', 1, 6, true),
  ('9a49fd63-7dac-5278-9632-ae18b2d5ff24', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_015', 'Quando tenho que tomar decisões, fico me torturando com medo de errar', 14, 'likert_scale', 1, 6, true),
  ('ccbb6d14-d875-5605-9f62-04e643bf75ed', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_016', 'Sou muito controlador com as pessoas que me rodeiam', 15, 'likert_scale', 1, 6, true),
  ('114a6b7a-0b38-55d9-ad65-9d592be22033', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_017', 'Gosto de estar em posição de controle ou autoridade sobre as pessoas que me rodeiam', 16, 'likert_scale', 1, 6, true),
  ('6ce982d5-c856-509f-a39f-c95fa8943171', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_018', 'Não gosto que me digam o que fazer', 17, 'likert_scale', 1, 6, true),
  ('ac086410-4e9a-584f-9c96-a47c442bd2b9', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_019', 'Para mim, é muito difícil aceitar soluções de compromisso ou ceder', 18, 'likert_scale', 1, 6, true),
  ('3cb96648-b5c5-5f2d-935f-f84882cc1df0', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_020', 'Não gosto de depender de ninguém', 19, 'likert_scale', 1, 6, true),
  ('d61b5b57-d3c4-5d02-bc97-9e6ceb5ea49a', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_021', 'Para mim, é crucial tomar minhas próprias decisões e ser independente', 20, 'likert_scale', 1, 6, true),
  ('bd30ae4a-3d04-5c5b-80e4-c083671b9d71', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_022', 'Tenho dificuldade de me "assentar" ou de assumir compromisso com uma única pessoa', 21, 'likert_scale', 1, 6, true),
  ('28ff4c84-0cf2-5d28-8209-722c6bc4f41b', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_023', 'Gosto de trabalhar por conta própria, para ter liberdade de fazer "o que eu quiser"', 22, 'likert_scale', 1, 6, true),
  ('fb50cf02-80b7-521f-a893-3a49057cf70d', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_024', 'Não gosto de me sentir preso(a) a um único emprego ou carreira, gosto de manter as minhas opções em aberto', 23, 'likert_scale', 1, 6, true),
  ('8bbbe2a9-ce37-511f-bc85-2b6f41cfa415', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_025', 'Habitualmente coloco minhas necessidades à frente dos outros', 24, 'likert_scale', 1, 6, true),
  ('8e0b4f66-b1e0-57ef-a064-ffa30f53d7d3', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_026', 'Sou muitas vezes exigente com os outros porque gosto de tudo "muito certinho"', 25, 'likert_scale', 1, 6, true),
  ('94531333-bfbf-5a69-b36a-1ce7053cc043', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_027', 'Tenho que fazer como os outros e pensar primeiro em mim', 26, 'likert_scale', 1, 6, true),
  ('c26c8173-6f08-5f68-ad21-efe655161e9d', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_028', 'Para mim, é muito importante que o meu ambiente seja confortável (ex., temperatura, luz, mobília)', 27, 'likert_scale', 1, 6, true),
  ('eae28682-4bd5-5f51-93d3-13d8857ef4eb', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_029', 'Considero-me uma pessoa rebelde, revoltada; muitas vezes vou contra a autoridade estabelecida', 28, 'likert_scale', 1, 6, true),
  ('ca832847-17f1-5bc5-bcc1-333531d49937', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_030', 'Não gosto de regras e me dá satisfação quebrá-las', 29, 'likert_scale', 1, 6, true),
  ('67a317b9-7956-5c6d-8ae9-7820cf5a2a7d', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_031', 'Gosto de não ser convencional, mesmo que isso seja pouco popular ou que faça com que seja colocado de lado', 30, 'likert_scale', 1, 6, true),
  ('bc9367f8-8a5a-5614-8736-564d6cd60204', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_032', 'Não procuro ter sucesso de acordo com as normas sociais (ex., riqueza, realização, popularidade)', 31, 'likert_scale', 1, 6, true),
  ('031dc923-08a6-5c84-8034-9a6857558a98', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_033', 'Sempre me destaquei por ser diferente; nunca fui atrás dos outros', 32, 'likert_scale', 1, 6, true),
  ('b7302d7f-cfa8-5dd8-a2d3-19d80f75f4cd', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_034', 'Sou uma pessoa muito reservada; não gosto que as pessoas saibam muito sobre a minha vida particular ou meus sentimentos', 33, 'likert_scale', 1, 6, true),
  ('7b7870ac-1e5b-541f-94a5-2f5e987bc9d1', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_035', 'Tento sempre parecer forte, mesmo quando me sinto vulnerável ou inseguro(a)', 34, 'likert_scale', 1, 6, true),
  ('c8108039-7e65-5c1d-8ae5-69f55488b741', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_036', 'às vezes sou muito possessivo(a) ou apegado(a) às pessoas que estimo', 35, 'likert_scale', 1, 6, true),
  ('c763a022-7563-5bf0-9d1b-40e81be0c096', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_037', 'Frequentemente sou manipulador(a) para conseguir os meus objetivos', 36, 'likert_scale', 1, 6, true),
  ('cb364d63-8bbd-5daf-b3ee-7ddfc188da75', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_038', 'Muitas vezes prefiro formas indiretas de obter o que quero, em vez de pedir diretamente', 37, 'likert_scale', 1, 6, true),
  ('03745a11-4c5d-56b0-b9bd-ee9b9af1735e', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_039', 'mantenho os outros à distância e só deixo que saibam de mim o que eu quero', 38, 'likert_scale', 1, 6, true),
  ('30c36dd9-8fd9-54eb-a719-e25635a4dc5b', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_040', 'Sou uma pessoa extremamente crítica', 39, 'likert_scale', 1, 6, true),
  ('a57e34d5-6352-54a4-8c7d-97f943ec72ff', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_041', 'Sinto uma grande pressão para atingir os padrões ou responsabilidades que imponho a mim mesmo', 40, 'likert_scale', 1, 6, true),
  ('d319252a-70f5-5683-833d-d21bead8bd32', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_042', 'Muitas vezes não tenho tato ou sensibilidade para me expressar', 41, 'likert_scale', 1, 6, true),
  ('f516a39e-677f-5227-95a0-89402d2c6a73', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_043', 'Tento ser sempre otimista; não me deixo abater', 42, 'likert_scale', 1, 6, true),
  ('8ec72dbe-30ac-58ab-8d46-b4a502cd3be6', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_044', 'Acredito que é importante mostrar "uma cara feliz" independentemente do que estou sentindo por dentro', 43, 'likert_scale', 1, 6, true),
  ('61b42b2c-318d-59d9-8b98-a3c017025654', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_045', 'Muitas vezes sinto inveja ou frustração quando os outros têm mais sucesso ou obtém mais atenção do que eu', 44, 'likert_scale', 1, 6, true),
  ('95f8d479-1940-515d-9de7-a1474bb7717e', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_046', 'Esforço-me para ter certeza de que estou recebendo o que me é devido e que não estou sendo enganado(a)', 45, 'likert_scale', 1, 6, true),
  ('3d02e034-955f-53db-a42a-2b33d8c21a7f', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_047', 'Procuro ser mais esperto do que os outros para que não se aproveitem de mim ou não me magoem', 46, 'likert_scale', 1, 6, true),
  ('6196203d-4853-5d6e-9f8b-6f2bfd5557f6', '82d52b66-30d1-581c-8d17-0265d4b754a4', 'YCI_048', 'Sei exatamente o que devo dizer ou fazer para que os outros gostem de mim (ex., elogiar, dizer o que eles querem ouvir)', 47, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  questionnaire_id = EXCLUDED.questionnaire_id,
  code = EXCLUDED.code,
  text = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  answer_type = EXCLUDED.answer_type,
  scale_min = EXCLUDED.scale_min,
  scale_max = EXCLUDED.scale_max,
  is_active = EXCLUDED.is_active;

INSERT INTO public.question_category_items (id, question_id, category_id, weight)
VALUES
  ('ee39aec4-f53d-5159-869a-21343f7b1406', 'e27aebdd-8ff7-5b38-b7a5-490629a0ef78', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('2eb6c98b-21bb-51c2-a909-916dd81cc6de', 'b52290bf-ff02-502b-9fb7-197677ac60cf', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('43208cd2-4cc1-5889-a2ca-45f2a1aa82f9', 'f3b4844d-6118-5ad1-94c2-22f9e295d33f', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('794f0916-6435-5456-b12f-faf956ead073', 'bb57d87e-f6d6-5225-ad0c-2cdbfe375537', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('3cc0a88c-fd7c-5ebc-8a7f-4e6dbfe6a14d', 'ca2821d6-f93e-5700-8dd9-00c0be39b512', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('926f6bee-ca33-512d-8e35-f0a574882f06', 'ed19aa00-828f-508b-8488-c54f9d5f3af2', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('e621d45f-5622-53f9-8e72-717930f86097', '291c1cba-7a48-580a-958b-0064886535f0', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('692fea30-14e8-5347-b1c3-8497a070dc44', '7ade4cd1-0db5-53cb-9137-5bf8b6527d59', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('4fa62b91-1984-5cf1-99b2-92aa5219cb57', '7d353e91-3c59-5639-9fee-ddf4f8c371a4', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('a935dc57-fcc5-5951-89ba-a31727fbff37', '952fe40b-ad46-5d35-b252-d3b61ec6e82f', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('62b81df9-9d07-523f-8b59-5e7b8411c7ef', '54d354d8-4b33-537a-9dba-96e1c95abff7', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('1b36a1f2-ce44-52be-8103-7c24dfe30d60', '2f231d13-556d-5181-a8f8-92e68b103d70', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('8d90a3ec-bed1-5e00-a1f0-33bc494ab226', '6e7f2a49-5883-5716-8544-20de48f05b1c', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('6ccbd7f6-fe02-557b-94d6-ee20da8bd51c', '5af08b26-abee-5467-8558-23f450fbee6a', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('238c5088-79f6-5d2b-a9ec-47f0373a1a4a', '9a49fd63-7dac-5278-9632-ae18b2d5ff24', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('cfff5b31-dfc9-5288-904c-1481cccf0a63', 'ccbb6d14-d875-5605-9f62-04e643bf75ed', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('66c87304-42ac-5555-be34-b0f43e05b0a1', '114a6b7a-0b38-55d9-ad65-9d592be22033', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('3f15ceea-c4af-526c-b160-10f36a44c06b', '6ce982d5-c856-509f-a39f-c95fa8943171', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('6444c01c-7c6a-51d5-8103-1fdb3794ab92', 'ac086410-4e9a-584f-9c96-a47c442bd2b9', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('1cd4b84a-1a6b-5283-9de6-4f873ec57180', '3cb96648-b5c5-5f2d-935f-f84882cc1df0', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('4dc0ac30-e88d-5591-a225-0376e2139190', 'd61b5b57-d3c4-5d02-bc97-9e6ceb5ea49a', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('6563eed3-3d53-5fec-a123-ab1cebd68c4c', 'bd30ae4a-3d04-5c5b-80e4-c083671b9d71', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('aa2b3377-0cd2-567c-b0fe-53764585d222', '28ff4c84-0cf2-5d28-8209-722c6bc4f41b', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('54f2dae4-1c7e-5f77-a3ae-47fb74f9563e', 'fb50cf02-80b7-521f-a893-3a49057cf70d', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('8fd2108d-178b-5b51-8f8f-3981f12bee42', '8bbbe2a9-ce37-511f-bc85-2b6f41cfa415', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('3eb3f416-1bca-58b5-9ff5-e0641d15eecb', '8e0b4f66-b1e0-57ef-a064-ffa30f53d7d3', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('f970399d-6fe7-5fd0-8f08-fb3d635615c0', '94531333-bfbf-5a69-b36a-1ce7053cc043', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('cb74cee5-dbb6-577b-b619-05fbba2200ca', 'c26c8173-6f08-5f68-ad21-efe655161e9d', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('b262a871-5d63-5a19-84b6-b372bbb8cb34', 'eae28682-4bd5-5f51-93d3-13d8857ef4eb', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('5da69ed4-f439-5513-89ab-b5e77060a5e6', 'ca832847-17f1-5bc5-bcc1-333531d49937', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('c6a104a8-62c7-5b43-bc7c-47a3bb229451', '67a317b9-7956-5c6d-8ae9-7820cf5a2a7d', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('a334229b-e796-503d-9d82-49e20334a758', 'bc9367f8-8a5a-5614-8736-564d6cd60204', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('dcf45d98-1433-5c2d-8c5f-7b2d07faeb86', '031dc923-08a6-5c84-8034-9a6857558a98', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('cb077f11-7d6a-5bb8-90b1-88786ecdbee7', 'b7302d7f-cfa8-5dd8-a2d3-19d80f75f4cd', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('9fa40a19-7a0a-509a-9abd-274fd031eb83', '7b7870ac-1e5b-541f-94a5-2f5e987bc9d1', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('933d59c6-1955-53a1-89ec-a16107a9ebb0', 'c8108039-7e65-5c1d-8ae5-69f55488b741', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('16971055-c2ef-52b0-a3e4-352d041be27b', 'c763a022-7563-5bf0-9d1b-40e81be0c096', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('e3a24064-15ae-55db-aded-d14973031bdf', 'cb364d63-8bbd-5daf-b3ee-7ddfc188da75', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('5fc7f36d-6bdf-58f9-861e-6eb24a43d22f', '03745a11-4c5d-56b0-b9bd-ee9b9af1735e', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('c9f31f56-aa2e-507a-94fb-1c8d6cc502ad', '30c36dd9-8fd9-54eb-a719-e25635a4dc5b', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('218e11c7-3243-5ed6-b1fe-210bce187cc7', 'a57e34d5-6352-54a4-8c7d-97f943ec72ff', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('1a743ccd-7932-5913-9ee3-216cbd1cb1c5', 'd319252a-70f5-5683-833d-d21bead8bd32', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('441882ae-9b77-5136-b0ac-a7070c8be79e', 'f516a39e-677f-5227-95a0-89402d2c6a73', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('cb15fbae-1a6e-597d-9899-9e644b915f48', '8ec72dbe-30ac-58ab-8d46-b4a502cd3be6', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('cb5461b9-1fc4-5509-8fcb-050e7717154d', '61b42b2c-318d-59d9-8b98-a3c017025654', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('9d74bc45-48c7-5378-a113-d7a4a92de3ed', '95f8d479-1940-515d-9de7-a1474bb7717e', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('a74303b0-a181-5d7b-bc58-93be1d634fd9', '3d02e034-955f-53db-a42a-2b33d8c21a7f', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1),
  ('26893de3-a682-513a-89ac-7c09fc2d89c9', '6196203d-4853-5d6e-9f8b-6f2bfd5557f6', '4702af8c-6a76-55f3-9168-e59cfa3111ff', 1)
ON CONFLICT (id) DO UPDATE SET
  question_id = EXCLUDED.question_id,
  category_id = EXCLUDED.category_id,
  weight = EXCLUDED.weight;

INSERT INTO public.questionnaires (id, code, name, description, is_active)
VALUES
  ('24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_FOUNDATION_V1', 'YRAI', 'Inventário YRAI com escala Likert de 1 a 6 para apoio à formulação de estilos de enfrentamento.', true)
ON CONFLICT (id) DO UPDATE SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active;

INSERT INTO public.questionnaire_versions (
  id, questionnaire_id, version, status, scoring_method, scale_min, scale_max, instructions, published_at, reference_period
)
VALUES
  ('8cab086f-0eb5-5c79-b4f3-23e5831d9289', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'v1', 'active', 'legacy_category_average', 1, 6, 'Responda o quanto cada afirmação descreve você usando a escala de 1 a 6.', timezone('utc', now()), 'unspecified')
ON CONFLICT (id) DO UPDATE SET
  questionnaire_id = EXCLUDED.questionnaire_id,
  version = EXCLUDED.version,
  status = EXCLUDED.status,
  scoring_method = EXCLUDED.scoring_method,
  scale_min = EXCLUDED.scale_min,
  scale_max = EXCLUDED.scale_max,
  instructions = EXCLUDED.instructions,
  published_at = EXCLUDED.published_at,
  reference_period = EXCLUDED.reference_period;

INSERT INTO public.question_categories (id, questionnaire_id, code, name, description)
VALUES
  ('793ae8d6-a667-5b6d-b529-f3327c7d346d', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_TOTAL', 'YRAI Geral', 'Apuração geral do inventário YRAI.')
ON CONFLICT (id) DO UPDATE SET
  questionnaire_id = EXCLUDED.questionnaire_id,
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description;

INSERT INTO public.questions (
  id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active
)
VALUES
  ('1230465f-8a5e-58f5-b47d-0cb830d25f80', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_001', 'Tento não pensar em coisas que me perturbam', 0, 'likert_scale', 1, 6, true),
  ('bcccbd82-10fa-5ab9-8e38-e8eabadf3a62', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_002', 'Tomo bebidas alcoólicas para me acalmar', 1, 'likert_scale', 1, 6, true),
  ('71a666be-54ab-58ab-98fc-45381e31cae7', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_003', 'Sinto-me feliz a maior parte do tempo', 2, 'likert_scale', 1, 6, true),
  ('8e69b3c3-5d5b-5393-b0ee-20aeddc99788', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_004', 'Raramente me sinto triste ou de mau humor', 3, 'likert_scale', 1, 6, true),
  ('e64351e5-4474-508c-b0d3-5070c7a0c555', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_005', 'Valorizo mais a razão do que a emoção (me guio mais pela cabeça do que pelo coração)', 4, 'likert_scale', 1, 6, true),
  ('42398b57-2e6d-5262-8c84-46c7af651b84', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_006', 'Acredito que não devo ficar bravo(a), mesmo com pessoas de quem não gosto', 5, 'likert_scale', 1, 6, true),
  ('6fa0a8cf-a49d-557b-a60c-f6414b78b594', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_007', 'Uso drogas para me sentir melhor', 6, 'likert_scale', 1, 6, true),
  ('9389df28-5802-5ca6-9e36-1bae56624aea', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_008', 'Não sinto grande coisa quando lembro da minha infância', 7, 'likert_scale', 1, 6, true),
  ('4b5a564c-47a8-531b-b91f-f4d1b28777c1', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_009', 'Fumo quando estou aborrecido', 8, 'likert_scale', 1, 6, true),
  ('ee6dc01a-1881-531f-9225-e66af3938b2a', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_010', 'Sofro de problemas gastrointestinais (ex., indigestão, úlcera, colite, gastrite, etc.)', 9, 'likert_scale', 1, 6, true),
  ('06054edd-dc94-5d41-94c8-9da1c4eb3553', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_011', 'Sinto-me entorpecido(a)', 10, 'likert_scale', 1, 6, true),
  ('54cd267b-bdcf-5cd6-8e44-aab23d6af81a', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_012', 'Tenho muitas vezes dores de cabeça', 11, 'likert_scale', 1, 6, true),
  ('24509057-ab3a-5921-ab7c-af43f1ac1486', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_013', 'Isolo-me quando estou zangado(a)', 12, 'likert_scale', 1, 6, true),
  ('dabc17c1-65ac-5739-be85-14d71715ffd9', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_014', 'Não tenho tanta energia quanto a maioria das pessoas na minha idade', 13, 'likert_scale', 1, 6, true),
  ('41be567b-9f7d-554f-8a1c-5fd6f58012f7', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_015', 'Sofro de dores musculares', 14, 'likert_scale', 1, 6, true),
  ('add6e0f1-54d3-5d12-b111-60f1b9b7721c', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_016', 'Vejo muita TV quando estou sozinho(a)', 15, 'likert_scale', 1, 6, true),
  ('1a40db66-5fc1-5130-a301-0bb638f05bc5', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_017', 'Acredito que se deve usar a cabeça para controlar as emoções', 16, 'likert_scale', 1, 6, true),
  ('c86231c8-c360-52c4-ba5f-05d79d7f9f99', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_018', 'Não consigo antipatizar fortemente com ninguém', 17, 'likert_scale', 1, 6, true),
  ('c1ee5a36-2664-504e-ae56-f8046c1d07a3', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_019', 'A minha filosofia quando alguma coisa vai mal é deixar para lá e seguir em frente', 18, 'likert_scale', 1, 6, true),
  ('b2044797-b8a5-58fd-a77c-78d83da86812', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_020', 'Afasto-me das pessoas quando me sinto magoado(a)', 19, 'likert_scale', 1, 6, true),
  ('8c1d3766-7fcc-515d-93ff-b76dc8e328e7', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_021', 'Não me lembro de grande coisa sobre a minha infância', 20, 'likert_scale', 1, 6, true),
  ('7fb22c81-ce6a-5b46-929b-45381b13545f', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_022', 'Faço sestas e durmo bastante durante o dia', 21, 'likert_scale', 1, 6, true),
  ('5887825f-bf64-543f-8e02-45ad25a226c5', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_023', 'Sinto-me melhor quando ando de um lado para o outro; não gosto de ficar muito tempo parado(a)', 22, 'likert_scale', 1, 6, true),
  ('339cd5c2-6bce-56f2-afbf-cd3f1d36daac', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_024', 'Procuro estar sempre ocupado(a) para não me sentir aborrecido(a)', 23, 'likert_scale', 1, 6, true),
  ('bfec1d2e-e5d2-5ead-8b41-a4a101f183d1', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_025', 'Passo a maior parte do tempo sonhando acordado(a)', 24, 'likert_scale', 1, 6, true),
  ('1cf6bc70-0bbe-5d6e-943e-28d75df8d17f', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_026', 'Quando estou aborrecido(a), como para me sentir melhor', 25, 'likert_scale', 1, 6, true),
  ('c9f5273a-1d49-5d65-84c1-85c2f5afe0d2', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_027', 'Tento não pensar em lembranças dolorosas do meu passado', 26, 'likert_scale', 1, 6, true),
  ('312664b0-6b44-561d-8667-b7783284e582', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_028', 'Sinto-me melhor se me mantiver constantemente ocupado(a), sem ter muito tempo para pensar', 27, 'likert_scale', 1, 6, true),
  ('3dc84e89-7833-5afb-b3ba-0f05949ef599', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_029', 'Tive uma infância muito feliz', 28, 'likert_scale', 1, 6, true),
  ('1861fc45-4919-5f57-8cf8-7347b0647661', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_030', 'Isolo-me quando estou triste', 29, 'likert_scale', 1, 6, true),
  ('41572bd4-a157-5a45-a31b-797abdf01543', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_031', 'As pessoas dizem que me pareço uma avestruz com a cabeça debaixo da terra (em outras palavras, tento não pensar em coisas que me desagradam)', 30, 'likert_scale', 1, 6, true),
  ('38607ac6-53df-506b-b5f7-b8d4af825f41', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_032', 'Tenho a tendência de não pensar em minhas perdas ou decepções', 31, 'likert_scale', 1, 6, true),
  ('d4528709-f286-5556-953b-fe02d0102e72', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_033', 'Mesmo quando a situação parece justificar emoções fortes, muitas vezes não sinto nada', 32, 'likert_scale', 1, 6, true),
  ('ca8ba792-6139-54cc-a706-130108652b5c', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_034', 'Sou uma pessoa de sorte por ter tido pais tão bons', 33, 'likert_scale', 1, 6, true),
  ('d24917a2-9f48-56a9-9210-e64a2c9301f9', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_035', 'A maior parte do tempo, procuro viver a minha vida sem grandes emoções', 34, 'likert_scale', 1, 6, true),
  ('4947f0d8-0053-5d03-842d-267f921aa81f', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_036', 'Muitas vezes compro coisas que não preciso para me sentir mais animado(a)', 35, 'likert_scale', 1, 6, true),
  ('bb94975a-348a-5118-b49a-202eafe3a9c7', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_037', 'Tento não me meter em situações difíceis ou que me façam sentir desconfortável', 36, 'likert_scale', 1, 6, true),
  ('1c42a02a-e2aa-5e21-a10b-a3c06a029bcb', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_038', 'Sinto-me fisicamente doente quando as coisas não vão bem', 37, 'likert_scale', 1, 6, true),
  ('2f245e2c-c611-54e6-b0de-c58d458f58b5', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_039', 'Quando as pessoas me abandonam ou morrem, não me perturbo muito', 38, 'likert_scale', 1, 6, true),
  ('126d1b2b-3bab-53ea-8abd-1bb8c5a445bc', '24ca2f90-40b6-5f74-b7f7-7de4321588fe', 'YRAI_040', 'Não me preocupo com o que os outros pensam de mim', 39, 'likert_scale', 1, 6, true)
ON CONFLICT (id) DO UPDATE SET
  questionnaire_id = EXCLUDED.questionnaire_id,
  code = EXCLUDED.code,
  text = EXCLUDED.text,
  order_index = EXCLUDED.order_index,
  answer_type = EXCLUDED.answer_type,
  scale_min = EXCLUDED.scale_min,
  scale_max = EXCLUDED.scale_max,
  is_active = EXCLUDED.is_active;

INSERT INTO public.question_category_items (id, question_id, category_id, weight)
VALUES
  ('c4762335-97fd-5198-b296-54c19a2da096', '1230465f-8a5e-58f5-b47d-0cb830d25f80', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('863944c6-0b30-5f48-b313-cc14cc4045d4', 'bcccbd82-10fa-5ab9-8e38-e8eabadf3a62', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('dadad665-7b85-514d-a902-16b55d64b831', '71a666be-54ab-58ab-98fc-45381e31cae7', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('f209615f-99a4-5b15-85bb-e9c514e850ed', '8e69b3c3-5d5b-5393-b0ee-20aeddc99788', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('2915677c-9fe7-570e-ad5e-e1459188dec1', 'e64351e5-4474-508c-b0d3-5070c7a0c555', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('bc7437f7-9aaf-5d5b-a371-00e6fc9bfd17', '42398b57-2e6d-5262-8c84-46c7af651b84', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('101ad095-c96e-5c03-bf69-94522a12747c', '6fa0a8cf-a49d-557b-a60c-f6414b78b594', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('6f5574f7-2036-5ab3-8330-f1b18ac32aed', '9389df28-5802-5ca6-9e36-1bae56624aea', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('08d2ddb3-ac1f-57a7-a2da-b616fc691ff2', '4b5a564c-47a8-531b-b91f-f4d1b28777c1', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('6332b0de-4b65-5727-a042-1849d5906a7f', 'ee6dc01a-1881-531f-9225-e66af3938b2a', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('e81786c5-67e7-51ae-8d7f-8a17a70a35a8', '06054edd-dc94-5d41-94c8-9da1c4eb3553', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('cb8cc554-b78d-5907-b952-d51d8846d356', '54cd267b-bdcf-5cd6-8e44-aab23d6af81a', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('f556843f-e7d7-5a1a-9dc3-9d50e5383fbe', '24509057-ab3a-5921-ab7c-af43f1ac1486', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('0de41048-b895-589c-be1b-25252f70c3a7', 'dabc17c1-65ac-5739-be85-14d71715ffd9', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('1e0375f5-8042-5727-b5ba-067aa8149d1c', '41be567b-9f7d-554f-8a1c-5fd6f58012f7', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('02e1a50b-785b-5144-b2d6-8d5282deb4aa', 'add6e0f1-54d3-5d12-b111-60f1b9b7721c', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('4c1fab76-00de-5994-bed1-0891783752f1', '1a40db66-5fc1-5130-a301-0bb638f05bc5', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('3472e818-af6d-5a6b-b46f-c7e2ccefb708', 'c86231c8-c360-52c4-ba5f-05d79d7f9f99', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('70ce0c00-e530-5232-a607-9b3defd46930', 'c1ee5a36-2664-504e-ae56-f8046c1d07a3', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('b7168cf2-9c28-5cd2-b2a2-9e0f55cbe42e', 'b2044797-b8a5-58fd-a77c-78d83da86812', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('6e2b7097-7f9d-54a0-bdb3-6b57b1e49c92', '8c1d3766-7fcc-515d-93ff-b76dc8e328e7', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('4808c941-94bf-5b92-9dea-a439ae1e8081', '7fb22c81-ce6a-5b46-929b-45381b13545f', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('803a2afc-a584-5ed0-9bd1-dac486e1b0a4', '5887825f-bf64-543f-8e02-45ad25a226c5', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('905fb0e1-8c12-54b0-86a6-511150fdd57c', '339cd5c2-6bce-56f2-afbf-cd3f1d36daac', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('6809f535-f375-57a0-8a77-d61547753c6c', 'bfec1d2e-e5d2-5ead-8b41-a4a101f183d1', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('0dfd11b8-4903-5626-94a0-33b0f07c79c2', '1cf6bc70-0bbe-5d6e-943e-28d75df8d17f', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('e6b9240f-11bc-5414-bf74-ff745aeec954', 'c9f5273a-1d49-5d65-84c1-85c2f5afe0d2', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('acb0774e-f465-5747-9260-48de13a480d1', '312664b0-6b44-561d-8667-b7783284e582', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('8459297d-81aa-5346-9006-de7f263d9a29', '3dc84e89-7833-5afb-b3ba-0f05949ef599', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('65cbfb1c-8b7e-573b-a1ad-f9262d8a6611', '1861fc45-4919-5f57-8cf8-7347b0647661', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('69bc9a1a-736d-5176-ac3b-9b9c1f1ec9ef', '41572bd4-a157-5a45-a31b-797abdf01543', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('8dbc967a-5536-5ca7-902d-15c4dddefbd3', '38607ac6-53df-506b-b5f7-b8d4af825f41', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('fe549a40-b4a9-5f7e-863f-a80b81245fba', 'd4528709-f286-5556-953b-fe02d0102e72', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('6d891096-a6f5-556d-af09-d0e57aceadf5', 'ca8ba792-6139-54cc-a706-130108652b5c', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('892c5bff-32e7-5315-a75c-34c6d5f3ed60', 'd24917a2-9f48-56a9-9210-e64a2c9301f9', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('fd0346cb-bfa1-5a26-be66-5589c8c30367', '4947f0d8-0053-5d03-842d-267f921aa81f', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('1243e470-08c2-5ec9-adbc-082d50550166', 'bb94975a-348a-5118-b49a-202eafe3a9c7', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('872c12e8-3e84-5053-a43a-2b9f46aefd12', '1c42a02a-e2aa-5e21-a10b-a3c06a029bcb', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('fc3d989a-80a0-5d08-a208-97c70e51aeac', '2f245e2c-c611-54e6-b0de-c58d458f58b5', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1),
  ('c481a33a-4111-5dcc-aac9-9c54fa7abf60', '126d1b2b-3bab-53ea-8abd-1bb8c5a445bc', '793ae8d6-a667-5b6d-b529-f3327c7d346d', 1)
ON CONFLICT (id) DO UPDATE SET
  question_id = EXCLUDED.question_id,
  category_id = EXCLUDED.category_id,
  weight = EXCLUDED.weight;

COMMIT;
