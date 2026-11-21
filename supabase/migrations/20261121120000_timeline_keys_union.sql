-- =============================================================================
-- Linha do Tempo: aceitar a UNIÃO dos vocabulários (paciente + psicóloga) em
-- emotional_need_keys e present_area_keys.
--
-- Causa: as CHECK de 20260820120002 só aceitam o vocabulário do formulário da
-- paciente; o formulário da psicóloga grava 6 chaves de necessidade e 3 de área
-- que o banco recusava ("Não conseguimos concluir a operação").
--
-- Só AMPLIA as duas CHECK: todo dado existente continua válido. Não altera
-- dados, colunas, índices, triggers nem RLS. coping_keys não tem CHECK e segue
-- assim. DROP+ADD na mesma transação (não existe janela sem CHECK).
--
-- ROLLBACK (executar só se a consulta abaixo retornar 0; senão manter a união):
--   SELECT count(*) FROM public.patient_timeline_events
--    WHERE emotional_need_keys && ARRAY['connection_acceptance',
--            'autonomy_competence_identity','limits_self_control',
--            'expression_freedom','recognition_value','spontaneity_leisure']
--       OR present_area_keys && ARRAY['self_esteem','decisions','body'];
--   -- depois: reaplicar as CHECK originais de 20260820120002_timeline_deepen_fields
--   --   (emotional_need_keys: 12 chaves da paciente; present_area_keys: 8).
-- =============================================================================

BEGIN;

ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_emotional_need_keys_valid;
ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_emotional_need_keys_valid
  CHECK (
    emotional_need_keys <@ ARRAY[
      -- vocabulário da paciente
      'presence', 'safety', 'affection', 'understanding', 'acceptance',
      'expression', 'autonomy', 'encouragement', 'limits', 'play',
      'dont_know', 'other',
      -- vocabulário da psicóloga
      'connection_acceptance', 'autonomy_competence_identity',
      'limits_self_control', 'expression_freedom', 'recognition_value',
      'spontaneity_leisure'
    ]::text[]
  );

ALTER TABLE public.patient_timeline_events
  DROP CONSTRAINT IF EXISTS patient_timeline_events_present_area_keys_valid;
ALTER TABLE public.patient_timeline_events
  ADD CONSTRAINT patient_timeline_events_present_area_keys_valid
  CHECK (
    present_area_keys <@ ARRAY[
      -- vocabulário da paciente
      'self_view', 'relationships', 'family', 'emotions', 'work', 'choices',
      'coping', 'other',
      -- vocabulário da psicóloga
      'self_esteem', 'decisions', 'body'
    ]::text[]
  );

COMMIT;
