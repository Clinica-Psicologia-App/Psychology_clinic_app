-- Biblioteca de Psicoeducação (EsquemaCore).
--
-- Jornada educativa em "bibliotecas" (módulos) organizadas em três etapas:
-- Conhecer, Compreender e Transformar. Cada módulo tem uma apresentação, um
-- conjunto de cards e um fechamento. Cada card tem texto do paciente e, opcional,
-- texto do terapeuta (que NUNCA vai para o paciente — privacidade de coluna).
--
-- Curadoria do admin; a publicação libera o módulo para os psicólogos e para os
-- pacientes. O acesso do paciente é feito por RPC SECURITY DEFINER que remove o
-- texto do terapeuta.

CREATE TABLE IF NOT EXISTS public.psychoeducation_modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  number INT NOT NULL,
  stage TEXT NOT NULL,           -- Conhecer | Compreender | Transformar
  title TEXT NOT NULL,
  presentation TEXT,
  closing TEXT,
  accent_color TEXT,             -- hex (#RRGGBB) para a cor do módulo
  cover_url TEXT,
  cards JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_published BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

CREATE UNIQUE INDEX IF NOT EXISTS psychoeducation_modules_number_key
  ON public.psychoeducation_modules (number);

ALTER TABLE public.psychoeducation_modules ENABLE ROW LEVEL SECURITY;

-- Staff (psicólogo/admin) lê os módulos publicados (com o texto do terapeuta).
DROP POLICY IF EXISTS psychoeducation_select_staff ON public.psychoeducation_modules;
CREATE POLICY psychoeducation_select_staff
  ON public.psychoeducation_modules FOR SELECT TO authenticated
  USING (public.current_role()::TEXT <> 'patient' AND is_published);

-- Admin gerencia o catálogo.
DROP POLICY IF EXISTS psychoeducation_admin_all ON public.psychoeducation_modules;
CREATE POLICY psychoeducation_admin_all
  ON public.psychoeducation_modules FOR ALL TO authenticated
  USING (public.current_role()::TEXT IN ('platform_admin', 'admin'))
  WITH CHECK (public.current_role()::TEXT IN ('platform_admin', 'admin'));

-- Acesso do paciente: RPC SECURITY DEFINER que devolve os módulos publicados
-- SEM o texto do terapeuta (privacidade de coluna — o role authenticated é
-- compartilhado, então não dá para depender só de RLS por coluna).
CREATE OR REPLACE FUNCTION public.get_psychoeducation_journey()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(m ORDER BY m.number), '[]'::jsonb)
  INTO result
  FROM (
    SELECT
      pm.id,
      pm.number,
      pm.stage,
      pm.title,
      pm.presentation,
      pm.closing,
      pm.accent_color,
      pm.cover_url,
      COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'title', card->>'title',
            'image_url', card->>'image_url',
            'patient_text', card->>'patient_text',
            'reflection', card->>'reflection',
            'exercise', card->>'exercise'
          )
        )
        FROM jsonb_array_elements(pm.cards) AS card
      ), '[]'::jsonb) AS cards
    FROM public.psychoeducation_modules pm
    WHERE pm.is_published
    ORDER BY pm.number
  ) m;

  RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_psychoeducation_journey() TO authenticated;

-- ── Seed dos módulos 7–12 (idempotente por number) ───────────────────────────
-- Conteúdo derivado do documento "App Biblioteca de Psicoeducação". Os módulos
-- 1–6 ficam para curadoria posterior. O texto é o do documento; onde ele só
-- fornece o objetivo/estrutura, os cards ficam a completar pela curadoria.

INSERT INTO public.psychoeducation_modules
  (number, stage, title, presentation, closing, accent_color, cards)
VALUES
(
  7, 'Compreender', 'Os Domínios dos Esquemas',
  'Os 18 esquemas se organizam em cinco grandes áreas da vida emocional. Conhecer os domínios ajuda a enxergar o mapa antes de olhar cada peça.',
  null, '#6366F1',
  $pe$[
    {"title":"Domínio 1 — Desconexão e Rejeição","patient_text":"Necessidades de segurança, aceitação e vínculo que não foram suficientemente atendidas."},
    {"title":"Domínio 2 — Autonomia e Desempenho Prejudicados","patient_text":"Dificuldades ligadas à independência e à confiança nas próprias capacidades."},
    {"title":"Domínio 3 — Limites Prejudicados","patient_text":"Dificuldade com limites internos, responsabilidade e autodisciplina."},
    {"title":"Domínio 4 — Direcionamento para o Outro","patient_text":"Foco excessivo nas necessidades dos outros em detrimento das próprias."},
    {"title":"Domínio 5 — Supervigilância e Inibição","patient_text":"Ênfase em controle, regras e supressão de espontaneidade e emoções."}
  ]$pe$::jsonb
),
(
  8, 'Compreender', 'Conhecendo os 18 Esquemas de Jeffrey Young',
  'Cada esquema é apresentado individualmente: o que é, como aparece, como surgiu e como transformar. Um a um, os padrões ganham nome.',
  null, '#6366F1',
  $pe$[]$pe$::jsonb
),
(
  9, 'Transformar', 'Reconhecendo Meus Padrões',
  'Da compreensão para a identificação pessoal: perceber quando o padrão aparece na sua própria vida. Ferramentas de apoio no app: diário emocional, registro de situações e identificação de gatilhos.',
  null, '#059669',
  $pe$[
    {"title":"Quando esse padrão aparece?","patient_text":"Observe os momentos em que o padrão se manifesta.","reflection":"Em que situações recentes você percebeu esse padrão?"},
    {"title":"Quais situações ativam?","patient_text":"Identifique os gatilhos que disparam a reação.","reflection":"O que costuma acontecer antes de o padrão aparecer?"},
    {"title":"Que emoções surgem?","patient_text":"Nomeie as emoções que aparecem junto do padrão.","reflection":"Quais emoções você reconhece nesses momentos?"},
    {"title":"Como costumo reagir?","patient_text":"Perceba a resposta automática que você costuma dar.","reflection":"Como você normalmente reage — e o que gostaria de fazer diferente?"}
  ]$pe$::jsonb
),
(
  10, 'Transformar', 'Libertando os Esquemas',
  'Estratégias iniciais de mudança para cada esquema: reconhecimento, aceitação, questionamento e novas respostas.',
  null, '#059669',
  $pe$[
    {"title":"Quando meu esquema aparece...","patient_text":"Descreva o que acontece quando o esquema é ativado — pensamentos, sensações e impulsos.","exercise":"Complete: “Quando meu esquema aparece, eu costumo…”"},
    {"title":"Meu Adulto Saudável pode...","patient_text":"Ensaie uma resposta mais flexível e cuidadosa a partir do Adulto Saudável.","exercise":"Complete: “Meu Adulto Saudável pode…”"}
  ]$pe$::jsonb
),
(
  11, 'Transformar', 'Conhecendo os Modos Esquemáticos',
  'Modos são estados emocionais momentâneos — a parte de você que assume o comando em cada situação. Reconhecê-los ajuda a escolher como responder.',
  null, '#059669',
  $pe$[
    {"title":"Modos Criança","patient_text":"Criança Vulnerável, Criança Zangada, Criança Impulsiva e Criança Feliz."},
    {"title":"Modos Parentais","patient_text":"Pai/Mãe Punitivo e Pai/Mãe Exigente — vozes internas de crítica e cobrança."},
    {"title":"Modos de Enfrentamento","patient_text":"Protetor Desligado, Capitulador Complacente e Hipercompensadores — formas de lidar com a dor."},
    {"title":"Modos Saudáveis","patient_text":"Adulto Saudável e Criança Feliz — os modos que queremos fortalecer."}
  ]$pe$::jsonb
),
(
  12, 'Transformar', 'Construindo o Adulto Saudável',
  'O fechamento da jornada de compreensão e o começo da transformação: desenvolver a parte de você capaz de cuidar, escolher e viver com sentido.',
  'Você não é definido pelo que aprendeu para sobreviver. Você pode construir novas formas de viver.',
  '#059669',
  $pe$[
    {"title":"Autocuidado","patient_text":"Reconhecer e atender às próprias necessidades básicas."},
    {"title":"Autocompaixão","patient_text":"Tratar-se com a mesma gentileza que ofereceria a quem você ama."},
    {"title":"Limites","patient_text":"Dizer sim e não a partir do que é saudável para você."},
    {"title":"Escolhas conscientes","patient_text":"Decidir a partir de valores, não de padrões automáticos."},
    {"title":"Relacionamentos saudáveis","patient_text":"Construir vínculos com reciprocidade, respeito e verdade."},
    {"title":"Conexão com valores","patient_text":"Orientar a vida pelo que realmente importa para você."}
  ]$pe$::jsonb
)
ON CONFLICT (number) DO UPDATE SET
  stage = EXCLUDED.stage,
  title = EXCLUDED.title,
  presentation = EXCLUDED.presentation,
  closing = EXCLUDED.closing,
  accent_color = EXCLUDED.accent_color,
  cards = EXCLUDED.cards,
  updated_at = timezone('utc', now());
