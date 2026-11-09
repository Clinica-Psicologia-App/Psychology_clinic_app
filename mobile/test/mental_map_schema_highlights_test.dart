import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_data.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map_builder.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_aggregator.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_questionnaire_block.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_score_highlight.dart';
import 'package:terapia_esquema/features/results/domain/scoring_domain_result.dart';
import 'package:terapia_esquema/features/results/domain/scoring_schema_result.dart';
import 'package:terapia_esquema/features/results/domain/scoring_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/domain/category_result.dart';
import 'package:terapia_esquema/features/results/domain/result_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/questionnaire_response_status.dart';

/// Resultado como o do YSQ: notas de domínio maiores que as de cada esquema.
PatientResultDetail _ysqLikeDetail() {
  return const PatientResultDetail(
    id: 'r1',
    patientId: 'p1',
    questionnaireId: 'q1',
    questionnaireCode: 'YSQ',
    questionnaireName: 'YSQ',
    status: QuestionnaireResponseStatus.completed,
    answers: [],
    categoryResults: [
      CategoryResult(
        id: 'cat1',
        categoryName: 'Geral',
        averageScore: 2,
        snapshot: ResultSnapshot(
          version: ScoringSnapshot.demoVersion,
          scoring: ScoringSnapshot(
            domains: [
              ScoringDomainResult(
                  id: 'd1',
                  code: 'DOM_DISCONNECTION',
                  name: 'Desconexão e rejeição',
                  weightedScore: 78),
              ScoringDomainResult(
                  id: 'd2',
                  code: 'DOM_OVERVIGILANCE',
                  name: 'Hipervigilância e inibição',
                  weightedScore: 65),
            ],
            schemas: [
              ScoringSchemaResult(
                  id: 's1',
                  code: 'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
                  name: 'Abandono/Instabilidade',
                  weightedScore: 4.2),
              ScoringSchemaResult(
                  id: 's2',
                  code: 'YSQ_SCHEMA_DEFECTIVENESS_SHAME',
                  name: 'Defectividade/Vergonha',
                  weightedScore: 3.9),
              ScoringSchemaResult(
                  id: 's3',
                  code: 'YSQ_SCHEMA_FAILURE',
                  name: 'Fracasso',
                  weightedScore: 3.1),
            ],
          ),
        ),
      ),
    ],
  );
}

void main() {
  test('sem schemasFirst, as notas de domínio ocupam as vagas (comportamento antigo)', () {
    final highlights = extractScoreHighlights(_ysqLikeDetail(), limit: 2);
    expect(highlights.map((h) => h.kind), ['domain', 'domain']);
  });

  test('com schemasFirst, os esquemas vêm antes dos domínios', () {
    final highlights =
        extractScoreHighlights(_ysqLikeDetail(), limit: 5, schemasFirst: true);
    expect(highlights.map((h) => h.kind),
        ['schema', 'schema', 'schema', 'domain', 'domain']);
    expect(highlights.first.name, 'Abandono/Instabilidade');
    expect(highlights.first.code, 'YSQ_SCHEMA_ABANDONMENT_INSTABILITY');
  });

  test('o bloco do mapa guarda os esquemas mesmo com domínios mais altos', () {
    final block = blockWithHighlights(
      const MentalMapQuestionnaireBlock(
        responseId: 'r1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        highlights: [],
      ),
      _ysqLikeDetail(),
      limit: 3,
    );
    expect(block.highlights.map((h) => h.kind), everyElement('schema'));
  });

  test('o nó Esquemas lista até 5 esquemas, cada um com o seu código', () {
    final map = buildMentalCaseMap(
      patientName: 'Teste',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'ysq',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          highlights: [
            MentalMapScoreHighlight(
                name: 'Abandono/Instabilidade',
                code: 'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
                kind: 'schema',
                score: 4.2),
            MentalMapScoreHighlight(
                name: 'Defectividade/Vergonha',
                code: 'YSQ_SCHEMA_DEFECTIVENESS_SHAME',
                kind: 'schema',
                score: 3.9),
            MentalMapScoreHighlight(
                name: 'Fracasso',
                code: 'YSQ_SCHEMA_FAILURE',
                kind: 'schema',
                score: 3.5),
            MentalMapScoreHighlight(
                name: 'Autossacrifício',
                code: 'YSQ_SCHEMA_SELF_SACRIFICE',
                kind: 'schema',
                score: 3.3),
            MentalMapScoreHighlight(
                name: 'Inibição emocional',
                code: 'YSQ_SCHEMA_EMOTIONAL_INHIBITION',
                kind: 'schema',
                score: 3.1),
            MentalMapScoreHighlight(
                name: 'Subjugação',
                code: 'YSQ_SCHEMA_SUBJUGATION',
                kind: 'schema',
                score: 2.9),
          ],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final node = map.primaryNodes.firstWhere((n) => n.id == 'schemas');
    expect(node.items.length, 5);
    expect(node.itemKeys, [
      'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
      'YSQ_SCHEMA_DEFECTIVENESS_SHAME',
      'YSQ_SCHEMA_FAILURE',
      'YSQ_SCHEMA_SELF_SACRIFICE',
      'YSQ_SCHEMA_EMOTIONAL_INHIBITION',
    ]);
  });
}
