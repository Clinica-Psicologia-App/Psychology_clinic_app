import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_gender.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person_input.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_input.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_type.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';

void main() {
  test('GenogramPerson.fromJson parses gender and years', () {
    final person = GenogramPerson.fromJson({
      'id': 'p1',
      'clinic_id': 'c1',
      'patient_id': 'pt1',
      'full_name': 'Maria Silva',
      'nickname': 'Mãe',
      'relationship_to_patient': 'Mãe',
      'gender': 'female',
      'birth_year': 1960,
      'death_year': null,
      'is_deceased': false,
      'is_sensitive': true,
      'created_at': '2026-05-01T12:00:00Z',
      'updated_at': '2026-05-01T12:00:00Z',
    });

    expect(person.displayName, contains('Maria Silva'));
    expect(person.gender?.label, 'Feminino');
    expect(person.isSensitive, isTrue);
  });

  test('GenogramPersonInput validates year range', () {
    expect(
      const GenogramPersonInput(
        fullName: 'João',
        birthYear: 1700,
      ).validate(),
      isNotNull,
    );
    expect(
      const GenogramPersonInput(
        fullName: 'João',
        birthYear: 1990,
        deathYear: 1980,
      ).validate(),
      isNotNull,
    );
    expect(
      const GenogramPersonInput(fullName: 'João', birthYear: 1990).validate(),
      isNull,
    );
  });

  test('GenogramRelationshipInput rejects same person', () {
    expect(
      const GenogramRelationshipInput(
        personAId: 'same',
        personBId: 'same',
        relationshipType: GenogramRelationshipType.sibling,
      ).validate(),
      isNotNull,
    );
    expect(
      const GenogramRelationshipInput(
        personAId: 'a',
        personBId: 'b',
        relationshipType: GenogramRelationshipType.spouse,
      ).validate(),
      isNull,
    );
  });

  test('GenogramRelationship.fromJson parses type', () {
    final rel = GenogramRelationship.fromJson({
      'id': 'r1',
      'clinic_id': 'c1',
      'patient_id': 'pt1',
      'person_a_id': 'a',
      'person_b_id': 'b',
      'relationship_type': 'parent_child',
      'is_sensitive': false,
      'created_at': '2026-05-01T12:00:00Z',
      'updated_at': '2026-05-01T12:00:00Z',
    });

    expect(rel.relationshipType, GenogramRelationshipType.parentChild);
    expect(rel.involvesPerson('a'), isTrue);
    expect(rel.otherPersonId('a'), 'b');
  });

  test('journey genogram available when empty', () {
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
    final genogram = steps.firstWhere((s) => s.id == JourneyStepId.genogram);
    expect(genogram.availability, JourneyStepAvailability.available);
  });

  test('journey genogram inProgress when has people', () {
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
      genogramPeopleCount: 2,
      genogramRelationshipCount: 1,
      checkInCount: 0,
      dailyMonitorCount: 0,
      hasYsqStructuredResult: false,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final genogram = steps.firstWhere((s) => s.id == JourneyStepId.genogram);
    expect(genogram.availability, JourneyStepAvailability.inProgress);
    expect(genogram.progressHint, contains('2 pessoa'));
  });
}
