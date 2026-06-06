import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_case_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_check_in_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_genogram_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_goal_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_monitor_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_problem_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_questionnaire_block.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_score_highlight.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_validation_summary.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/therapy_resource_recommendation_engine.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/patient_resource_access.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/resource_access_status.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/therapy_resource.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/therapy_resource_type.dart';

void main() {
  test('deriveResourceAccessStatus derives progress', () {
    expect(
      deriveResourceAccessStatus(isActive: true),
      ResourceAccessStatus.released,
    );
    expect(
      deriveResourceAccessStatus(
        isActive: true,
        viewedAt: DateTime.utc(2025, 5, 1),
      ),
      ResourceAccessStatus.viewed,
    );
    expect(
      deriveResourceAccessStatus(
        isActive: true,
        viewedAt: DateTime.utc(2025, 5, 1),
        completedAt: DateTime.utc(2025, 5, 2),
      ),
      ResourceAccessStatus.completed,
    );
  });

  test('TherapyResource.fromJson parses fields', () {
    final r = TherapyResource.fromJson({
      'id': 'r1',
      'title': 'Artigo teste',
      'type': 'article',
      'description': 'Desc',
      'url': 'https://example.com',
      'is_active': true,
    });

    expect(r.title, 'Artigo teste');
    expect(r.type, TherapyResourceType.article);
    expect(r.url, 'https://example.com');
  });

  test('PatientResourceAccess.fromJson parses dates and nested resource', () {
    final access = PatientResourceAccess.fromJson({
      'id': 'a1',
      'patient_id': 'p1',
      'resource_id': 'r1',
      'is_active': true,
      'released_at': '2025-05-20T10:00:00Z',
      'viewed_at': null,
      'completed_at': null,
      'resource': {
        'id': 'r1',
        'title': 'Recurso',
        'type': 'exercise',
        'is_active': true,
      },
    });

    expect(access.resource.title, 'Recurso');
    expect(access.progressStatus, ResourceAccessStatus.released);
    expect(access.releasedAt, isNotNull);
  });

  test('PatientResourceAccess fallback when viewed/completed missing', () {
    final access = PatientResourceAccess.fromJson({
      'id': 'a2',
      'patient_id': 'p1',
      'resource_id': 'r1',
      'is_active': false,
      'resource': {
        'id': 'r1',
        'title': 'X',
        'type': 'other',
        'is_active': true,
      },
    });

    expect(access.isActive, isFalse);
    expect(access.viewedAt, isNull);
    expect(access.completedAt, isNull);
  });

  test('buildTherapyResourceRecommendations suggests matching resources', () {
    final mentalMap = MentalMapData(
      patientName: 'Paciente teste',
      caseSummary: const MentalMapCaseSummary(
        therapyDemands: 'Regular ansiedade e entender padrões de esquema.',
        centralHypotheses: ['Abandono'],
        currentFocuses: ['Crises de ansiedade'],
      ),
      validationSummary: MentalMapValidationSummary.empty,
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'att-1',
          questionnaireCode: 'ATTACHMENT_STYLES_V1',
          questionnaireName: 'Apego',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Ansioso',
              code: 'ANSIOSO',
              kind: 'category',
              score: 8,
            ),
          ],
        ),
        MentalMapQuestionnaireBlock(
          responseId: 'par-1',
          questionnaireCode: 'PARENTAL_STYLES_V1',
          questionnaireName: 'Estilos Parentais',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Privação emocional',
              code: 'MOTHER_PRIVACAO_EMOCIONAL',
              kind: 'category',
              score: 7,
            ),
          ],
        ),
        MentalMapQuestionnaireBlock(
          responseId: 'yci-1',
          questionnaireCode: 'YCI_FOUNDATION_V1',
          questionnaireName: 'YCI',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Evitação',
              code: 'EVITACAO',
              kind: 'category',
              score: 6,
            ),
          ],
        ),
      ],
      activeProblems: const [
        MentalMapProblemSummary(
          id: 'prob-1',
          title: 'Crises de ansiedade',
          statusLabel: 'Ativo',
        ),
      ],
      activeGoals: const [
        MentalMapGoalSummary(
          id: 'goal-1',
          title: 'Fortalecer regulação emocional',
          statusLabel: 'Ativo',
        ),
      ],
      recentCheckIn: MentalMapCheckInSummary(
        id: 'c1',
        anxietyScore: 8,
        checkedInAt: DateTime.utc(2025, 6, 1),
      ),
      recentMonitors: [
        MentalMapMonitorSummary(
          id: 'm1',
          summaryLine: 'Ansiedade alta no trabalho',
          createdAt: DateTime.utc(2025, 6, 1),
        ),
      ],
      recentTimelineEvents: const [],
      genogram: MentalMapGenogramSummary.empty,
    );

    final library = const [
      TherapyResource(
        id: 'r1',
        title: 'Leitura: Introdução aos esquemas',
        type: TherapyResourceType.article,
        isActive: true,
      ),
      TherapyResource(
        id: 'r2',
        title: 'Exercício: Registro emocional guiado',
        type: TherapyResourceType.exercise,
        isActive: true,
      ),
      TherapyResource(
        id: 'r3',
        title: 'Vídeo: Ancoragem no presente (grounding)',
        type: TherapyResourceType.video,
        isActive: true,
      ),
    ];

    final recommendations = buildTherapyResourceRecommendations(
      mentalMap: mentalMap,
      library: library,
      assigned: const [],
    );

    expect(recommendations, hasLength(3));
    expect(
      recommendations.any((item) => item.resource.title.contains('esquemas')),
      isTrue,
    );
    expect(
      recommendations.any((item) => item.resource.title.contains('Registro')),
      isTrue,
    );
    expect(
      recommendations.any((item) => item.resource.title.contains('grounding')),
      isTrue,
    );
    final emotionalExercise = recommendations.firstWhere(
      (item) => item.resource.title.contains('Registro emocional'),
    );
    expect(
      emotionalExercise.reasons.any(
        (reason) => reason.contains('estilos de enfrentamento'),
      ),
      isTrue,
    );
  });
}
