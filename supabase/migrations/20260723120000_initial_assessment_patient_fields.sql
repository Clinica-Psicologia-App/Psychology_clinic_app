-- =============================================================================
-- Fluxo "Conhecer" — Bloco 1 (Conhecendo Você)
-- Campos preenchidos pelo paciente (ou pelo terapeuta em nome dele).
-- Ficam em public.patients porque são visíveis ao paciente (mesma lente).
-- Idade = birth_date (já existe); Filhos = has_children (já existe).
-- =============================================================================

ALTER TABLE public.patients
  ADD COLUMN preferred_name        TEXT,    -- "Como prefere ser chamado"
  ADD COLUMN lives_with            TEXT,    -- "Com quem mora"
  ADD COLUMN uses_medication       BOOLEAN, -- "Uso de medicação"
  ADD COLUMN medication_notes      TEXT,    -- detalhamento opcional da medicação
  ADD COLUMN psychiatric_followup  BOOLEAN, -- "Acompanhamento psiquiátrico"
  ADD COLUMN psychiatrist_notes    TEXT,    -- detalhamento opcional do acompanhamento
  ADD COLUMN important_to_know     TEXT;    -- "Algo importante que gostaria que seu terapeuta soubesse?"

COMMENT ON COLUMN public.patients.preferred_name IS
  'Bloco 1 (Conhecer): como o paciente prefere ser chamado.';
COMMENT ON COLUMN public.patients.lives_with IS
  'Bloco 1 (Conhecer): com quem o paciente mora.';
COMMENT ON COLUMN public.patients.uses_medication IS
  'Bloco 1 (Conhecer): faz uso de medicação.';
COMMENT ON COLUMN public.patients.psychiatric_followup IS
  'Bloco 1 (Conhecer): possui acompanhamento psiquiátrico.';
COMMENT ON COLUMN public.patients.important_to_know IS
  'Bloco 1 (Conhecer): algo importante que o paciente quer que o terapeuta saiba.';
