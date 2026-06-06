import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/patient_check_in.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/patient_check_in_input.dart';

void main() {
  test('PatientCheckIn.fromJson parses scores', () {
    final checkIn = PatientCheckIn.fromJson({
      'id': 'c1',
      'clinic_id': 'cl1',
      'patient_id': 'p1',
      'created_by': null,
      'mood_score': 7,
      'anxiety_score': 3,
      'energy_score': 6,
      'problem_intensity_score': 4,
      'notes': 'Dia tranquilo',
      'checked_in_at': DateTime.now().toUtc().toIso8601String(),
      'created_at': '2026-05-01T12:00:00Z',
      'updated_at': '2026-05-01T12:00:00Z',
    });

    expect(checkIn.moodScore, 7);
    expect(checkIn.isToday, isTrue);
    expect(checkIn.summaryLine, contains('Humor 7'));
  });

  test('PatientCheckInInput validates score range', () {
    expect(
      const PatientCheckInInput(moodScore: 11).validate(),
      isNotNull,
    );
    expect(
      const PatientCheckInInput(moodScore: 5).validate(),
      isNull,
    );
  });

  test('PatientCheckInInput requires at least one field', () {
    expect(const PatientCheckInInput().validate(), isNotNull);
    expect(
      const PatientCheckInInput(notes: 'ok').validate(),
      isNull,
    );
  });

  test('journey check-in completed when has check-in today', () {
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
      hasCheckInToday: true,
      timelineEventCount: 0,
      genogramPeopleCount: 0,
      genogramRelationshipCount: 0,
      checkInCount: 0,
      dailyMonitorCount: 0,
      hasYsqStructuredResult: false,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final checkIn = steps.firstWhere((s) => s.id == JourneyStepId.checkIn);
    expect(checkIn.availability, JourneyStepAvailability.completed);
    expect(checkIn.progressHint, contains('hoje'));
  });

  test('journey check-in available when no check-in today', () {
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
    final checkIn = steps.firstWhere((s) => s.id == JourneyStepId.checkIn);
    expect(checkIn.availability, JourneyStepAvailability.available);
  });
}
