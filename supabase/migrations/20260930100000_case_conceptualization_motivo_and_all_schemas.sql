-- Seção 2: divide motivo_notes em dois campos separados (a. Inicialmente / b. Atualmente)
-- Seção 8.1: adiciona campo para listar todos os esquemas identificados antes de selecionar os centrais
ALTER TABLE case_conceptualizations
  ADD COLUMN IF NOT EXISTS motivo_initial TEXT,
  ADD COLUMN IF NOT EXISTS motivo_current TEXT,
  ADD COLUMN IF NOT EXISTS all_schemas    TEXT;

-- Migração de dados: copia motivo_notes para motivo_initial (campo legado → novo campo a.)
-- Mantém motivo_notes para não quebrar clientes antigos até próximo deploy.
UPDATE case_conceptualizations
SET motivo_initial = motivo_notes
WHERE motivo_notes IS NOT NULL
  AND motivo_initial IS NULL;
