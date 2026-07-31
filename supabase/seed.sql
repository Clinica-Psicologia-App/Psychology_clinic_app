-- =============================================================================
-- Seed mínima — MVP Plataforma Terapia do Esquema (demo)
-- Dados 100% fictícios. Idempotente via ON CONFLICT (id).
-- UUIDs fixos: docs/database-model.md | Roteiro: docs/demo-script.md
--
-- Login demo (após db reset): senha TesteMVP2025! — ver docs/demo-checklist.md
-- Profiles são criados pelo trigger handle_new_user ao inserir auth.users.
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- UUIDs fixos
-- -----------------------------------------------------------------------------
-- Clínica:     11111111-1111-1111-1111-111111111101
-- Admin:       11111111-1111-1111-1111-111111111102
-- Psychologist:11111111-1111-1111-1111-111111111103
-- Patient prof:11111111-1111-1111-1111-111111111104
-- Patient rec: 11111111-1111-1111-1111-111111111201
-- Questionnaire:11111111-1111-1111-1111-111111111301
-- Category:    11111111-1111-1111-1111-111111111401
-- Questions:   11111111-1111-1111-1111-111111111501 ..1505
-- Cat. items:  11111111-1111-1111-1111-111111111601 ..1605
-- Response:    11111111-1111-1111-1111-111111111701
-- Answers:     11111111-1111-1111-1111-111111111801 ..1805
-- Motor clínico DEMO (global, clinic_id NULL) — migration 013:
-- Domains:     66666666-6666-6666-6666-666666666601 ..602
-- Schemas:     66666666-6666-6666-6666-666666666701 ..705
-- Q version:   66666666-6666-6666-6666-666666666801 (active, MVP_DEMO v1)
-- Scoring:     66666666-6666-6666-6666-666666666901 ..905
-- Severity:    66666666-6666-6666-6666-666666666B01..B04 (+ B11..B44 por esquema)

-- 1. Clínica de teste
INSERT INTO public.clinics (id, name, document, email, phone, is_active)
VALUES (
  '11111111-1111-1111-1111-111111111101',
  'Clínica Demo — Terapia do Esquema',
  '00.000.000/0001-99',
  'contato@clinicateste-mvp.example',
  '+5511999990001',
  true
)
ON CONFLICT (id) DO NOTHING;

-- 2–4. auth.users + identities (trigger cria profiles com mesmo id)
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  confirmation_token,
  recovery_token,
  email_change_token_new,
  email_change,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
)
VALUES
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111102',
    'authenticated',
    'authenticated',
    'admin@clinicateste-mvp.example',
    crypt('TesteMVP2025!', gen_salt('bf')),
    timezone('utc', now()),
    '',
    '',
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object(
      'full_name', 'Ricardo Mendes (admin demo)',
      'clinic_id', '11111111-1111-1111-1111-111111111101',
      'role', 'platform_admin',
      'phone', '+5511999990002'
    ),
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111103',
    'authenticated',
    'authenticated',
    'psicologo@clinicateste-mvp.example',
    crypt('TesteMVP2025!', gen_salt('bf')),
    timezone('utc', now()),
    '',
    '',
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object(
      'full_name', 'Dra. Ana Costa (psicóloga demo)',
      'clinic_id', '11111111-1111-1111-1111-111111111101',
      'role', 'psychologist',
      'phone', '+5511999990003'
    ),
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    '11111111-1111-1111-1111-111111111104',
    'authenticated',
    'authenticated',
    'paciente.login@clinicateste-mvp.example',
    crypt('TesteMVP2025!', gen_salt('bf')),
    timezone('utc', now()),
    '',
    '',
    '',
    '',
    '{"provider":"email","providers":["email"]}',
    jsonb_build_object(
      'full_name', 'Maria Silva (paciente demo)',
      'clinic_id', '11111111-1111-1111-1111-111111111101',
      'role', 'patient',
      'phone', '+5511999990004'
    ),
    timezone('utc', now()),
    timezone('utc', now())
  )
ON CONFLICT (id) DO UPDATE SET
  encrypted_password = EXCLUDED.encrypted_password,
  email_confirmed_at = EXCLUDED.email_confirmed_at,
  confirmation_token = EXCLUDED.confirmation_token,
  recovery_token = EXCLUDED.recovery_token,
  email_change_token_new = EXCLUDED.email_change_token_new,
  email_change = EXCLUDED.email_change,
  raw_app_meta_data = EXCLUDED.raw_app_meta_data,
  raw_user_meta_data = EXCLUDED.raw_user_meta_data,
  updated_at = timezone('utc', now());

INSERT INTO auth.identities (
  id,
  provider_id,
  user_id,
  identity_data,
  provider,
  last_sign_in_at,
  created_at,
  updated_at
)
VALUES
  (
    '22222222-2222-2222-2222-222222222102',
    '11111111-1111-1111-1111-111111111102',
    '11111111-1111-1111-1111-111111111102',
    '{"sub":"11111111-1111-1111-1111-111111111102","email":"admin@clinicateste-mvp.example"}'::jsonb,
    'email',
    timezone('utc', now()),
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    '22222222-2222-2222-2222-222222222103',
    '11111111-1111-1111-1111-111111111103',
    '11111111-1111-1111-1111-111111111103',
    '{"sub":"11111111-1111-1111-1111-111111111103","email":"psicologo@clinicateste-mvp.example"}'::jsonb,
    'email',
    timezone('utc', now()),
    timezone('utc', now()),
    timezone('utc', now())
  ),
  (
    '22222222-2222-2222-2222-222222222104',
    '11111111-1111-1111-1111-111111111104',
    '11111111-1111-1111-1111-111111111104',
    '{"sub":"11111111-1111-1111-1111-111111111104","email":"paciente.login@clinicateste-mvp.example"}'::jsonb,
    'email',
    timezone('utc', now()),
    timezone('utc', now()),
    timezone('utc', now())
  )
ON CONFLICT (id) DO NOTHING;

-- 4b. Nomes legíveis nos profiles (após upsert em auth.users)
UPDATE public.profiles SET full_name = 'Ricardo Mendes (admin demo)'
  WHERE id = '11111111-1111-1111-1111-111111111102';
UPDATE public.profiles SET full_name = 'Dra. Ana Costa (psicóloga demo)'
  WHERE id = '11111111-1111-1111-1111-111111111103';
UPDATE public.profiles SET full_name = 'Maria Silva (paciente demo)'
  WHERE id = '11111111-1111-1111-1111-111111111104';

-- 5. Paciente vinculado ao profile patient e ao psicólogo
INSERT INTO public.patients (
  id,
  clinic_id,
  profile_id,
  responsible_psychologist_id,
  full_name,
  email,
  phone,
  cpf,
  birth_date,
  gender,
  has_children
)
VALUES (
  '11111111-1111-1111-1111-111111111201',
  '11111111-1111-1111-1111-111111111101',
  '11111111-1111-1111-1111-111111111104',
  '11111111-1111-1111-1111-111111111103',
  'Maria Silva (paciente demo)',
  'paciente@clinicateste-mvp.example',
  '+5511999990005',
  '00000000191',
  '1990-05-15',
  'nao_informado',
  false
)
ON CONFLICT (id) DO NOTHING;

-- 6. Questionário de teste
INSERT INTO public.questionnaires (id, code, name, description, is_active)
VALUES (
  '11111111-1111-1111-1111-111111111301',
  'MVP_DEMO',
  'Inventário Demo — 5 itens',
  'Questionário fictício para demonstração do fluxo (Likert 1–6). Não é instrumento clínico validado.',
  true
)
ON CONFLICT (id) DO NOTHING;

-- 7. Categoria de apuração
INSERT INTO public.question_categories (id, questionnaire_id, code, name, description)
VALUES (
  '11111111-1111-1111-1111-111111111401',
  '11111111-1111-1111-1111-111111111301',
  'DEMO_GERAL',
  'Categoria demonstração',
  'Agrupa as cinco perguntas do questionário de teste.'
)
ON CONFLICT (id) DO NOTHING;

-- 7b. Versão ativa (perguntas e respostas são fixadas por versão)
INSERT INTO public.questionnaire_versions (
  id, questionnaire_id, version, status, scoring_method,
  scale_min, scale_max, instructions, published_at
)
VALUES (
  '66666666-6666-6666-6666-666666666801',
  '11111111-1111-1111-1111-111111111301',
  'v1-demo',
  'active',
  'weighted_sum_demo',
  1,
  6,
  'DEMO — Inventário fictício de 5 itens (escala 1 a 6). Responda pensando na última semana. Estes resultados não têm interpretação clínica validada.',
  timezone('utc', now()) - interval '7 days'
)
ON CONFLICT (id) DO NOTHING;

-- 8. Cinco perguntas (fixadas na versão v1-demo)
INSERT INTO public.questions (
  id, questionnaire_id, questionnaire_version_id, code, text, order_index, answer_type, scale_min, scale_max, is_active
)
VALUES
  (
    '11111111-1111-1111-1111-111111111501',
    '11111111-1111-1111-1111-111111111301',
    '66666666-6666-6666-6666-666666666801',
    'Q01',
    'Sinto que as pessoas importantes não estarão disponíveis quando preciso (fictício).',
    0,
    'likert_scale',
    1,
    6,
    true
  ),
  (
    '11111111-1111-1111-1111-111111111502',
    '11111111-1111-1111-1111-111111111301',
    '66666666-6666-6666-6666-666666666801',
    'Q02',
    'Tenho dificuldade em confiar nas pessoas próximas (fictício).',
    1,
    'likert_scale',
    1,
    6,
    true
  ),
  (
    '11111111-1111-1111-1111-111111111503',
    '11111111-1111-1111-1111-111111111301',
    '66666666-6666-6666-6666-666666666801',
    'Q03',
    'Sinto que não pertenço em grupos sociais (fictício).',
    2,
    'likert_scale',
    1,
    6,
    true
  ),
  (
    '11111111-1111-1111-1111-111111111504',
    '11111111-1111-1111-1111-111111111301',
    '66666666-6666-6666-6666-666666666801',
    'Q04',
    'Preciso de aprovação dos outros para me sentir bem (fictício).',
    3,
    'likert_scale',
    1,
    6,
    true
  ),
  (
    '11111111-1111-1111-1111-111111111505',
    '11111111-1111-1111-1111-111111111301',
    '66666666-6666-6666-6666-666666666801',
    'Q05',
    'Tenho medo de perder o controle das minhas emoções (fictício).',
    4,
    'likert_scale',
    1,
    6,
    true
  )
ON CONFLICT (id) DO NOTHING;

-- 9. Vínculos categoria ↔ perguntas (peso 1)
INSERT INTO public.question_category_items (id, question_id, category_id, weight)
VALUES
  ('11111111-1111-1111-1111-111111111601', '11111111-1111-1111-1111-111111111501', '11111111-1111-1111-1111-111111111401', 1),
  ('11111111-1111-1111-1111-111111111602', '11111111-1111-1111-1111-111111111502', '11111111-1111-1111-1111-111111111401', 1),
  ('11111111-1111-1111-1111-111111111603', '11111111-1111-1111-1111-111111111503', '11111111-1111-1111-1111-111111111401', 1),
  ('11111111-1111-1111-1111-111111111604', '11111111-1111-1111-1111-111111111504', '11111111-1111-1111-1111-111111111401', 1),
  ('11111111-1111-1111-1111-111111111605', '11111111-1111-1111-1111-111111111505', '11111111-1111-1111-1111-111111111401', 1)
ON CONFLICT (id) DO NOTHING;

-- 10. Resposta de questionário concluída (fixada na versão v1-demo)
INSERT INTO public.questionnaire_responses (
  id,
  clinic_id,
  patient_id,
  questionnaire_id,
  questionnaire_version_id,
  status,
  started_at,
  completed_at
)
VALUES (
  '11111111-1111-1111-1111-111111111701',
  '11111111-1111-1111-1111-111111111101',
  '11111111-1111-1111-1111-111111111201',
  '11111111-1111-1111-1111-111111111301',
  '66666666-6666-6666-6666-666666666801',
  'completed',
  timezone('utc', now()) - interval '1 day',
  timezone('utc', now()) - interval '23 hours'
)
ON CONFLICT (id) DO NOTHING;

-- 11. Cinco respostas por pergunta
INSERT INTO public.questionnaire_answers (id, response_id, question_id, answer_value)
VALUES
  ('11111111-1111-1111-1111-111111111801', '11111111-1111-1111-1111-111111111701', '11111111-1111-1111-1111-111111111501', 4),
  ('11111111-1111-1111-1111-111111111802', '11111111-1111-1111-1111-111111111701', '11111111-1111-1111-1111-111111111502', 3),
  ('11111111-1111-1111-1111-111111111803', '11111111-1111-1111-1111-111111111701', '11111111-1111-1111-1111-111111111503', 5),
  ('11111111-1111-1111-1111-111111111804', '11111111-1111-1111-1111-111111111701', '11111111-1111-1111-1111-111111111504', 2),
  ('11111111-1111-1111-1111-111111111805', '11111111-1111-1111-1111-111111111701', '11111111-1111-1111-1111-111111111505', 4)
ON CONFLICT (id) DO NOTHING;

-- 12. Recursos terapêuticos da clínica
INSERT INTO public.therapy_resources (
  id, clinic_id, title, type, description, url, is_active
)
VALUES
  (
    '33333333-3333-3333-3333-333333333301',
    '11111111-1111-1111-1111-111111111101',
    'Leitura: Introdução aos esquemas',
    'article',
    'Artigo fictício de psicoeducação para a demo (link de exemplo).',
    'https://clinicateste-mvp.example/recursos/esquemas',
    true
  ),
  (
    '33333333-3333-3333-3333-333333333302',
    '11111111-1111-1111-1111-111111111101',
    'Exercício: Registro emocional guiado',
    'exercise',
    'Atividade entre sessões — ideal para liberar na demo ao vivo.',
    null,
    true
  ),
  (
    '33333333-3333-3333-3333-333333333303',
    '11111111-1111-1111-1111-111111111101',
    'Vídeo: Ancoragem no presente (grounding)',
    'video',
    'Vídeo fictício curto; URL de exemplo para abrir no app.',
    'https://clinicateste-mvp.example/recursos/grounding',
    true
  )
ON CONFLICT (id) DO NOTHING;

-- 13. Liberação de recurso ao paciente seed
INSERT INTO public.patient_resource_access (
  id, patient_id, resource_id, released_by_profile_id, is_active, released_at
)
VALUES (
  '33333333-3333-3333-3333-333333333401',
  '11111111-1111-1111-1111-111111111201',
  '33333333-3333-3333-3333-333333333301',
  '11111111-1111-1111-1111-111111111103',
  true,
  timezone('utc', now()) - interval '2 days'
)
ON CONFLICT (id) DO NOTHING;

-- 14. Monitor diário do paciente seed
INSERT INTO public.daily_monitors (
  id,
  clinic_id,
  patient_id,
  mood_notes,
  sleep_notes,
  activity_notes,
  emotion_notes,
  created_at
)
VALUES (
  '44444444-4444-4444-4444-444444444401',
  '11111111-1111-1111-1111-111111111101',
  '11111111-1111-1111-1111-111111111201',
  'Ansiosa pela manhã; mais tranquila após conversar com um amigo.',
  'Sono: ~6h. Acordei cedo pensando no dia de trabalho.',
  'Caminhada de 20 min no fim da tarde; evitei redes sociais à noite.',
  E'Intensidade: 6/10\nGatilhos: Prazo no trabalho; notícia no celular',
  timezone('utc', now()) - interval '1 day'
)
ON CONFLICT (id) DO NOTHING;

-- 15. Resultado MVP (snapshot) da resposta concluída — para tela de Resultados (staff)
INSERT INTO public.questionnaire_results (
  id,
  response_id,
  questionnaire_id,
  category_id,
  total_score,
  average_score,
  classification,
  snapshot
)
VALUES (
  '55555555-5555-5555-5555-555555555501',
  '11111111-1111-1111-1111-111111111701',
  '11111111-1111-1111-1111-111111111301',
  '11111111-1111-1111-1111-111111111401',
  18,
  3.6,
  'pending_review',
  jsonb_build_object(
    'version', 'mvp-1',
    'category_code', 'DEMO_GERAL',
    'category_name', 'Categoria demonstração',
    'answer_count', 5,
    'total_weighted_score', 18,
    'average_score', 3.6,
    'note', 'Agregação placeholder — motor clínico não aplicado (demo)',
    'items', jsonb_build_array(
      jsonb_build_object('question_id', '11111111-1111-1111-1111-111111111501', 'answer_value', 4, 'weight', 1, 'weighted_score', 4),
      jsonb_build_object('question_id', '11111111-1111-1111-1111-111111111502', 'answer_value', 3, 'weight', 1, 'weighted_score', 3),
      jsonb_build_object('question_id', '11111111-1111-1111-1111-111111111503', 'answer_value', 5, 'weight', 1, 'weighted_score', 5),
      jsonb_build_object('question_id', '11111111-1111-1111-1111-111111111504', 'answer_value', 2, 'weight', 1, 'weighted_score', 2),
      jsonb_build_object('question_id', '11111111-1111-1111-1111-111111111505', 'answer_value', 4, 'weight', 1, 'weighted_score', 4)
    )
  )
)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 16. Motor clínico — catálogo DEMO global (NÃO é instrumento clínico validado)
-- Tabelas: schema_domains, schemas, questionnaire_versions,
--           question_scoring_rules, severity_ranges (migration 013)
-- -----------------------------------------------------------------------------

-- 16a. Domínios DEMO (fictícios, inspirados em agrupamentos comuns — sem validação clínica)
INSERT INTO public.schema_domains (
  id, clinic_id, code, name, description, sort_order, is_active
)
VALUES
  (
    '66666666-6666-6666-6666-666666666601',
    NULL,
    'DEMO_DOMAIN_DISCONNECTION',
    'Demo — Domínio Desconexão/Rejeição (fictício)',
    'Agrupamento DEMO para itens de abandono e desconfiança. Não substitui domínios oficiais da Terapia do Esquema.',
    0,
    true
  ),
  (
    '66666666-6666-6666-6666-666666666602',
    NULL,
    'DEMO_DOMAIN_OTHER_DIRECTED',
    'Demo — Domínio Orientação ao outro (fictício)',
    'Agrupamento DEMO para pertencimento, aprovação e controle emocional. Apenas para testes de catálogo no banco.',
    1,
    true
  )
ON CONFLICT (id) DO NOTHING;

-- 16b. Esquemas DEMO (clinic_id NULL — alinhados ao domínio global)
INSERT INTO public.schemas (
  id, domain_id, clinic_id, code, name, description, sort_order, is_active
)
VALUES
  (
    '66666666-6666-6666-6666-666666666701',
    '66666666-6666-6666-6666-666666666601',
    NULL,
    'DEMO_SCHEMA_ABANDONMENT',
    'Demo — Esquema Abandono (fictício)',
    'Mapeamento DEMO da pergunta Q01. Não é o Esquema Abandono clínico oficial.',
    0,
    true
  ),
  (
    '66666666-6666-6666-6666-666666666702',
    '66666666-6666-6666-6666-666666666601',
    NULL,
    'DEMO_SCHEMA_MISTRUST',
    'Demo — Esquema Desconfiança (fictício)',
    'Mapeamento DEMO da pergunta Q02.',
    1,
    true
  ),
  (
    '66666666-6666-6666-6666-666666666703',
    '66666666-6666-6666-6666-666666666602',
    NULL,
    'DEMO_SCHEMA_SOCIAL_EXCLUSION',
    'Demo — Esquema Exclusão social (fictício)',
    'Mapeamento DEMO da pergunta Q03.',
    0,
    true
  ),
  (
    '66666666-6666-6666-6666-666666666704',
    '66666666-6666-6666-6666-666666666602',
    NULL,
    'DEMO_SCHEMA_APPROVAL',
    'Demo — Esquema Busca de aprovação (fictício)',
    'Mapeamento DEMO da pergunta Q04.',
    1,
    true
  ),
  (
    '66666666-6666-6666-6666-666666666705',
    '66666666-6666-6666-6666-666666666602',
    NULL,
    'DEMO_SCHEMA_EMOTIONAL_CONTROL',
    'Demo — Esquema Controle emocional (fictício)',
    'Mapeamento DEMO da pergunta Q05.',
    2,
    true
  )
ON CONFLICT (id) DO NOTHING;

-- 16c. Versão ativa do questionário MVP_DEMO (regras de pontuação DEMO)
INSERT INTO public.questionnaire_versions (
  id,
  questionnaire_id,
  version,
  status,
  scoring_method,
  scale_min,
  scale_max,
  instructions,
  published_at
)
VALUES (
  '66666666-6666-6666-6666-666666666801',
  '11111111-1111-1111-1111-111111111301',
  'v1-demo',
  'active',
  'weighted_sum_demo',
  1,
  6,
  'DEMO — Inventário fictício de 5 itens (escala 1 a 6). Responda pensando na última semana. Estes resultados não têm interpretação clínica validada.',
  timezone('utc', now()) - interval '7 days'
)
ON CONFLICT (id) DO NOTHING;

-- 16d. Regras de pontuação por pergunta (versão demo × perguntas seed Q01–Q05)
INSERT INTO public.question_scoring_rules (
  id,
  questionnaire_version_id,
  question_id,
  schema_id,
  domain_id,
  weight,
  reverse_score,
  min_value,
  max_value,
  sort_order,
  metadata
)
VALUES
  (
    '66666666-6666-6666-6666-666666666901',
    '66666666-6666-6666-6666-666666666801',
    '11111111-1111-1111-1111-111111111501',
    '66666666-6666-6666-6666-666666666701',
    '66666666-6666-6666-6666-666666666601',
    1,
    false,
    1,
    6,
    0,
    '{"demo": true, "question_code": "Q01", "note": "Catálogo DEMO — motor não calcula ainda"}'::jsonb
  ),
  (
    '66666666-6666-6666-6666-666666666902',
    '66666666-6666-6666-6666-666666666801',
    '11111111-1111-1111-1111-111111111502',
    '66666666-6666-6666-6666-666666666702',
    '66666666-6666-6666-6666-666666666601',
    1,
    false,
    1,
    6,
    1,
    '{"demo": true, "question_code": "Q02"}'::jsonb
  ),
  (
    '66666666-6666-6666-6666-666666666903',
    '66666666-6666-6666-6666-666666666801',
    '11111111-1111-1111-1111-111111111503',
    '66666666-6666-6666-6666-666666666703',
    '66666666-6666-6666-6666-666666666602',
    1,
    false,
    1,
    6,
    2,
    '{"demo": true, "question_code": "Q03"}'::jsonb
  ),
  (
    '66666666-6666-6666-6666-666666666904',
    '66666666-6666-6666-6666-666666666801',
    '11111111-1111-1111-1111-111111111504',
    '66666666-6666-6666-6666-666666666704',
    '66666666-6666-6666-6666-666666666602',
    1,
    false,
    1,
    6,
    3,
    '{"demo": true, "question_code": "Q04"}'::jsonb
  ),
  (
    '66666666-6666-6666-6666-666666666905',
    '66666666-6666-6666-6666-666666666801',
    '11111111-1111-1111-1111-111111111505',
    '66666666-6666-6666-6666-666666666705',
    '66666666-6666-6666-6666-666666666602',
    1,
    false,
    1,
    6,
    4,
    '{"demo": true, "question_code": "Q05"}'::jsonb
  )
ON CONFLICT (id) DO NOTHING;

-- 16e. Faixas de severidade DEMO (média ponderada 1–6 por esquema — referência futura)
-- schema_id preenchido por esquema; cortes fictícios para validação de estrutura apenas.
INSERT INTO public.severity_ranges (
  id,
  questionnaire_version_id,
  schema_id,
  domain_id,
  label,
  min_score,
  max_score,
  color_key,
  sort_order,
  metadata
)
VALUES
  -- Esquema DEMO Abandono (Q01)
  ('66666666-6666-6666-6666-666666666B01', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666701', NULL, 'Demo — Baixo', 1, 2.5, 'severity_low', 0, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B02', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666701', NULL, 'Demo — Moderado', 2.51, 4, 'severity_moderate', 1, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B03', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666701', NULL, 'Demo — Alto', 4.01, 5, 'severity_high', 2, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B04', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666701', NULL, 'Demo — Muito alto', 5.01, 6, 'severity_very_high', 3, '{"demo": true}'::jsonb),
  -- Repetir faixas DEMO para os demais esquemas (mesmos limiares fictícios 1–6)
  ('66666666-6666-6666-6666-666666666B11', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666702', NULL, 'Demo — Baixo', 1, 2.5, 'severity_low', 0, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B12', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666702', NULL, 'Demo — Moderado', 2.51, 4, 'severity_moderate', 1, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B13', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666702', NULL, 'Demo — Alto', 4.01, 5, 'severity_high', 2, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B14', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666702', NULL, 'Demo — Muito alto', 5.01, 6, 'severity_very_high', 3, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B21', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666703', NULL, 'Demo — Baixo', 1, 2.5, 'severity_low', 0, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B22', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666703', NULL, 'Demo — Moderado', 2.51, 4, 'severity_moderate', 1, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B23', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666703', NULL, 'Demo — Alto', 4.01, 5, 'severity_high', 2, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B24', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666703', NULL, 'Demo — Muito alto', 5.01, 6, 'severity_very_high', 3, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B31', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666704', NULL, 'Demo — Baixo', 1, 2.5, 'severity_low', 0, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B32', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666704', NULL, 'Demo — Moderado', 2.51, 4, 'severity_moderate', 1, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B33', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666704', NULL, 'Demo — Alto', 4.01, 5, 'severity_high', 2, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B34', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666704', NULL, 'Demo — Muito alto', 5.01, 6, 'severity_very_high', 3, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B41', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666705', NULL, 'Demo — Baixo', 1, 2.5, 'severity_low', 0, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B42', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666705', NULL, 'Demo — Moderado', 2.51, 4, 'severity_moderate', 1, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B43', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666705', NULL, 'Demo — Alto', 4.01, 5, 'severity_high', 2, '{"demo": true}'::jsonb),
  ('66666666-6666-6666-6666-666666666B44', '66666666-6666-6666-6666-666666666801', '66666666-6666-6666-6666-666666666705', NULL, 'Demo — Muito alto', 5.01, 6, 'severity_very_high', 3, '{"demo": true}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 17. Metadados do catálogo + acesso do psicólogo seed
-- -----------------------------------------------------------------------------

UPDATE public.questionnaires
SET
  author_name = src.author_name,
  instrument_version = src.instrument_version,
  citation = src.citation,
  license_notes = src.license_notes,
  updated_at = timezone('utc', now())
FROM (
  VALUES
    (
      'MVP_DEMO',
      'Equipe MVP Terapia do Esquema',
      'v1-demo',
      'Instrumento demonstrativo interno do MVP.',
      'Uso interno de demonstração.'
    ),
    (
      'YSQ_FOUNDATION_V1',
      'Jeffrey E. Young',
      'Foundation v1',
      'Young Schema Questionnaire (catálogo clínico importado para homologação).',
      'Pendente validação clínica/licenciamento.'
    ),
    (
      'YAMI_MODES_FOUNDATION_V1',
      'Catálogo clínico interno',
      'Foundation v1',
      'YAMI - Modos Esquemáticos (base importada para homologação).',
      'Pendente validação clínica/licenciamento.'
    ),
    (
      'PARENTAL_STYLES_V1',
      'Catálogo clínico interno',
      'v1',
      'Instrumento de estilos parentais importado para apoio à formulação clínica.',
      'Pendente validação clínica/licenciamento.'
    ),
    (
      'ATTACHMENT_STYLES_V1',
      'Catálogo clínico interno',
      'v1',
      'Instrumento de estilos de apego importado para apoio à formulação clínica.',
      'Pendente validação clínica/licenciamento.'
    ),
    (
      'YCI_FOUNDATION_V1',
      'Catálogo clínico interno',
      'Foundation v1',
      'Inventário YCI importado para apoio à formulação de estilos de enfrentamento.',
      'Pendente validação clínica/licenciamento.'
    ),
    (
      'YRAI_FOUNDATION_V1',
      'Catálogo clínico interno',
      'Foundation v1',
      'Inventário YRAI importado para apoio à formulação de estilos de enfrentamento.',
      'Pendente validação clínica/licenciamento.'
    )
) AS src(code, author_name, instrument_version, citation, license_notes)
WHERE public.questionnaires.code = src.code;

INSERT INTO public.questionnaire_professional_access (
  clinic_id,
  questionnaire_id,
  professional_id,
  granted_by,
  is_enabled
)
SELECT
  '11111111-1111-1111-1111-111111111101',
  q.id,
  '11111111-1111-1111-1111-111111111103',
  '11111111-1111-1111-1111-111111111102',
  true
FROM public.questionnaires AS q
WHERE q.code IN (
  'MVP_DEMO',
  'YSQ_FOUNDATION_V1',
  'YAMI_MODES_FOUNDATION_V1',
  'PARENTAL_STYLES_V1',
  'ATTACHMENT_STYLES_V1',
  'YCI_FOUNDATION_V1',
  'YRAI_FOUNDATION_V1'
)
ON CONFLICT (questionnaire_id, professional_id) DO UPDATE
SET
  clinic_id = EXCLUDED.clinic_id,
  granted_by = EXCLUDED.granted_by,
  is_enabled = true,
  revoked_at = NULL,
  updated_at = timezone('utc', now());

COMMIT;
