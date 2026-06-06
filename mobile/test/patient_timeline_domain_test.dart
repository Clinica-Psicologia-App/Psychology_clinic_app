import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event_input.dart';

void main() {
  test('PatientTimelineEvent.fromJson parses fields', () {
    final event = PatientTimelineEvent.fromJson({
      'id': 'e1',
      'clinic_id': 'cl1',
      'patient_id': 'p1',
      'created_by': null,
      'title': 'Mudança de escola',
      'description': 'Período difícil',
      'event_date': '2010-03-15',
      'period_label': 'Infância',
      'category': 'Educação',
      'emotional_impact': 8,
      'is_sensitive': true,
      'created_at': '2026-05-01T12:00:00Z',
      'updated_at': '2026-05-01T12:00:00Z',
    });

    expect(event.title, 'Mudança de escola');
    expect(event.eventDate?.year, 2010);
    expect(event.emotionalImpact, 8);
    expect(event.isSensitive, isTrue);
    expect(event.dateLabel, contains('2010'));
  });

  test('PatientTimelineEventInput validates emotional impact', () {
    expect(
      const PatientTimelineEventInput(
        title: 'Teste',
        emotionalImpact: 11,
      ).validate(),
      isNotNull,
    );
    expect(
      const PatientTimelineEventInput(
        title: 'Teste',
        emotionalImpact: 5,
      ).validate(),
      isNull,
    );
  });

  test('sortTimelineEventsChronologically orders by date then created_at', () {
    final older = PatientTimelineEvent.fromJson({
      'id': '1',
      'clinic_id': 'c',
      'patient_id': 'p',
      'title': 'Antigo',
      'event_date': '2000-01-01',
      'is_sensitive': false,
      'created_at': '2026-01-01T10:00:00Z',
      'updated_at': '2026-01-01T10:00:00Z',
    });
    final newer = PatientTimelineEvent.fromJson({
      'id': '2',
      'clinic_id': 'c',
      'patient_id': 'p',
      'title': 'Recente',
      'event_date': '2020-06-01',
      'is_sensitive': false,
      'created_at': '2026-01-02T10:00:00Z',
      'updated_at': '2026-01-02T10:00:00Z',
    });
    final noDate = PatientTimelineEvent.fromJson({
      'id': '3',
      'clinic_id': 'c',
      'patient_id': 'p',
      'title': 'Sem data',
      'period_label': 'Adolescência',
      'is_sensitive': false,
      'created_at': '2026-05-01T10:00:00Z',
      'updated_at': '2026-05-01T10:00:00Z',
    });

    final sorted = sortTimelineEventsChronologically([older, noDate, newer]);
    expect(sorted.map((e) => e.id).toList(), ['2', '1', '3']);
  });

  test('compareTimelineEventsChronologically uses period when no dates', () {
    final a = PatientTimelineEvent.fromJson({
      'id': 'a',
      'clinic_id': 'c',
      'patient_id': 'p',
      'title': 'A',
      'period_label': '2020',
      'is_sensitive': false,
      'created_at': '2026-01-01T10:00:00Z',
      'updated_at': '2026-01-01T10:00:00Z',
    });
    final b = PatientTimelineEvent.fromJson({
      'id': 'b',
      'clinic_id': 'c',
      'patient_id': 'p',
      'title': 'B',
      'period_label': '2010',
      'is_sensitive': false,
      'created_at': '2026-01-01T11:00:00Z',
      'updated_at': '2026-01-01T11:00:00Z',
    });

    expect(compareTimelineEventsChronologically(a, b), lessThan(0));
  });

  test('journey timeline available when no events', () {
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
    final timeline = steps.firstWhere((s) => s.id == JourneyStepId.timeline);
    expect(timeline.availability, JourneyStepAvailability.available);
  });

  test('journey timeline inProgress when events exist', () {
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
      timelineEventCount: 3,
      genogramPeopleCount: 0,
      genogramRelationshipCount: 0,
      checkInCount: 0,
      dailyMonitorCount: 0,
      hasYsqStructuredResult: false,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final timeline = steps.firstWhere((s) => s.id == JourneyStepId.timeline);
    expect(timeline.availability, JourneyStepAvailability.inProgress);
    expect(timeline.progressHint, contains('3'));
  });
}
