-- Adiciona emoções do humor e modo de esquema ao check-in do paciente.

ALTER TABLE public.patient_check_ins
  ADD COLUMN mood_emotions JSONB NOT NULL DEFAULT '[]',
  ADD COLUMN selected_mode JSONB;

COMMENT ON COLUMN public.patient_check_ins.mood_emotions IS
  'Lista de emoções selecionadas pelo paciente para a faixa de humor (ex: ["Triste","Solitário(a)"]).';

COMMENT ON COLUMN public.patient_check_ins.selected_mode IS
  'Modo de esquema registrado: {family, clinical_name, patient_label, nickname?}.';
