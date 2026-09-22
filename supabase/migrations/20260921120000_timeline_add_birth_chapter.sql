-- Adiciona 'birth' ao CHECK constraint de life_chapter em patient_timeline_events.
--
-- O capítulo 'birth' representa eventos registrados antes de Minha Infância
-- (nascimento, gestação, histórico perinatal). A UI do fluxo Conhecer já exibe
-- essa opção; sem esta migração qualquer tentativa de salvar falha com violação
-- de constraint.

ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_life_chapter_valid;

ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_life_chapter_valid
  CHECK (
    life_chapter IS NULL
    OR life_chapter IN (
      'birth',          -- Nascimento / período perinatal
      'early_years',    -- Primeiros anos
      'childhood',      -- Infância
      'adolescence',    -- Adolescência
      'adulthood',      -- Vida adulta
      'today',          -- Momento atual
      'cannot_locate',  -- Não consigo localizar exatamente
      'maturity'        -- legado (não oferecido na UI nova)
    )
  );

COMMENT ON COLUMN public.patient_timeline_events.life_chapter IS
  'Capítulo da linha do tempo ao qual o evento pertence. '
  'Valores: birth, early_years, childhood, adolescence, adulthood, today, cannot_locate. '
  '''maturity'' mantido apenas para compatibilidade com dados legados.';
