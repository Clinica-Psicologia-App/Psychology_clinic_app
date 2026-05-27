-- =============================================================================
-- Migration 008: validações entre tabelas (CHECK não suporta subquery no PostgreSQL)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- patients: profile e psicólogo devem pertencer à mesma clínica
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_patient_clinic_refs()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_profile_clinic UUID;
  v_psychologist_clinic UUID;
BEGIN
  IF NEW.profile_id IS NOT NULL THEN
    SELECT clinic_id INTO v_profile_clinic FROM public.profiles WHERE id = NEW.profile_id;
    IF v_profile_clinic IS NULL OR v_profile_clinic <> NEW.clinic_id THEN
      RAISE EXCEPTION 'profile_id deve pertencer à mesma clínica do paciente';
    END IF;
  END IF;

  IF NEW.responsible_psychologist_id IS NOT NULL THEN
    SELECT clinic_id INTO v_psychologist_clinic
    FROM public.profiles
    WHERE id = NEW.responsible_psychologist_id;

    IF v_psychologist_clinic IS NULL OR v_psychologist_clinic <> NEW.clinic_id THEN
      RAISE EXCEPTION 'responsible_psychologist_id deve pertencer à mesma clínica do paciente';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patients_validate_clinic_refs
  BEFORE INSERT OR UPDATE ON public.patients
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_patient_clinic_refs();

-- -----------------------------------------------------------------------------
-- question_category_items: pergunta e categoria do mesmo questionário
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_question_category_item_questionnaire()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_question_questionnaire UUID;
  v_category_questionnaire UUID;
BEGIN
  SELECT questionnaire_id INTO v_question_questionnaire
  FROM public.questions WHERE id = NEW.question_id;

  SELECT questionnaire_id INTO v_category_questionnaire
  FROM public.question_categories WHERE id = NEW.category_id;

  IF v_question_questionnaire IS NULL OR v_category_questionnaire IS NULL THEN
    RAISE EXCEPTION 'question_id ou category_id inválido';
  END IF;

  IF v_question_questionnaire <> v_category_questionnaire THEN
    RAISE EXCEPTION 'pergunta e categoria devem pertencer ao mesmo questionário';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_question_category_items_validate_questionnaire
  BEFORE INSERT OR UPDATE ON public.question_category_items
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_question_category_item_questionnaire();

-- -----------------------------------------------------------------------------
-- questionnaire_responses: paciente na mesma clínica
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_questionnaire_response_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id da resposta';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_questionnaire_responses_validate_clinic
  BEFORE INSERT OR UPDATE ON public.questionnaire_responses
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_questionnaire_response_clinic();

-- -----------------------------------------------------------------------------
-- questionnaire_answers: pergunta do mesmo questionário da response
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_questionnaire_answer_questionnaire()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_response_questionnaire UUID;
  v_question_questionnaire UUID;
BEGIN
  SELECT questionnaire_id INTO v_response_questionnaire
  FROM public.questionnaire_responses WHERE id = NEW.response_id;

  SELECT questionnaire_id INTO v_question_questionnaire
  FROM public.questions WHERE id = NEW.question_id;

  IF v_response_questionnaire IS NULL OR v_question_questionnaire IS NULL THEN
    RAISE EXCEPTION 'response_id ou question_id inválido';
  END IF;

  IF v_response_questionnaire <> v_question_questionnaire THEN
    RAISE EXCEPTION 'pergunta deve pertencer ao questionário da resposta';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_questionnaire_answers_validate_questionnaire
  BEFORE INSERT OR UPDATE ON public.questionnaire_answers
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_questionnaire_answer_questionnaire();

-- -----------------------------------------------------------------------------
-- questionnaire_results: coerência response / questionnaire / category
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_questionnaire_result_refs()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_response_questionnaire UUID;
  v_category_questionnaire UUID;
BEGIN
  SELECT questionnaire_id INTO v_response_questionnaire
  FROM public.questionnaire_responses WHERE id = NEW.response_id;

  SELECT questionnaire_id INTO v_category_questionnaire
  FROM public.question_categories WHERE id = NEW.category_id;

  IF v_response_questionnaire IS NULL THEN
    RAISE EXCEPTION 'response_id inválido';
  END IF;

  IF NEW.questionnaire_id <> v_response_questionnaire THEN
    RAISE EXCEPTION 'questionnaire_id deve coincidir com o da resposta';
  END IF;

  IF v_category_questionnaire IS NULL OR v_category_questionnaire <> NEW.questionnaire_id THEN
    RAISE EXCEPTION 'category_id deve pertencer ao mesmo questionário';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_questionnaire_results_validate_refs
  BEFORE INSERT OR UPDATE ON public.questionnaire_results
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_questionnaire_result_refs();

-- -----------------------------------------------------------------------------
-- patient_resource_access: paciente e recurso na mesma clínica
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_patient_resource_access_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
  v_resource_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;
  SELECT clinic_id INTO v_resource_clinic FROM public.therapy_resources WHERE id = NEW.resource_id;

  IF v_patient_clinic IS NULL OR v_resource_clinic IS NULL THEN
    RAISE EXCEPTION 'patient_id ou resource_id inválido';
  END IF;

  IF v_patient_clinic <> v_resource_clinic THEN
    RAISE EXCEPTION 'paciente e recurso devem pertencer à mesma clínica';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_patient_resource_access_validate_clinic
  BEFORE INSERT OR UPDATE ON public.patient_resource_access
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_patient_resource_access_clinic();

-- -----------------------------------------------------------------------------
-- daily_monitors: paciente na mesma clínica
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validate_daily_monitor_clinic()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  v_patient_clinic UUID;
BEGIN
  SELECT clinic_id INTO v_patient_clinic FROM public.patients WHERE id = NEW.patient_id;

  IF v_patient_clinic IS NULL OR v_patient_clinic <> NEW.clinic_id THEN
    RAISE EXCEPTION 'patient_id deve pertencer à clinic_id do monitor';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_daily_monitors_validate_clinic
  BEFORE INSERT OR UPDATE ON public.daily_monitors
  FOR EACH ROW
  EXECUTE FUNCTION public.validate_daily_monitor_clinic();
