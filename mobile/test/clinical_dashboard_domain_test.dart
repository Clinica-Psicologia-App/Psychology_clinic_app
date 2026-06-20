import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary_builder.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_builder.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_callouts.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_score_row.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_instrument_dashboard.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_parental_dashboard_builder.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/patient_check_in.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem_status.dart';
import 'package:terapia_esquema/features/results/domain/category_result.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/domain/questionnaire_response_status.dart';
import 'package:terapia_esquema/features/results/domain/result_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/scoring_schema_result.dart';
import 'package:terapia_esquema/features/results/domain/scoring_severity.dart';
import 'package:terapia_esquema/features/results/domain/scoring_snapshot.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal_status.dart';

void main() {
  test('latestStructuredResponse picks newest YSQ', () {
    final responses = [
      PatientResponseSummary(
        id: '1',
        questionnaireId: 'q',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2024, 1, 1),
        answerCount: 1,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: '2',
        questionnaireId: 'q',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 1, 1),
        answerCount: 1,
        hasResults: true,
        resultsCount: 1,
      ),
    ];

    final latest = latestStructuredResponse(responses, ysqInstrumentMarker);
    expect(latest?.id, '2');
  });

  test('latestStructuredResponseByCode picks attachment by exact code', () {
    final responses = [
      PatientResponseSummary(
        id: 'old-attachment',
        questionnaireId: 'q',
        questionnaireCode: 'ATTACHMENT_STYLES_V1',
        questionnaireName: 'Apego',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 1, 1),
        answerCount: 42,
        hasResults: true,
        resultsCount: 3,
      ),
      PatientResponseSummary(
        id: 'new-attachment',
        questionnaireId: 'q',
        questionnaireCode: 'ATTACHMENT_STYLES_V1',
        questionnaireName: 'Apego',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 2, 1),
        answerCount: 42,
        hasResults: true,
        resultsCount: 3,
      ),
    ];

    final latest = latestStructuredResponseByCode(
      responses,
      attachmentInstrumentCode,
    );
    expect(latest?.id, 'new-attachment');
  });

  test('latestStructuredResponseByCode picks YCI by exact code', () {
    final responses = [
      PatientResponseSummary(
        id: 'old-yci',
        questionnaireId: 'q',
        questionnaireCode: 'YCI_FOUNDATION_V1',
        questionnaireName: 'YCI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 1, 1),
        answerCount: 48,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'new-yci',
        questionnaireId: 'q',
        questionnaireCode: 'YCI_FOUNDATION_V1',
        questionnaireName: 'YCI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 2, 1),
        answerCount: 48,
        hasResults: true,
        resultsCount: 1,
      ),
    ];

    final latest = latestStructuredResponseByCode(
      responses,
      yciInstrumentCode,
    );
    expect(latest?.id, 'new-yci');
  });

  test('latestStructuredResponseByCode picks YRAI by exact code', () {
    final responses = [
      PatientResponseSummary(
        id: 'old-yrai',
        questionnaireId: 'q',
        questionnaireCode: 'YRAI_FOUNDATION_V1',
        questionnaireName: 'YRAI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 1, 1),
        answerCount: 40,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'new-yrai',
        questionnaireId: 'q',
        questionnaireCode: 'YRAI_FOUNDATION_V1',
        questionnaireName: 'YRAI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 2, 1),
        answerCount: 40,
        hasResults: true,
        resultsCount: 1,
      ),
    ];

    final latest = latestStructuredResponseByCode(
      responses,
      yraiInstrumentCode,
    );
    expect(latest?.id, 'new-yrai');
  });

  test('extractTopSchemaRows orders by score descending', () {
    final detail = const PatientResultDetail(
      id: 'r',
      patientId: 'p',
      questionnaireId: 'q',
      questionnaireCode: 'YSQ',
      questionnaireName: 'YSQ',
      status: QuestionnaireResponseStatus.completed,
      answers: [],
      categoryResults: [
        CategoryResult(
          id: 'c',
          snapshot: ResultSnapshot(
            version: ScoringSnapshot.demoVersion,
            scoring: ScoringSnapshot(
              schemas: [
                ScoringSchemaResult(
                  id: 'a',
                  code: 'A',
                  name: 'Alpha',
                  weightedScore: 3,
                ),
                ScoringSchemaResult(
                  id: 'b',
                  code: 'B',
                  name: 'Beta',
                  weightedScore: 8,
                  severity: ScoringSeverity(label: 'Alta'),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final rows = extractTopSchemaRows(detail, limit: 5);
    expect(rows.first.name, 'Beta');
    expect(rows.first.severityLabel, 'Alta');
    expect(rows.last.name, 'Alpha');
  });

  test(
      'buildStructuredHistory includes attachment, YCI and YRAI and sorts by completion date',
      () {
    final history = buildStructuredHistory([
      PatientResponseSummary(
        id: 'y',
        questionnaireId: 'q1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 6, 1),
        answerCount: 1,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'a',
        questionnaireId: 'q3',
        questionnaireCode: 'ATTACHMENT_STYLES_V1',
        questionnaireName: 'Apego',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 1),
        answerCount: 42,
        hasResults: true,
        resultsCount: 3,
      ),
      PatientResponseSummary(
        id: 'c',
        questionnaireId: 'q4',
        questionnaireCode: 'YCI_FOUNDATION_V1',
        questionnaireName: 'YCI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 15),
        answerCount: 48,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'r',
        questionnaireId: 'q5',
        questionnaireCode: 'YRAI_FOUNDATION_V1',
        questionnaireName: 'YRAI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 10),
        answerCount: 40,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'o',
        questionnaireId: 'q2',
        questionnaireCode: 'OTHER',
        questionnaireName: 'Outro',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 7, 1),
        answerCount: 1,
        hasResults: true,
        resultsCount: 1,
      ),
    ]);

    expect(history.length, 4);
    expect(
      history.map((entry) => entry.questionnaireCode),
      [
        'YSQ_FOUNDATION_V1',
        'YCI_FOUNDATION_V1',
        'YRAI_FOUNDATION_V1',
        'ATTACHMENT_STYLES_V1',
      ],
    );
  });

  test('ClinicalDashboardData.empty has no instrument results', () {
    expect(ClinicalDashboardData.empty.hasAnyInstrumentResult, isFalse);
    expect(ClinicalDashboardData.empty.hasCaseSummary, isFalse);
    expect(ClinicalDashboardData.empty.callouts, isEmpty);
  });

  test('patientHasStructuredDashboardResults accepts attachment results', () {
    final responses = [
      PatientResponseSummary(
        id: 'a1',
        questionnaireId: 'q1',
        questionnaireCode: 'ATTACHMENT_STYLES_V1',
        questionnaireName: 'Apego',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 6, 1),
        answerCount: 42,
        hasResults: true,
        resultsCount: 3,
      ),
    ];

    expect(patientHasStructuredDashboardResults(responses), isTrue);
  });

  test('patientHasStructuredDashboardResults accepts YCI results', () {
    final responses = [
      PatientResponseSummary(
        id: 'yci-1',
        questionnaireId: 'q1',
        questionnaireCode: 'YCI_FOUNDATION_V1',
        questionnaireName: 'YCI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 6, 1),
        answerCount: 48,
        hasResults: true,
        resultsCount: 1,
      ),
    ];

    expect(patientHasStructuredDashboardResults(responses), isTrue);
  });

  test('patientHasStructuredDashboardResults accepts YRAI results', () {
    final responses = [
      PatientResponseSummary(
        id: 'yrai-1',
        questionnaireId: 'q1',
        questionnaireCode: 'YRAI_FOUNDATION_V1',
        questionnaireName: 'YRAI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 6, 1),
        answerCount: 40,
        hasResults: true,
        resultsCount: 1,
      ),
    ];

    expect(patientHasStructuredDashboardResults(responses), isTrue);
  });

  test('buildClinicalCaseSummary aggregates current case data', () {
    final summary = buildClinicalCaseSummary(
      patientName: 'Maria Silva',
      responses: [
        PatientResponseSummary(
          id: 'r1',
          questionnaireId: 'q1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          status: QuestionnaireResponseStatus.completed,
          completedAt: DateTime(2025, 1, 10),
          answerCount: 90,
          hasResults: true,
          resultsCount: 1,
        ),
      ],
      ysq: const ClinicalInstrumentDashboard(
        responseId: 'r1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        topScores: [
          ClinicalDashboardScoreRow(name: 'Abandono', code: 'ABN', score: 5.4),
        ],
      ),
      yami: const ClinicalInstrumentDashboard(
        responseId: 'r2',
        questionnaireCode: 'YAMI_MODES_FOUNDATION_V1',
        questionnaireName: 'YAMI',
        topScores: [
          ClinicalDashboardScoreRow(
              name: 'Criança vulnerável', code: 'CV', score: 4.8),
          ClinicalDashboardScoreRow(name: 'Punitivo', code: 'PUN', score: 3.2),
          ClinicalDashboardScoreRow(name: 'Protetor', code: 'PRO', score: 2.1),
          ClinicalDashboardScoreRow(name: 'Extra', code: 'X', score: 1.0),
        ],
      ),
      attachment: const ClinicalInstrumentDashboard(
        responseId: 'r3',
        questionnaireCode: 'ATTACHMENT_STYLES_V1',
        questionnaireName: 'Apego',
        topScores: [
          ClinicalDashboardScoreRow(name: 'Ansioso', code: 'ANX', score: 0.8),
        ],
      ),
      yci: const ClinicalInstrumentDashboard(
        responseId: 'r4',
        questionnaireCode: 'YCI_FOUNDATION_V1',
        questionnaireName: 'YCI',
        topScores: [
          ClinicalDashboardScoreRow(name: 'YCI Geral', code: 'YCI', score: 4.1),
        ],
      ),
      yrai: null,
      problems: [
        PatientProblem(
          id: 'p1',
          clinicId: 'c',
          patientId: 'p',
          title: 'Medo de rejeição',
          intensity: 9,
          status: PatientProblemStatus.active,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 9),
        ),
      ],
      goals: [
        TherapyGoal(
          id: 'g1',
          clinicId: 'c',
          patientId: 'p',
          title: 'Fortalecer autonomia',
          status: TherapyGoalStatus.active,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 8),
        ),
      ],
      checkIns: [
        PatientCheckIn(
          id: 'ci1',
          clinicId: 'c',
          patientId: 'p',
          moodScore: 6,
          anxietyScore: 8,
          checkedInAt: DateTime(2025, 1, 11),
          createdAt: DateTime(2025, 1, 11),
          updatedAt: DateTime(2025, 1, 11),
        ),
      ],
      events: [
        PatientTimelineEvent(
          id: 'e1',
          clinicId: 'c',
          patientId: 'p',
          title: 'Mudança de trabalho',
          emotionalImpact: 9,
          isSensitive: false,
          createdAt: DateTime(2025, 1, 5),
          updatedAt: DateTime(2025, 1, 5),
        ),
      ],
    );

    expect(summary.structuredResultCount, 1);
    expect(summary.patientName, 'Maria Silva');
    expect(summary.openProblemsCount, 1);
    expect(summary.activeGoalsCount, 1);
    expect(summary.topSchemas.single.name, 'Abandono');
    expect(summary.topModes.length, 3);
    expect(summary.topModes.first.name, 'Criança vulnerável');
    expect(summary.topAttachment.single.name, 'Ansioso');
    expect(summary.topCoping.single.name, 'YCI Geral');
    expect(summary.latestClinicalUpdateAt, isNotNull);
    expect(summary.relevantEvents.single.title, 'Mudança de trabalho');
    expect(summary.hasSummary, isTrue);
  });

  test('buildClinicalCaseSummary falls back to empty state', () {
    final summary = buildClinicalCaseSummary(
      patientName: 'Paciente',
      responses: const [],
      ysq: null,
      yami: null,
      attachment: null,
      yci: null,
      yrai: null,
      problems: const [],
      goals: const [],
      checkIns: const [],
      events: const [],
    );

    expect(summary.isEmpty, isTrue);
  });

  test('buildClinicalDashboardCallouts suggests instruments and check-in', () {
    final callouts = buildClinicalDashboardCallouts(
      hasYsqResult: false,
      hasYamiResult: false,
      hasRecentCheckIn: false,
    );

    expect(callouts.length, 2);
    expect(callouts.first.kind, ClinicalDashboardCalloutKind.missingYsq);
    expect(
      callouts.last.kind,
      ClinicalDashboardCalloutKind.missingCheckIn,
    );
  });

  test('hasRecentCheckIn accepts check-ins within seven days', () {
    expect(
      hasRecentCheckIn(
        DateTime(2025, 1, 10),
        now: DateTime(2025, 1, 11),
      ),
      isTrue,
    );
    expect(
      hasRecentCheckIn(
        DateTime(2024, 12, 1),
        now: DateTime(2025, 1, 11),
      ),
      isFalse,
    );
  });

  test('buildParentalDashboard parses parental-context-v1 figures', () {
    final detail = PatientResultDetail(
      id: 'parental-1',
      patientId: 'p1',
      questionnaireId: 'q1',
      questionnaireCode: 'PARENTAL_STYLES_V1',
      questionnaireName: 'Estilos Parentais',
      status: QuestionnaireResponseStatus.completed,
      completedAt: DateTime(2025, 5, 20),
      answers: const [],
      categoryResults: [
        CategoryResult(
          id: 'c1',
          snapshot: ResultSnapshot.fromJson({
            'version': 'parental-context-v1',
            'contexts': [
              {
                'id': 'ctx-1',
                'key': 'mother',
                'label': 'Mãe',
                'status': 'completed',
                'answer_count': 72,
                'total_questions': 72,
                'schemas': [
                  {
                    'id': 's1',
                    'code': 'M_ABANDONO',
                    'name': 'Abandono - Mãe',
                    'weighted_score': 12,
                  },
                  {
                    'id': 's2',
                    'code': 'M_PERMISSIVO',
                    'name': 'Permissivo - Mãe',
                    'weighted_score': 8,
                  },
                ],
              },
              {
                'id': 'ctx-2',
                'key': 'father',
                'label': 'Pai',
                'status': 'completed',
                'answer_count': 72,
                'total_questions': 72,
                'schemas': [
                  {
                    'id': 's3',
                    'code': 'P_AUTORITARIO',
                    'name': 'Autoritário - Pai',
                    'weighted_score': 10,
                  },
                ],
              },
            ],
          }),
        ),
      ],
    );

    final dashboard = buildParentalDashboard(
      summary: PatientResponseSummary(
        id: 'parental-1',
        questionnaireId: 'q1',
        questionnaireCode: 'PARENTAL_STYLES_V1',
        questionnaireName: 'Estilos Parentais',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 20),
        answerCount: 144,
        hasResults: true,
        resultsCount: 1,
      ),
      detail: detail,
    );

    expect(dashboard, isNotNull);
    expect(dashboard!.figures.length, 2);
    expect(dashboard.figures.first.label, 'Mãe');
    expect(dashboard.figures.first.topScores.first.name, 'Abandono - Mãe');
    expect(dashboard.figures.last.label, 'Pai');
    expect(dashboard.hasContent, isTrue);
  });

  test('buildParentalDashboard returns null without contexts', () {
    final detail = const PatientResultDetail(
      id: 'parental-empty',
      patientId: 'p1',
      questionnaireId: 'q1',
      questionnaireCode: 'PARENTAL_STYLES_V1',
      questionnaireName: 'Estilos Parentais',
      status: QuestionnaireResponseStatus.completed,
      answers: [],
      categoryResults: [],
    );

    final dashboard = buildParentalDashboard(
      summary: PatientResponseSummary(
        id: 'parental-empty',
        questionnaireId: 'q1',
        questionnaireCode: 'PARENTAL_STYLES_V1',
        questionnaireName: 'Estilos Parentais',
        status: QuestionnaireResponseStatus.completed,
        answerCount: 0,
        hasResults: false,
        resultsCount: 0,
      ),
      detail: detail,
    );

    expect(dashboard, isNull);
  });

  test('journey dashboard inProgress when YSQ result exists', () {
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
      hasYsqStructuredResult: true,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final dash = steps.firstWhere((s) => s.id == JourneyStepId.results);
    expect(dash.availability, JourneyStepAvailability.inProgress);
    expect(dash.title, 'Dashboard clínico');
  });
}
