-- =============================================================================
-- Migration 007: triggers updated_at e preparação RLS (sem policies)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Triggers updated_at
-- -----------------------------------------------------------------------------

CREATE TRIGGER trg_clinics_set_updated_at
  BEFORE UPDATE ON public.clinics
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_patients_set_updated_at
  BEFORE UPDATE ON public.patients
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_questionnaires_set_updated_at
  BEFORE UPDATE ON public.questionnaires
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_question_categories_set_updated_at
  BEFORE UPDATE ON public.question_categories
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_questions_set_updated_at
  BEFORE UPDATE ON public.questions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_questionnaire_responses_set_updated_at
  BEFORE UPDATE ON public.questionnaire_responses
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_questionnaire_answers_set_updated_at
  BEFORE UPDATE ON public.questionnaire_answers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_therapy_resources_set_updated_at
  BEFORE UPDATE ON public.therapy_resources
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TRIGGER trg_daily_monitors_set_updated_at
  BEFORE UPDATE ON public.daily_monitors
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Row Level Security — habilitado, policies definidas em etapa futura
-- Com RLS ativo e sem policy, apenas service_role bypassa (comportamento esperado).
-- -----------------------------------------------------------------------------

ALTER TABLE public.clinics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questionnaires ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.question_category_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questionnaire_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questionnaire_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.questionnaire_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.therapy_resources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_resource_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_monitors ENABLE ROW LEVEL SECURITY;
