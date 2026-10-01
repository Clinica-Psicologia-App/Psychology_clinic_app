-- Adiciona sono, estresse e múltiplos modos ao check-in
-- problem_intensity_score e selected_mode mantidos para compatibilidade com dados antigos

ALTER TABLE public.patient_check_ins
  ADD COLUMN IF NOT EXISTS sleep_score    INTEGER,
  ADD COLUMN IF NOT EXISTS stress_score   INTEGER,
  ADD COLUMN IF NOT EXISTS selected_modes JSONB;
