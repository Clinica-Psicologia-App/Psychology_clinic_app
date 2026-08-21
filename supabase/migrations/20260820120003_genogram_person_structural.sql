-- Campos estruturais da pessoa no Genograma (etapa Conhecer, Tela 3, §20).
-- Só identificação/estrutura — a camada emocional da relação (vínculo,
-- necessidades, clima, padrões) vem em migração posterior.
--
-- gender e relationship_to_patient já existem em genogram_people.

-- Idade direta e aproximada (a spec pede "Idade ___ anos", com opções
-- "Não sei" / "Prefiro não informar"). birth_year continua existindo para
-- o cálculo de geração no gráfico.
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS age_approx SMALLINT;

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_age_approx_range
  CHECK (age_approx IS NULL OR (age_approx >= 0 AND age_approx <= 150));

-- "Essa pessoa é falecida?" — Sim / Não / Não sei (tri-estado).
-- is_deceased (bool) continua para compatibilidade; deceased_status é a
-- fonte do fluxo novo e distingue "não" de "não sei".
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS deceased_status TEXT;

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_deceased_status_valid
  CHECK (
    deceased_status IS NULL
    OR deceased_status IN ('yes', 'no', 'unknown')
  );

-- "Com que idade faleceu?" (alternativa a death_year, que já existe).
ALTER TABLE public.genogram_people
  ADD COLUMN IF NOT EXISTS death_age SMALLINT;

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_death_age_range
  CHECK (death_age IS NULL OR (death_age >= 0 AND death_age <= 150));
