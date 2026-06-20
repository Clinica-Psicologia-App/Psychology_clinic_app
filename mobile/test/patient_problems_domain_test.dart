import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem_input.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem_status.dart';

void main() {
  test('PatientProblem.fromJson parses intensity and status', () {
    final problem = PatientProblem.fromJson({
      'id': 'p1',
      'clinic_id': 'c1',
      'patient_id': 'pt1',
      'created_by': null,
      'title': 'Ansiedade',
      'description': 'Em situações sociais',
      'category': 'Humor',
      'intensity': 7,
      'status': 'improved',
      'identified_at': '2026-01-10',
      'resolved_at': null,
      'created_at': '2026-05-01T12:00:00Z',
      'updated_at': '2026-05-01T12:00:00Z',
    });

    expect(problem.intensity, 7);
    expect(problem.status, PatientProblemStatus.improved);
    expect(problem.isOpen, isTrue);
  });

  test('patientProblemStatusFromStorage maps all values', () {
    expect(
      patientProblemStatusFromStorage('resolved'),
      PatientProblemStatus.resolved,
    );
    expect(
      patientProblemStatusFromStorage('archived'),
      PatientProblemStatus.archived,
    );
    expect(
      patientProblemStatusFromStorage('x'),
      PatientProblemStatus.active,
    );
  });

  test('PatientProblemInput validates intensity range', () {
    expect(
      const PatientProblemInput(title: 'T', intensity: 11).validate(),
      isNotNull,
    );
    expect(
      const PatientProblemInput(title: 'T', intensity: 5).validate(),
      isNull,
    );
  });

  test('journey problems inProgress when open problems exist', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 0,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 0,
      totalProblemCount: 2,
      openProblemCount: 1,
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
    final problems = steps.firstWhere((s) => s.id == JourneyStepId.problems);
    expect(problems.availability, JourneyStepAvailability.inProgress);
  });

  test('journey problems completed when all closed', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 0,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 0,
      totalProblemCount: 1,
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
    final problems = steps.firstWhere((s) => s.id == JourneyStepId.problems);
    expect(problems.availability, JourneyStepAvailability.completed);
  });

  test('journey problems available when none registered', () {
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
    final problems = steps.firstWhere((s) => s.id == JourneyStepId.problems);
    expect(problems.availability, JourneyStepAvailability.available);
  });
}
