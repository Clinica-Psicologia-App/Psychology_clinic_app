ALTER TABLE public.questionnaire_responses
  ADD COLUMN reviewed_at TIMESTAMPTZ,
  ADD COLUMN reviewed_by_profile_id UUID REFERENCES public.profiles (id) ON DELETE SET NULL,
  ADD COLUMN review_notes TEXT;

COMMENT ON COLUMN public.questionnaire_responses.reviewed_at IS
  'Quando a resposta foi revisada clinicamente pela equipe.';

COMMENT ON COLUMN public.questionnaire_responses.reviewed_by_profile_id IS
  'Perfil da equipe que registrou a revisão clínica.';

COMMENT ON COLUMN public.questionnaire_responses.review_notes IS
  'Observação curta opcional da revisão clínica.';

CREATE INDEX idx_questionnaire_responses_reviewed_at
  ON public.questionnaire_responses (reviewed_at);

CREATE INDEX idx_questionnaire_responses_reviewed_by
  ON public.questionnaire_responses (reviewed_by_profile_id);
