-- =============================================================================
-- Plataforma Terapia do Esquema — MVP
-- Migration 001: extensões, tipos enumerados e função utilitária updated_at
-- =============================================================================

-- gen_random_uuid() (PostgreSQL 13+; habilitado por padrão no Supabase)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- -----------------------------------------------------------------------------
-- Enums de domínio
-- -----------------------------------------------------------------------------

CREATE TYPE public.profile_role AS ENUM (
  'admin',
  'psychologist',
  'patient'
);

COMMENT ON TYPE public.profile_role IS
  'Papel do usuário na clínica: admin, psychologist ou patient.';

CREATE TYPE public.questionnaire_response_status AS ENUM (
  'draft',
  'completed',
  'cancelled'
);

COMMENT ON TYPE public.questionnaire_response_status IS
  'Ciclo de vida de uma aplicação de questionário pelo paciente.';

CREATE TYPE public.question_answer_type AS ENUM (
  'likert_scale',
  'numeric_scale',
  'single_choice',
  'text'
);

COMMENT ON TYPE public.question_answer_type IS
  'Formato de resposta esperado para uma pergunta.';

CREATE TYPE public.therapy_resource_type AS ENUM (
  'article',
  'video',
  'exercise',
  'document',
  'link',
  'other'
);

COMMENT ON TYPE public.therapy_resource_type IS
  'Tipo de material terapêutico disponibilizado à clínica.';

-- -----------------------------------------------------------------------------
-- Função reutilizável para colunas updated_at
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = timezone('utc', now());
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.set_updated_at() IS
  'Trigger function: atualiza updated_at em UTC antes de UPDATE.';
