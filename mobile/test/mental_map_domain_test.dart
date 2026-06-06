import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_aggregator.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_case_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_genogram_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_goal_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_problem_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_questionnaire_block.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_score_highlight.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_validation_summary.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/results/domain/category_result.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/domain/questionnaire_response_status.dart';
import 'package:terapia_esquema/features/results/domain/result_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/scoring_schema_result.dart';
import 'package:terapia_esquema/features/results/domain/scoring_snapshot.dart';

void main() {
  test('buildQuestionnaireBlocks picks latest responses for core instruments',
      () {
    final responses = [
      PatientResponseSummary(
        id: 'old-ysq',
        questionnaireId: 'q1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2024, 1, 1),
        answerCount: 90,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'new-ysq',
        questionnaireId: 'q1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 6, 1),
        answerCount: 90,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'yami-1',
        questionnaireId: 'q2',
        questionnaireCode: 'YAMI_MODES',
        questionnaireName: 'YAMI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 1),
        answerCount: 20,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'attachment-1',
        questionnaireId: 'q3',
        questionnaireCode: 'ATTACHMENT_STYLES_V1',
        questionnaireName: 'Apego',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 2),
        answerCount: 42,
        hasResults: true,
        resultsCount: 3,
      ),
      PatientResponseSummary(
        id: 'parental-1',
        questionnaireId: 'q4',
        questionnaireCode: 'PARENTAL_STYLES_V1',
        questionnaireName: 'Parentais',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 3),
        answerCount: 36,
        hasResults: true,
        resultsCount: 2,
      ),
    ];

    final blocks = buildQuestionnaireBlocks(responses: responses);
    expect(blocks.length, 4);
    expect(blocks.any((b) => b.responseId == 'new-ysq'), isTrue);
    expect(blocks.any((b) => b.responseId == 'yami-1'), isTrue);
    expect(blocks.any((b) => b.responseId == 'attachment-1'), isTrue);
    expect(blocks.any((b) => b.responseId == 'parental-1'), isTrue);
  });

  test('extractScoreHighlights orders by score descending', () {
    final detail = _detailWithSchemas(
      PatientResultDetail(
        id: 'r1',
        patientId: 'p1',
        questionnaireId: 'q1',
        questionnaireCode: 'YSQ',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        answers: const [],
        categoryResults: const [],
      ),
    );

    final highlights = extractScoreHighlights(detail, limit: 3);
    expect(highlights.length, 2);
    expect(highlights.first.name, 'Alto');
    expect(highlights.last.name, 'Baixo');
  });

  test('mentalMapHasRelevantData false when all sections empty', () {
    expect(mentalMapHasRelevantData(MentalMapData.empty), isFalse);
  });

  test('mentalMapHasRelevantData true with active problem', () {
    const data = MentalMapData(
      patientName: 'Paciente teste',
      caseSummary: MentalMapCaseSummary.empty,
      validationSummary: MentalMapValidationSummary.empty,
      questionnaires: [],
      activeProblems: [
        MentalMapProblemSummary(
          id: '1',
          title: 'Ansiedade',
          statusLabel: 'Ativo',
        ),
      ],
      activeGoals: [],
      recentMonitors: [],
      recentTimelineEvents: [],
      genogram: MentalMapGenogramSummary.empty,
    );
    expect(mentalMapHasRelevantData(data), isTrue);
  });

  test('buildValidationSummary flags pending therapist review', () {
    final caseSummary = buildCaseSummary(
      patient: const Patient(
        id: 'p1',
        fullName: 'Paciente',
        responsiblePsychologistId: 'psy-1',
        intakeSummary: 'Sintese inicial.',
      ),
      questionnaires: const [],
      activeProblems: const [],
      activeGoals: const [],
    );

    final summary = buildValidationSummary(
      patient: const Patient(
        id: 'p1',
        fullName: 'Paciente',
        responsiblePsychologistId: 'psy-1',
        intakeSummary: 'Sintese inicial.',
      ),
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'r1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          requiresTherapistReview: true,
          highlights: [],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      caseSummary: caseSummary,
    );

    expect(summary.hasPendingReview, isTrue);
    expect(summary.title, 'Revisão clínica pendente');
  });

  test('buildCaseSummary merges intake, highlights, goals and problems', () {
    final summary = buildCaseSummary(
      patient: const Patient(
        id: 'p1',
        fullName: 'Paciente',
        responsiblePsychologistId: 'psy-1',
        intakeSummary: 'Histórico com ansiedade persistente.',
        currentLifeContext: 'Sobrecarga no trabalho e conflitos familiares.',
        therapyDemands: 'Regular ansiedade\nMelhorar limites',
      ),
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'r1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Abandono',
              code: 'ABANDONO',
              kind: 'schema',
              score: 5,
            ),
            MentalMapScoreHighlight(
              name: 'Privação emocional',
              code: 'PRIVACAO',
              kind: 'schema',
              score: 4,
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
          title: 'Fortalecer autonomia emocional',
          statusLabel: 'Ativo',
        ),
      ],
    );

    expect(summary.hasContent, isTrue);
    expect(summary.centralHypotheses, contains('Abandono'));
    expect(summary.currentFocuses, contains('Regular ansiedade'));
    expect(
      summary.currentFocuses,
      contains('Fortalecer autonomia emocional'),
    );
  });

  test('journey mental map available without clinical data', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 0,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 0,
      totalProblemCount: 0,
      openProblemCount: 0,
      hasCheckInToday: false,
      timelineEventCount: 0,
      genogramPeopleCount: 0,
      genogramRelationshipCount: 0,
      checkInCount: 0,
      dailyMonitorCount: 0,
      hasYsqStructuredResult: false,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final map = steps.firstWhere((s) => s.id == JourneyStepId.mentalMap);
    expect(map.availability, JourneyStepAvailability.available);
  });

  test('journey mental map inProgress with relevant data', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 1,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 0,
      totalProblemCount: 0,
      openProblemCount: 0,
      hasCheckInToday: false,
      timelineEventCount: 0,
      genogramPeopleCount: 0,
      genogramRelationshipCount: 0,
      checkInCount: 0,
      dailyMonitorCount: 0,
      hasYsqStructuredResult: false,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final map = steps.firstWhere((s) => s.id == JourneyStepId.mentalMap);
    expect(map.availability, JourneyStepAvailability.inProgress);
  });
}

PatientResultDetail _detailWithSchemas(PatientResultDetail base) {
  return PatientResultDetail(
    id: base.id,
    patientId: base.patientId,
    questionnaireId: base.questionnaireId,
    questionnaireCode: base.questionnaireCode,
    questionnaireName: base.questionnaireName,
    status: base.status,
    answers: base.answers,
    categoryResults: [
      CategoryResult(
        id: 'cat1',
        categoryName: 'Legado',
        averageScore: 2,
        snapshot: ResultSnapshot(
          version: ScoringSnapshot.demoVersion,
          scoring: const ScoringSnapshot(
            schemas: [
              ScoringSchemaResult(
                id: 's1',
                code: 'LOW',
                name: 'Baixo',
                weightedScore: 1,
              ),
              ScoringSchemaResult(
                id: 's2',
                code: 'HIGH',
                name: 'Alto',
                weightedScore: 9,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
