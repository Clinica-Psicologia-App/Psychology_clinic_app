-- Genograma · Etapa 4 (casos avancados):
-- - adocao: flag no vinculo pai/mae-filho (desenho tracejado)
-- - gemeos: novo tipo de relacao 'twin' (linhas convergentes em Λ)

-- Adocao: so faz sentido em parent_child; default false nao afeta linhas atuais.
ALTER TABLE public.genogram_relationships
  ADD COLUMN IF NOT EXISTS is_adoptive BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.genogram_relationships.is_adoptive IS
  'So relevante em parent_child: filiacao adotiva (descida tracejada no genograma).';

-- Gemeos: adiciona 'twin' a lista permitida de relationship_type.
ALTER TABLE public.genogram_relationships
  DROP CONSTRAINT IF EXISTS genogram_relationships_type_valid;

ALTER TABLE public.genogram_relationships
  ADD CONSTRAINT genogram_relationships_type_valid
  CHECK (
    relationship_type IN (
      'parent_child',
      'spouse',
      'ex_spouse',
      'sibling',
      'twin',
      'conflict',
      'distant',
      'neutral',
      'close',
      'ruptured',
      'other'
    )
  );
