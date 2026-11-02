-- =============================================================================
-- Textos do paciente por instrumento (feedback Guacira/Luciana, out/2026)
--
-- Nova coluna questionnaires.patient_content (jsonb) com os textos exibidos ao
-- paciente, para ajustar a redação sem publicar nova versão do app:
--   intro                 apresentação no topo da tela "Antes de começar"
--   how_to_respond        cartão "Como responder" / "Orientação para resposta"
--   how_to_respond_title  título do cartão acima (padrão: "Como responder")
--   reference_period_text substitui o texto padrão do período de referência
--   fixed_question        pergunta fixa exibida durante todo o questionário
--   scale_labels          6 rótulos da escala (1..6), mostrados ao selecionar
--   follow_up             corpo do cartão "Para seu acompanhamento"
--
-- Também atualiza a descrição ("Sobre este instrumento" e cartão da lista).
-- Não altera perguntas nem versões; correções de português ficam em outra
-- migração, após aprovação das clientes.
-- =============================================================================

BEGIN;

ALTER TABLE public.questionnaires
  ADD COLUMN IF NOT EXISTS patient_content jsonb;

COMMENT ON COLUMN public.questionnaires.patient_content IS
  'Textos exibidos ao paciente (intro, how_to_respond, fixed_question, scale_labels, follow_up...). Ver migração 20261102100000.';

-- ── YCI ──────────────────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  description = 'Este questionário ajuda a identificar maneiras de reagir a situações difíceis, especialmente quando você tenta se proteger de sentimentos de vulnerabilidade.',
  patient_content = $json${
    "intro": "Antes de começar, leia as orientações para responder ao questionário. Suas respostas contribuirão para a compreensão do seu processo terapêutico.",
    "how_to_respond": "Leia cada afirmação com atenção e considere até que ponto ela descreve você. Para responder, escolha uma das seis opções da escala, selecionando aquela que melhor corresponde ao seu caso.",
    "fixed_question": "Até que ponto esta afirmação descreve você?",
    "scale_labels": [
      "Completamente falso, isto é, não tem absolutamente nada a ver com o que acontece comigo",
      "Falso na maioria das vezes, isto é, não tem quase nada a ver com o que acontece comigo",
      "Um pouco mais verdadeiro do que falso, isto é, tem um pouco a ver com o que acontece comigo",
      "Moderadamente verdadeiro, isto é, tem moderadamente a ver com o que acontece comigo",
      "Verdadeiro na maioria das vezes, isto é, tem muito a ver com o que acontece comigo",
      "Descreve-me perfeitamente"
    ],
    "follow_up": "Suas respostas ficarão disponíveis para seu psicólogo e poderão contribuir para a compreensão dos seus padrões de enfrentamento ao longo do processo terapêutico."
  }$json$::jsonb
WHERE code = 'YCI_FOUNDATION_V1';

-- ── YRAI (mesmo "Como responder", pergunta e escala do YCI, a pedido da Guacira;
--    apresentação e descrição seguem as atuais até as clientes enviarem os textos)
UPDATE public.questionnaires SET
  patient_content = (
    SELECT jsonb_build_object(
      'how_to_respond', patient_content->'how_to_respond',
      'fixed_question', patient_content->'fixed_question',
      'scale_labels', patient_content->'scale_labels'
    )
    FROM public.questionnaires WHERE code = 'YCI_FOUNDATION_V1'
  )
WHERE code = 'YRAI_FOUNDATION_V1';

-- ── YAMI ─────────────────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  description = 'Este questionário ajuda a identificar diferentes estados emocionais e maneiras de pensar e agir que podem surgir em determinadas situações.',
  patient_content = $json${
    "intro": "Antes de começar, leia as orientações com atenção. Suas respostas ajudarão você e seu psicólogo a compreender melhor suas experiências emocionais e seus padrões de comportamento.",
    "how_to_respond": "Leia cada afirmação com atenção e considere com que frequência você acreditou ou sentiu o que está descrito durante o último mês. Escolha uma das seis opções da escala, selecionando aquela que melhor corresponde à sua experiência.",
    "fixed_question": "Com que frequência você sentiu isso no último mês?",
    "scale_labels": [
      "Nunca ou quase nunca",
      "Raramente",
      "Às vezes",
      "Muitas vezes",
      "Grande parte do tempo",
      "Quase o tempo todo"
    ],
    "follow_up": "Suas respostas ficarão disponíveis para seu psicólogo e poderão contribuir para a compreensão dos seus padrões emocionais e de enfrentamento ao longo do processo terapêutico."
  }$json$::jsonb
WHERE code = 'YAMI_MODES_FOUNDATION_V1';

-- ── Estilos de Apego ─────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  description = 'Este questionário ajuda a compreender como você costuma vivenciar os vínculos afetivos, especialmente em relação à proximidade, à confiança e à segurança nos relacionamentos.',
  patient_content = $json${
    "intro": "Antes de começar, leia as orientações com atenção. Suas respostas ajudarão você e seu psicólogo a compreender melhor suas experiências nos relacionamentos.",
    "how_to_respond": "Leia cada afirmação com atenção e considere se ela descreve sua maneira habitual de se relacionar. Selecione 'Sim' quando a afirmação for verdadeira para você ou 'Não' quando não corresponder à sua experiência.",
    "fixed_question": "Esta afirmação descreve sua maneira de se relacionar?",
    "follow_up": "Suas respostas ficarão disponíveis para seu psicólogo e poderão contribuir para a compreensão de seus padrões de vínculo e relacionamento ao longo do processo terapêutico."
  }$json$::jsonb
WHERE code = 'ATTACHMENT_STYLES_V1';

-- ── Estilos Parentais ────────────────────────────────────────────────────────
UPDATE public.questionnaires SET
  patient_content = $json${
    "intro": "Antes de começar, conheça as orientações que vão ajudar você a responder ao questionário.",
    "how_to_respond_title": "Orientação para resposta",
    "how_to_respond": "Antes de começar, selecione as pessoas que exerceram o papel de pais ou cuidadores durante sua infância. Você responderá às mesmas afirmações para cada pessoa selecionada, considerando sua experiência com ela.",
    "reference_period_text": "Responda considerando como você percebia os comportamentos e as atitudes dessas figuras parentais durante sua infância."
  }$json$::jsonb
WHERE code = 'PARENTAL_STYLES_V1';

COMMIT;
