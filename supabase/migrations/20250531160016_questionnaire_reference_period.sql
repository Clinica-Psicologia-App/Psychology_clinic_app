-- Período de referência temporal por versão de questionário (orientação ao paciente).
-- Não altera o motor de apuração (finish-questionnaire / scoring).

ALTER TABLE public.questionnaire_versions
  ADD COLUMN reference_period TEXT NOT NULL DEFAULT 'unspecified';

ALTER TABLE public.questionnaire_versions
  ADD CONSTRAINT questionnaire_versions_reference_period_valid
  CHECK (reference_period IN (
    'unspecified',
    'last_month',
    'last_year',
    'lifetime'
  ));

COMMENT ON COLUMN public.questionnaire_versions.reference_period IS
  'Janela temporal que o respondente deve considerar ao responder (ex.: último ano no YSQ). '
  'Usado na introdução do app antes de iniciar; não entra no cálculo de scores. '
  'Valores: unspecified, last_month, last_year, lifetime.';

-- YSQ: últimos 12 meses
UPDATE public.questionnaire_versions qv
SET reference_period = 'last_year'
FROM public.questionnaires q
WHERE qv.questionnaire_id = q.id
  AND q.code = 'YSQ_FOUNDATION_V1';

-- YAMI: último mês
UPDATE public.questionnaire_versions qv
SET reference_period = 'last_month'
FROM public.questionnaires q
WHERE qv.questionnaire_id = q.id
  AND q.code = 'YAMI_MODES_FOUNDATION_V1';

-- MVP demo: sem orientação temporal específica (permanece default se já unspecified)
UPDATE public.questionnaire_versions qv
SET reference_period = 'unspecified'
FROM public.questionnaires q
WHERE qv.questionnaire_id = q.id
  AND q.code = 'MVP_DEMO';
