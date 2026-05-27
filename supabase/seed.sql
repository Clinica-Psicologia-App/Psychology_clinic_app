-- =============================================================================
-- Seed mínima — MVP Plataforma Terapia do Esquema
-- Dados fictícios para testar relacionamentos. Idempotente via ON CONFLICT (id).
-- UUIDs fixos documentados em docs/database-model.md / next-steps.md
--
-- Login de teste (após db reset): senha TesteMVP2025! para os três e-mails abaixo.
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

-- 1. Clínica de teste
INSERT INTO public.clinics (id, name, document, email, phone, is_active)
VALUES (
  '11111111-1111-1111-1111-111111111101',
  'Clínica Teste MVP',
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
      'full_name', 'Admin Teste MVP',
      'clinic_id', '11111111-1111-1111-1111-111111111101',
      'role', 'admin',
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
      'full_name', 'Psicólogo Teste MVP',
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
      'full_name', 'Login Paciente Teste MVP',
      'clinic_id', '11111111-1111-1111-1111-111111111101',
      'role', 'patient',
      'phone', '+5511999990004'
    ),
    timezone('utc', now()),
    timezone('utc', now())
  )
ON CONFLICT (id) DO NOTHING;

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
  'Paciente Fictício Teste MVP',
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
  'Questionário Demonstração MVP',
  'Instrumento fictício com 5 itens Likert para validar fluxo de respostas.',
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

-- 8. Cinco perguntas
INSERT INTO public.questions (
  id, questionnaire_id, code, text, order_index, answer_type, scale_min, scale_max, is_active
)
VALUES
  (
    '11111111-1111-1111-1111-111111111501',
    '11111111-1111-1111-1111-111111111301',
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

-- 10. Resposta de questionário concluída
INSERT INTO public.questionnaire_responses (
  id,
  clinic_id,
  patient_id,
  questionnaire_id,
  status,
  started_at,
  completed_at
)
VALUES (
  '11111111-1111-1111-1111-111111111701',
  '11111111-1111-1111-1111-111111111101',
  '11111111-1111-1111-1111-111111111201',
  '11111111-1111-1111-1111-111111111301',
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

COMMIT;
