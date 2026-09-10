-- Adiciona campos de adoecimento e perda gestacional na tabela genogram_people.
-- illness_type: 'physical' | 'mental' | 'both' — marca símbolo com meia-tinta.
-- pregnancy_loss_type: 'miscarriage' | 'stillbirth' | 'abortion' — símbolo triângulo.

alter table genogram_people
  add column if not exists illness_type        text check (illness_type in ('physical', 'mental', 'both')),
  add column if not exists pregnancy_loss_type text check (pregnancy_loss_type in ('miscarriage', 'stillbirth', 'abortion'));

comment on column genogram_people.illness_type        is 'Tipo de adoecimento para exibir meia-tinta no símbolo: physical, mental ou both.';
comment on column genogram_people.pregnancy_loss_type is 'Perda gestacional: miscarriage (aborto), stillbirth (natimorto) ou abortion (interrupção voluntária). Exibe triângulo no genograma.';
