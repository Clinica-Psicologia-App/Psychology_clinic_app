-- =============================================================================
-- Conhecendo Você: texto livre "Conte sobre seus filhos (nomes e idades)".
-- Coluna nova e nula em public.patients; sem GRANT, sem policy nova (a RLS
-- atual da tabela já cobre colunas novas). A escrita pelo paciente passa pela
-- edge function update-patient-basics (lista branca).
--
-- ROLLBACK (manual; ordem importa):
--   1) Republicar update-patient-basics v22 (cópia em
--      esquemacore-fabrica/docs/rollback/update-patient-basics-v22/), que não
--      conhece children_notes.
--   2) Copiar antes os valores de children_notes se precisarem ser preservados.
--   3) ALTER TABLE public.patients DROP CONSTRAINT IF EXISTS patients_children_notes_length;
--   4) ALTER TABLE public.patients DROP COLUMN IF EXISTS children_notes;
-- =============================================================================

ALTER TABLE public.patients
  ADD COLUMN IF NOT EXISTS children_notes text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'patients_children_notes_length'
      AND conrelid = 'public.patients'::regclass
  ) THEN
    ALTER TABLE public.patients
      ADD CONSTRAINT patients_children_notes_length
      CHECK (children_notes IS NULL OR char_length(children_notes) <= 1000);
  END IF;
END
$$;

COMMENT ON COLUMN public.patients.children_notes IS
  'Conhecendo Você: texto livre do paciente sobre os filhos (nomes e idades), até 1000 caracteres. Complementa has_children; a função update-patient-basics zera quando has_children = false.';
