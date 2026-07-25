import 'genogram_enums.dart';

/// Uma pessoa do genograma na visão da Tela 3 (Minha Família), com a camada
/// emocional. Lê `genogram_people`; o `clinicalComment` (staff-only) vem
/// mesclado de `genogram_person_notes`.
class GenogramPersonEntry {
  const GenogramPersonEntry({
    required this.id,
    required this.patientId,
    required this.fullName,
    this.relationshipToPatient,
    this.gender,
    this.birthYear,
    this.deathYear,
    this.isDeceased = false,
    this.isCaregiver,
    this.bondQuality,
    this.emotionalPresence,
    this.caregiverTraits = const [],
    this.caregiverTraitsOther,
    this.feltNeeds = const [],
    this.wishedNeeds = const [],
    this.linkedEvents = const [],
    this.linkedEventsOther,
    this.isSensitive = false,
    this.clinicalComment,
    this.filledByRole,
  });

  final String id;
  final String patientId;
  final String fullName;
  final String? relationshipToPatient;
  final String? gender; // male/female/other/unknown
  final int? birthYear;
  final int? deathYear;
  final bool isDeceased;

  // Camada emocional (Tela 3)
  final bool? isCaregiver;
  final BondQuality? bondQuality;
  final int? emotionalPresence; // 0–10
  final List<CaregiverTrait> caregiverTraits;
  final String? caregiverTraitsOther;
  final List<CaregiverNeed> feltNeeds;
  final List<CaregiverNeed> wishedNeeds;
  final List<LinkedEvent> linkedEvents;
  final String? linkedEventsOther;

  final bool isSensitive;

  /// Comentário clínico do terapeuta (staff-only).
  final String? clinicalComment;
  final String? filledByRole;

  /// Rótulo curto "Nome (Parentesco)".
  String get displayLabel {
    final rel = relationshipToPatient?.trim();
    if (rel != null && rel.isNotEmpty) return '$fullName ($rel)';
    return fullName;
  }

  factory GenogramPersonEntry.fromJson(Map<String, dynamic> json) {
    return GenogramPersonEntry(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      fullName: json['full_name'] as String,
      relationshipToPatient: json['relationship_to_patient'] as String?,
      gender: json['gender'] as String?,
      birthYear: (json['birth_year'] as num?)?.toInt(),
      deathYear: (json['death_year'] as num?)?.toInt(),
      isDeceased: json['is_deceased'] as bool? ?? false,
      isCaregiver: json['is_caregiver'] as bool?,
      bondQuality: BondQuality.fromKey(json['bond_quality'] as String?),
      emotionalPresence: (json['emotional_presence'] as num?)?.toInt(),
      caregiverTraits: parseKeys(
          json['caregiver_traits'], CaregiverTrait.values, (e) => e.key),
      caregiverTraitsOther: json['caregiver_traits_other'] as String?,
      feltNeeds:
          parseKeys(json['felt_needs'], CaregiverNeed.values, (e) => e.key),
      wishedNeeds:
          parseKeys(json['wished_needs'], CaregiverNeed.values, (e) => e.key),
      linkedEvents:
          parseKeys(json['linked_events'], LinkedEvent.values, (e) => e.key),
      linkedEventsOther: json['linked_events_other'] as String?,
      isSensitive: json['is_sensitive'] as bool? ?? false,
      filledByRole: json['filled_by_role'] as String?,
    );
  }

  GenogramPersonEntry copyWith({String? clinicalComment}) {
    return GenogramPersonEntry(
      id: id,
      patientId: patientId,
      fullName: fullName,
      relationshipToPatient: relationshipToPatient,
      gender: gender,
      birthYear: birthYear,
      deathYear: deathYear,
      isDeceased: isDeceased,
      isCaregiver: isCaregiver,
      bondQuality: bondQuality,
      emotionalPresence: emotionalPresence,
      caregiverTraits: caregiverTraits,
      caregiverTraitsOther: caregiverTraitsOther,
      feltNeeds: feltNeeds,
      wishedNeeds: wishedNeeds,
      linkedEvents: linkedEvents,
      linkedEventsOther: linkedEventsOther,
      isSensitive: isSensitive,
      clinicalComment: clinicalComment ?? this.clinicalComment,
      filledByRole: filledByRole,
    );
  }
}
