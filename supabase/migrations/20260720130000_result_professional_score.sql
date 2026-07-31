-- Armazena o score validado pelo psicólogo diretamente na linha de resultado
-- por categoria (sem depender do recálculo a partir dos itens individuais).
-- Usado pela régua consolidada (modo 'consolidated' no snapshot.regua).
ALTER TABLE public.questionnaire_results
  ADD COLUMN IF NOT EXISTS professional_average_score NUMERIC(12,4),
  ADD COLUMN IF NOT EXISTS professional_note          TEXT;
