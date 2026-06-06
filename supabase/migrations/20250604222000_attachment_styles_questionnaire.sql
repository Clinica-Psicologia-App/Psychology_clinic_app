-- Questionário Estilos de Apego modelado no catálogo padrão do app.
-- Fonte: planilha de escopo enviada pelo usuário (aba Estilos de Apego).

BEGIN;

INSERT INTO public.questionnaires (id, code, name, description, is_active)
VALUES
  ('b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATTACHMENT_STYLES_V1', 'Estilos de Apego', 'Questionário binário de estilo de apego com apuração por categoria ansioso, seguro e evitante.', true)
ON CONFLICT (id) DO UPDATE SET
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  is_active = EXCLUDED.is_active;

INSERT INTO public.questionnaire_versions (
  id, questionnaire_id, version, status, scoring_method, scale_min, scale_max, instructions, published_at, reference_period
)
VALUES
  ('23796291-f46e-53ed-b6e1-c336c5a6e7ef', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'v1', 'active', 'legacy_category_average', 0, 1, 'Marque Sim quando a afirmação for verdadeira para você e Não quando não corresponder ao seu jeito de se relacionar.', timezone('utc', now()), 'unspecified')
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
  ('9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATTACHMENT_ANXIOUS', 'Ansioso', 'Afirmações associadas ao estilo de apego ansioso.'),
  ('a5b36109-9bfe-5965-91a1-0ef8199f9c50', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATTACHMENT_SECURE', 'Seguro', 'Afirmações associadas ao estilo de apego seguro.'),
  ('7ca73657-8ae2-5910-9eeb-06a7398e7a34', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATTACHMENT_AVOIDANT', 'Evitante', 'Afirmações associadas ao estilo de apego evitante.')
ON CONFLICT (id) DO UPDATE SET
  questionnaire_id = EXCLUDED.questionnaire_id,
  code = EXCLUDED.code,
  name = EXCLUDED.name,
  description = EXCLUDED.description;

INSERT INTO public.questions (
  id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active
)
VALUES
  ('e951054b-f1af-5f4b-92ff-5f04661e7247', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_001', 'Com frequência me preocupo se meu parceiro vai me deixar.', 0, 'single_choice', 0, 1, true),
  ('bef868b2-b769-5434-9a3e-8ebed1343e04', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_002', 'Acho fácil ser afetuoso com meu parceiro', 1, 'single_choice', 0, 1, true),
  ('05d7552f-edfe-5244-8d20-c50e1c6f2cfc', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_003', 'Tenho medo de que, se uma pessoa conhecer o meu eu verdadeiro, não goste de quem sou.', 2, 'single_choice', 0, 1, true),
  ('f3d8211c-5324-5cd5-8111-a7c6756c3018', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_004', 'Percebi que me recupero facilmente de um rompimento. É esquisito como eu simplesmente tiro alguém da minha cabeça.', 3, 'single_choice', 0, 1, true),
  ('c95b1564-4097-5c06-9c73-406b878a6d8d', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_005', 'Quando estou envolvido em um relacionamento, sinto-me um pouco ansioso e incompleto.', 4, 'single_choice', 0, 1, true),
  ('a04a7a92-acb3-5761-88b5-4037da45b939', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_006', 'Acho difícil apoiar emocionalmente meu parceiro quando ele está se sentindo triste.', 5, 'single_choice', 0, 1, true),
  ('58736cff-e404-54bb-ba52-81695d4b18fc', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_007', 'Quando o meu parceiro está viajando, tenho medo de que ele possa se interessar por outra pessoa.', 6, 'single_choice', 0, 1, true),
  ('1e4421f2-d1bc-5ee7-bc10-e7c8cbfdccff', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_008', 'Sinto-me a vontade dependendo de parceiros românticos.', 7, 'single_choice', 0, 1, true),
  ('f0053baf-069a-5cbc-a7b2-4d2b97cec155', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_009', 'A minha independência é mais importante para mim do que meus relacionamentos', 8, 'single_choice', 0, 1, true),
  ('f859d532-d5d4-5128-96ee-c97731afab3e', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_010', 'Prefiro não compartilhar meus sentimentos mais íntimos com meu parceiro.', 9, 'single_choice', 0, 1, true),
  ('2a9192e8-f133-5619-8d82-7efb5b1145e7', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_011', 'Quando mostro ao meu parceiro o que estou sentindo, tenho medo de que ele não sinta o mesmo em relação a mim.', 10, 'single_choice', 0, 1, true),
  ('29b0b254-dac9-586f-8f88-79ba38a80991', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_012', 'Em geral, estou satisfeito com os meus relacionamentos românticos.', 11, 'single_choice', 0, 1, true),
  ('9909ed59-1f65-561e-b86c-89f228e8afd9', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_013', 'Não sinto necessidade de me expressar no meu relacionamento.', 12, 'single_choice', 0, 1, true),
  ('90b224a6-901f-58ee-9bdc-4a7d26ced06b', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_014', 'Penso muito sobre meus relacionamentos.', 13, 'single_choice', 0, 1, true),
  ('a7ae60b0-0b14-5752-add9-89c41b27e6cf', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_015', 'Acho difícil depender de parceiros românticos.', 14, 'single_choice', 0, 1, true),
  ('30a5a8ef-346f-553f-a6a8-cc78d061d5a0', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_016', 'Tendo a me apegar rapidamente a parceiros românticos.', 15, 'single_choice', 0, 1, true),
  ('5c3e0707-cd37-541e-b4bf-46158f6898e1', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_017', 'Tenho pouca dificuldade em expressar as minhas necessidades e vontades para o meu parceiro.', 16, 'single_choice', 0, 1, true),
  ('dfbac9f7-f56d-5b53-a7a3-6953c6b54b7a', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_018', 'Às vezes, fico bravo ou aborrecido com meu parceiro sem saber por que.', 17, 'single_choice', 0, 1, true),
  ('683a822b-c958-5c25-af09-7e2ae406b17c', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_019', 'Sou muito sensível aos estados de animo de meu parceiro.', 18, 'single_choice', 0, 1, true),
  ('ec86ad9c-e561-5fa9-a7d2-352037e90f6d', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_020', 'Acredito que a maioria das pessoas é essencialmente honesta e confiável.', 19, 'single_choice', 0, 1, true),
  ('3c207cbe-2b45-5eb1-83a8-4bbae420f0a9', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_021', 'Prefiro sexo casual sem compromisso a sexo intimo com uma pessoa só.', 20, 'single_choice', 0, 1, true),
  ('1e37608e-c41c-5179-b2a3-ce2e794356d4', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_022', 'Sinto-me a vontade para compartilhar meus pensamentos e sentimentos com meu parceiro.', 21, 'single_choice', 0, 1, true),
  ('64f08a59-96f9-598b-b477-0eeeb83ad44c', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_023', 'Preocupo-me que, caso o meu parceiro me abandone, talvez eu nunca consiga encontrar outra pessoa.', 22, 'single_choice', 0, 1, true),
  ('c36d23b5-86c5-56ba-9a0e-38e0a5f5ffb3', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_024', 'Fico nervoso quando meu parceiro fica muito próximo.', 23, 'single_choice', 0, 1, true),
  ('238de6e1-c3ec-5ea7-9ef2-d378775c6ad1', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_025', 'Durante um conflito, tendo a fazer ou dizer, impulsivamente, coisas das quais me arrependo depois, em vez de ser capaz de raciocinar sobre as coisas.', 24, 'single_choice', 0, 1, true),
  ('ca6ccb45-1932-5cb4-a16a-2d2fc92dd8c8', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_026', 'Uma discussão com o meu parceiro geralmente não me faz questionar nosso relacionamento.', 25, 'single_choice', 0, 1, true),
  ('da6cfd52-b0c2-5115-a017-0aa09add731e', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_027', 'Meu parceiro com frequência quer ser mais intimo do que eu me sentiria confortável sendo.', 26, 'single_choice', 0, 1, true),
  ('a81b36d9-ad3a-589a-ace3-49cc84e4a910', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_028', 'Fico preocupado sobre ele não ser atraente o bastante.', 27, 'single_choice', 0, 1, true),
  ('10c9f055-3bce-586d-9e4f-76463cf23da0', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_029', 'Às vezes, as pessoas me acham chato porque crio pequenos dramas nos relacionamentos.', 28, 'single_choice', 0, 1, true),
  ('bde390c7-57bd-5951-ada5-a577a7c4b9cb', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_030', 'Tenho saudade de meu parceiro quando não estamos juntos, mas, aí, quando ficamos juntos, sinto necessidade de escapar.', 29, 'single_choice', 0, 1, true),
  ('ae3567e6-dc78-590f-8a21-472979a94c86', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_031', 'Quando discordo de alguém, eu me sinto a vontade para expressar minhas opiniões.', 30, 'single_choice', 0, 1, true),
  ('f74b9134-b28c-5c45-afcb-da9cae3cad0d', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_032', 'Detesto sentir que as pessoas dependem de mim.', 31, 'single_choice', 0, 1, true),
  ('a9b69b92-9b5d-5134-b835-005b33c1feb1', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_033', 'Se perceber que alguém em quem estou interessado está olhando com atenção para outras pessoas, não deixo que isso me perturbe. Posso sentir um pouco de ciúmes, mas é passageiro.', 32, 'single_choice', 0, 1, true),
  ('94d58ab4-8059-508a-8fa0-c08fcf44a039', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_034', 'Se perceber que alguém em quem estou interessado está olhando com atenção outras pessoas, isso me deixa deprimido.', 33, 'single_choice', 0, 1, true),
  ('5fafb831-18fd-5e54-9c86-ebbc506bd367', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_035', 'Se alguém com quem estou saindo começa a agir com frieza e distância, posso até me perguntar o que aconteceu, mas saberei que provavelmente não tem nada a ver comigo.', 34, 'single_choice', 0, 1, true),
  ('74bfaa5e-01ec-500a-90b7-e5b163745735', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_036', 'Se alguém com quem estou saindo começa a agir com frieza e distância, eu provavelmente ficarei indiferente. Posso até mesmo ficar aliviado.', 35, 'single_choice', 0, 1, true),
  ('8c7164d1-8583-5359-9fa0-29141b3e726b', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_037', 'Se alguém com quem estou saindo começa a agir com frieza e distancia, ficarei preocupado de ter feito alguma coisa errada.', 36, 'single_choice', 0, 1, true),
  ('b6015593-ca22-585d-981d-29efefdc4aca', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_038', 'Se meu parceiro estiver querendo romper comigo, farei o melhor que puder para mostrar a ele o que estará perdendo (um pouco de ciúme não faz mal).', 37, 'single_choice', 0, 1, true),
  ('8a9e3fbf-403d-5858-8cae-37d05c7fdeee', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_039', 'Se alguém com quem saí por vários meses me diz que não quer mais me ver, eu ficare imagoado a principio, mas acabarei superando.', 38, 'single_choice', 0, 1, true),
  ('55af5eb5-1de2-53b8-a453-dfb98e257bc5', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_040', 'Às vezes, quando consigo o que quero em um relacionamento, eu não tenho mais certeza do que quero', 39, 'single_choice', 0, 1, true),
  ('55a74313-5cd5-5e9a-af5c-3e414fac2558', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_041', 'Eu não teria muito problema em manter contato com o meu ex (estritamente platônico) – afinal, temos muito em comum.', 40, 'single_choice', 0, 1, true),
  ('bb8c823c-ccdf-5acc-a5d2-611f1175aa54', 'b3faabc0-c64b-5b9b-b227-5dac19e1be71', 'ATT_042', 'Se percebo que alguém em que estou interessado esta olhando com atenção outras pessoas fico aliviado –significa que ele não está querendo que as coisas fiquem exclusivas.', 41, 'single_choice', 0, 1, true)
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
  ('ef6ddd71-b93d-571a-8527-2d8f8b56c562', 'e951054b-f1af-5f4b-92ff-5f04661e7247', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('05407040-6883-5808-b90a-bf4fabfe120b', 'bef868b2-b769-5434-9a3e-8ebed1343e04', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('570cbd83-917e-5ddd-b7e8-7a62d41c64c7', '05d7552f-edfe-5244-8d20-c50e1c6f2cfc', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('b2acde70-b9cd-5afa-a10e-ddf90870e985', 'f3d8211c-5324-5cd5-8111-a7c6756c3018', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('b9273152-272f-5015-8e5e-2cdc40b02181', 'c95b1564-4097-5c06-9c73-406b878a6d8d', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('6069ee43-5424-5acf-99eb-bcc1c0961e86', 'a04a7a92-acb3-5761-88b5-4037da45b939', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('8a8ce215-5cc7-53aa-ba0f-05a8c9555047', '58736cff-e404-54bb-ba52-81695d4b18fc', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('7af4af6e-1d1d-5833-96ba-0a948435ff19', '1e4421f2-d1bc-5ee7-bc10-e7c8cbfdccff', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('dd565f66-2f44-5bda-af67-f413dba9b15b', 'f0053baf-069a-5cbc-a7b2-4d2b97cec155', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('83fc7fff-6392-5e14-97f0-d105acf9a1af', 'f859d532-d5d4-5128-96ee-c97731afab3e', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('7c72f394-237d-576b-875f-0816d3fb5870', '2a9192e8-f133-5619-8d82-7efb5b1145e7', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('3f2ff7ec-f563-5f88-82b8-f5587855ad21', '29b0b254-dac9-586f-8f88-79ba38a80991', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('8c462391-a881-59b1-b73b-05fc38bb5538', '9909ed59-1f65-561e-b86c-89f228e8afd9', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('eafbd6f6-4e2b-5540-ac39-cc3c3967d774', '90b224a6-901f-58ee-9bdc-4a7d26ced06b', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('a14884cd-b881-5284-95db-42b05c872cf1', 'a7ae60b0-0b14-5752-add9-89c41b27e6cf', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('c0d1f888-8596-5815-8734-604e71eda699', '30a5a8ef-346f-553f-a6a8-cc78d061d5a0', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('044a1b30-9fbb-5871-ab5b-e8adbb175b0d', '5c3e0707-cd37-541e-b4bf-46158f6898e1', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('25af3e90-77e7-51f6-97bb-befe00946acc', 'dfbac9f7-f56d-5b53-a7a3-6953c6b54b7a', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('b6aab318-e29f-5cab-9d2f-0cc092b975d4', '683a822b-c958-5c25-af09-7e2ae406b17c', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('0a8ab28b-cb06-53fd-a903-e2a57ac65d97', 'ec86ad9c-e561-5fa9-a7d2-352037e90f6d', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('88986b87-bde4-5832-9a8b-0dab9e2547b6', '3c207cbe-2b45-5eb1-83a8-4bbae420f0a9', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('531bd16f-6e98-52c0-b554-744752662cc6', '1e37608e-c41c-5179-b2a3-ce2e794356d4', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('463f7d6a-7e80-5a84-9623-9ac7961e7cd7', '64f08a59-96f9-598b-b477-0eeeb83ad44c', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('ad4b3724-c7a0-572f-82ef-95c0ba2ea8e2', 'c36d23b5-86c5-56ba-9a0e-38e0a5f5ffb3', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('22680185-ef08-51a7-93fa-a18edde262cd', '238de6e1-c3ec-5ea7-9ef2-d378775c6ad1', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('8614ec89-8267-5259-95c8-30e28988890d', 'ca6ccb45-1932-5cb4-a16a-2d2fc92dd8c8', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('232dd9dd-ca2e-5364-a089-bb85548d7a69', 'da6cfd52-b0c2-5115-a017-0aa09add731e', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('a990af59-c589-53cb-bd95-e13c84340644', 'a81b36d9-ad3a-589a-ace3-49cc84e4a910', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('2c3034c3-136d-5ac3-8cd2-100a39cd54bb', '10c9f055-3bce-586d-9e4f-76463cf23da0', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('8cc90c31-9af6-5570-89c6-8e538942a41d', 'bde390c7-57bd-5951-ada5-a577a7c4b9cb', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('e9b51881-1e44-56c7-bc57-9e8ab892bbfb', 'ae3567e6-dc78-590f-8a21-472979a94c86', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('494d5019-c32f-5ab0-a689-0ad786a37d2d', 'f74b9134-b28c-5c45-afcb-da9cae3cad0d', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('4e84c82d-477b-5888-a372-de12be261e72', 'a9b69b92-9b5d-5134-b835-005b33c1feb1', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('08a47b25-22a7-501b-a7b9-46ced2c038d4', '94d58ab4-8059-508a-8fa0-c08fcf44a039', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('85551223-e0a5-5ec5-8d20-5fe001c70e13', '5fafb831-18fd-5e54-9c86-ebbc506bd367', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('21344997-63b8-5991-838b-4435e1896ac9', '74bfaa5e-01ec-500a-90b7-e5b163745735', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('2430f251-7c3b-5997-a545-8d19bcb8460c', '8c7164d1-8583-5359-9fa0-29141b3e726b', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('121c451f-ac17-591a-97cb-c732d6ff4060', 'b6015593-ca22-585d-981d-29efefdc4aca', '9ff67fc5-5a77-57b1-a3b4-9f75fd4251fd', 1),
  ('75bbb0e5-03df-516d-916b-f1f04b792939', '8a9e3fbf-403d-5858-8cae-37d05c7fdeee', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('2d44cca5-437d-5859-ae67-c7c52ed30c5c', '55af5eb5-1de2-53b8-a453-dfb98e257bc5', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1),
  ('4abdbc06-c34e-5ae1-9767-caadb5025519', '55a74313-5cd5-5e9a-af5c-3e414fac2558', 'a5b36109-9bfe-5965-91a1-0ef8199f9c50', 1),
  ('cefb5717-74c9-562d-ae16-77a613a215d2', 'bb8c823c-ccdf-5acc-a5d2-611f1175aa54', '7ca73657-8ae2-5910-9eeb-06a7398e7a34', 1)
ON CONFLICT (id) DO UPDATE SET
  question_id = EXCLUDED.question_id,
  category_id = EXCLUDED.category_id,
  weight = EXCLUDED.weight;

COMMIT;
