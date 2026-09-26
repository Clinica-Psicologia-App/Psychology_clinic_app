-- Expande os valores válidos de felt_needs e wished_needs em genogram_people
-- para incluir 'guidance' (Orientação) e 'stability' (Previsibilidade e estabilidade).

ALTER TABLE public.genogram_people
  DROP CONSTRAINT IF EXISTS genogram_people_felt_needs_valid,
  DROP CONSTRAINT IF EXISTS genogram_people_wished_needs_valid;

ALTER TABLE public.genogram_people
  ADD CONSTRAINT genogram_people_felt_needs_valid
    CHECK (felt_needs IS NULL OR felt_needs <@ ARRAY[
      'safe', 'loved', 'accepted', 'understood', 'valued',
      'respected', 'free_to_be', 'encouraged', 'protected',
      'guidance', 'stability'
    ]::text[]),
  ADD CONSTRAINT genogram_people_wished_needs_valid
    CHECK (wished_needs IS NULL OR wished_needs <@ ARRAY[
      'safe', 'loved', 'accepted', 'understood', 'valued',
      'respected', 'free_to_be', 'encouraged', 'protected',
      'guidance', 'stability'
    ]::text[]);
