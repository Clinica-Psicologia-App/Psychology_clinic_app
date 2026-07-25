-- =============================================================================
-- Client-requested questionnaire display updates
--
-- 1. Adiciona coluna sort_order à tabela questionnaires (padrão 999 para
--    instrumentos sem ordem definida).
-- 2. Atualiza nome, descrição e ordem dos 5 instrumentos clínicos conforme
--    solicitação do cliente (2026-07-15).
-- 3. Ajusta admin_list_questionnaires() para retornar e ordenar por sort_order.
-- =============================================================================

-- ── 1. Nova coluna sort_order ─────────────────────────────────────────────────

ALTER TABLE public.questionnaires
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 999;

COMMENT ON COLUMN public.questionnaires.sort_order IS
  'Ordem de exibição dos instrumentos na interface clínica. Menor valor = primeiro.';

CREATE INDEX IF NOT EXISTS idx_questionnaires_sort_order
  ON public.questionnaires (sort_order);

-- ── 2. Atualização dos instrumentos clínicos ──────────────────────────────────

-- YSQ-L3 — Questionário de Esquemas de Young (90 itens) → ordem 1
UPDATE public.questionnaires
SET
  name        = 'YSQ-L3 — Questionário de Esquemas de Young',
  description = 'Avalia crenças centrais, emoções e padrões de comportamento estáveis formados a partir de necessidades emocionais não atendidas na infância. (Versão Longa — 90 alternativas)',
  sort_order  = 1
WHERE code = 'YSQ_FOUNDATION_V1';

-- YPI — Young Parenting Inventory (72 itens) → ordem 2
UPDATE public.questionnaires
SET
  name        = 'YPI — Young Parenting Inventory',
  description = 'Avalia a percepção sobre os comportamentos, atitudes e o clima emocional criado pelos cuidadores durante a infância. (72 alternativas)',
  sort_order  = 2
WHERE code = 'PARENTAL_STYLES_V1';

-- YAMI — Inventário de Modos Esquemáticos de Young → ordem 3
UPDATE public.questionnaires
SET
  name        = 'YAMI — Inventário de Modos Esquemáticos de Young',
  description = 'Avalia estilos de interação e estratégias de enfrentamento de uma pessoa.',
  sort_order  = 3
WHERE code = 'YAMI_MODES_FOUNDATION_V1';

-- YCI — Young Compensation Inventory (48 itens) → ordem 4
UPDATE public.questionnaires
SET
  name        = 'YCI — Young Compensation Inventory',
  description = 'Avalia o uso de estratégias disfuncionais de enfrentamento para lutar contra Esquemas Iniciais Desadaptativos. (48 alternativas)',
  sort_order  = 4
WHERE code = 'YCI_FOUNDATION_V1';

-- YRAI — Young-Rygh Avoidance Inventory (40 itens) → ordem 5
UPDATE public.questionnaires
SET
  name        = 'YRAI — Young-Rygh Avoidance Inventory',
  description = 'Avalia como os indivíduos evitam emoções negativas, lidam com pensamentos disfuncionais e fogem da ativação de padrões comportamentais prejudiciais. (40 alternativas)',
  sort_order  = 5
WHERE code = 'YRAI_FOUNDATION_V1';

-- MVP_DEMO → desativado (não aparece mais para nenhum usuário no app)
UPDATE public.questionnaires
SET is_active = false, sort_order = 99
WHERE code = 'MVP_DEMO';

-- ── 3. Atualiza admin_list_questionnaires() ───────────────────────────────────
-- A assinatura ganha a coluna sort_order. O Postgres não permite alterar o tipo
-- de retorno via CREATE OR REPLACE (SQLSTATE 42P13), então é preciso remover a
-- função antes — e reaplicar o GRANT depois, já que o DROP o remove junto.

DROP FUNCTION IF EXISTS public.admin_list_questionnaires();

CREATE OR REPLACE FUNCTION public.admin_list_questionnaires()
RETURNS TABLE (
  id uuid, code text, name text, description text, is_active boolean,
  sort_order integer,
  author_name text, instrument_version text, citation text, license_notes text,
  clinical_status text, version_id uuid, version text, version_status text,
  reference_period text, scale_min integer, scale_max integer,
  question_count bigint, response_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.assert_platform_admin();
  RETURN QUERY
  SELECT q.id, q.code, q.name, q.description, q.is_active,
         q.sort_order,
         q.author_name, q.instrument_version, q.citation, q.license_notes,
         q.clinical_status, qv.id, qv.version, qv.status::text,
         qv.reference_period, qv.scale_min, qv.scale_max,
         (SELECT count(*) FROM public.questions qu WHERE qu.questionnaire_id = q.id),
         (SELECT count(*) FROM public.questionnaire_responses qr WHERE qr.questionnaire_id = q.id)
  FROM public.questionnaires q
  LEFT JOIN LATERAL (
    SELECT v.* FROM public.questionnaire_versions v
    WHERE v.questionnaire_id = q.id
    ORDER BY (v.status = 'active') DESC, v.created_at DESC
    LIMIT 1
  ) qv ON true
  ORDER BY q.sort_order, q.name;
END;
$$;

-- Reaplica o privilégio perdido no DROP acima.
GRANT EXECUTE ON FUNCTION public.admin_list_questionnaires() TO authenticated;
