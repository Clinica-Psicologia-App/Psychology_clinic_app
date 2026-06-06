import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_builder.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/results/domain/category_result.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/domain/questionnaire_response_status.dart';
import 'package:terapia_esquema/features/results/domain/result_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/scoring_schema_result.dart';
import 'package:terapia_esquema/features/results/domain/scoring_severity.dart';
import 'package:terapia_esquema/features/results/domain/scoring_snapshot.dart';

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

  test('extractTopSchemaRows orders by score descending', () {
    final detail = PatientResultDetail(
      id: 'r',
      patientId: 'p',
      questionnaireId: 'q',
      questionnaireCode: 'YSQ',
      questionnaireName: 'YSQ',
      status: QuestionnaireResponseStatus.completed,
      answers: const [],
      categoryResults: [
        CategoryResult(
          id: 'c',
          snapshot: ResultSnapshot(
            version: ScoringSnapshot.demoVersion,
            scoring: const ScoringSnapshot(
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

  test('buildStructuredHistory filters YSQ and YAMI only', () {
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

    expect(history.length, 1);
    expect(history.first.questionnaireCode, contains('YSQ'));
  });

  test('ClinicalDashboardData.empty has no instrument results', () {
    expect(ClinicalDashboardData.empty.hasAnyInstrumentResult, isFalse);
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
