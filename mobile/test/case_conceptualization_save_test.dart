import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/data/case_conceptualization_repository.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';

void main() {
  // Colunas NOT NULL em case_conceptualizations (migrações 20260902120000,
  // 20260903120000 e 20260921130000).
  const notNull = [
    'unmet_needs',
    'mode_sequences',
    'therapeutic_relationship',
    'origins',
    'functioning',
    'life_problems',
    'central_schemas',
    'mode_assessment',
    'therapy_objectives',
  ];

  test('Síntese vazia nunca manda null em coluna NOT NULL', () {
    final cols = synthesisColumns(CaseConceptualization.empty());
    for (final k in notNull) {
      expect(cols.containsKey(k), isTrue, reason: k);
      expect(cols[k], isNotNull, reason: '$k violaria a constraint NOT NULL');
    }
    expect(cols['functioning'], isEmpty);
    expect(cols['life_problems'], isEmpty);
    expect(cols['mode_assessment'], isEmpty);
  });

  test('Síntese não grava os itens 2, 3 e 4 (são da tela Demandas)', () {
    final cols = synthesisColumns(CaseConceptualization.empty());
    for (final k in [
      'motivo_initial',
      'motivo_current',
      'general_impressions',
      'diagnosis',
    ]) {
      expect(cols.containsKey(k), isFalse, reason: k);
    }
  });

  test('seção preenchida continua sendo gravada', () {
    const c = CaseConceptualization(
      unmetNeeds: const [],
      modeSequences: const [],
      relationship: const TherapeuticRelationship(),
      lifeProblems: const TherapistLifeProblems(problem1: 'trabalho'),
      allSchemas: ' abandono ',
    );
    final cols = synthesisColumns(c);
    expect((cols['life_problems'] as Map)['problem1'], 'trabalho');
    expect(cols['all_schemas'], 'abandono');
  });
}
