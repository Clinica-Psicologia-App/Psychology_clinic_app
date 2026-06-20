import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';

void main() {
  test('buildPatientJourneySteps marks modules with correct base availability',
      () {
    final steps = buildPatientJourneySteps(null);
    expect(steps.length, 10);

    final byId = {for (final s in steps) s.id: s};

    expect(
      byId[JourneyStepId.questionnaires]!.availability,
      JourneyStepAvailability.available,
    );
    expect(
      byId[JourneyStepId.results]!.availability,
      JourneyStepAvailability.available,
    );
    expect(
      byId[JourneyStepId.therapyGoals]!.availability,
      JourneyStepAvailability.available,
    );
    expect(
      byId[JourneyStepId.genogram]!.availability,
      JourneyStepAvailability.available,
    );
    expect(steps.map((step) => step.order),
        orderedEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]));
    expect(byId[JourneyStepId.genogram]!.order, 2);
    expect(byId[JourneyStepId.timeline]!.order, 3);
    expect(byId[JourneyStepId.problems]!.order, 4);
    expect(byId[JourneyStepId.dailyMonitor]!.order, 7);
  });

  test('progress marks questionnaires completed when all active done', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 3,
      completedQuestionnaireCount: 3,
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
    final q = steps.firstWhere((s) => s.id == JourneyStepId.questionnaires);
    expect(q.availability, JourneyStepAvailability.completed);
  });

  test('questionnaires are blocked when none are available to patient', () {
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

    final step = buildPatientJourneySteps(progress)
        .firstWhere((item) => item.id == JourneyStepId.questionnaires);

    expect(step.availability, JourneyStepAvailability.blocked);
    expect(step.progressHint, contains('Nenhum instrumento'));
  });

  test('progress marks monitor completed when has record today', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 1,
      completedQuestionnaireCount: 0,
      hasMonitorToday: true,
      releasedResourceCount: 1,
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
    final monitor = steps.firstWhere((s) => s.id == JourneyStepId.dailyMonitor);
    expect(monitor.availability, JourneyStepAvailability.completed);
    expect(monitor.progressHint, contains('hoje'));
  });

  test('availability labels in Portuguese', () {
    expect(
      JourneyStepAvailability.available.label,
      'Disponível',
    );
    expect(
      JourneyStepAvailability.inDevelopment.label,
      'Em desenvolvimento',
    );
    expect(
      JourneyStepAvailability.completed.label,
      'Concluído',
    );
    expect(
      JourneyStepAvailability.blocked.label,
      'Bloqueado',
    );
  });

  test('JourneyStepId round-trips route key', () {
    expect(
      journeyStepIdFromRouteKey(JourneyStepId.mentalMap.routeKey),
      JourneyStepId.mentalMap,
    );
    expect(journeyStepIdFromRouteKey('invalid'), isNull);
  });

  test('therapy goals completed when only completed goals exist', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 0,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 2,
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
    final goals = steps.firstWhere((s) => s.id == JourneyStepId.therapyGoals);
    expect(goals.availability, JourneyStepAvailability.completed);
  });

  test('blocked and inDevelopment open placeholder', () {
    expect(JourneyStepAvailability.blocked.opensPlaceholder, isTrue);
    expect(JourneyStepAvailability.inDevelopment.opensPlaceholder, isTrue);
    expect(JourneyStepAvailability.available.isNavigableToModule, isTrue);
  });

  test('journey uses clinical labels aligned with scope', () {
    final steps = buildPatientJourneySteps(null);
    final byId = {for (final s in steps) s.id: s};

    expect(byId[JourneyStepId.timeline]!.title, 'Linha da vida');
    expect(byId[JourneyStepId.problems]!.title, 'Problemas e demandas');
    expect(byId[JourneyStepId.library]!.title, 'Biblioteca terapêutica');
    expect(
      byId[JourneyStepId.mentalMap]!.subtitle,
      contains('formulação clínica'),
    );
  });
}
