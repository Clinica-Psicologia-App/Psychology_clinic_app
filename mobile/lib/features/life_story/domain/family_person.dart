import 'genogram_relationship_enums.dart';
import 'life_story_enums.dart';

/// Gênero para a representação gráfica do genograma (spec §20).
enum PersonGender { male, female, other, unknown }

extension PersonGenderMeta on PersonGender {
  String get key => switch (this) {
        PersonGender.male => 'male',
        PersonGender.female => 'female',
        PersonGender.other => 'other',
        PersonGender.unknown => 'unknown',
      };
  String get label => switch (this) {
        PersonGender.male => 'Masculino',
        PersonGender.female => 'Feminino',
        PersonGender.other => 'Outro',
        PersonGender.unknown => 'Não informar',
      };
}

const kPersonGendersInOrder = PersonGender.values;

PersonGender? personGenderFromKey(String? key) {
  for (final g in PersonGender.values) {
    if (g.key == key) return g;
  }
  return null;
}

/// "Essa pessoa é falecida?" — Sim / Não / Não sei (spec §20).
enum DeceasedStatus { yes, no, unknown }

extension DeceasedStatusMeta on DeceasedStatus {
  String get key => switch (this) {
        DeceasedStatus.yes => 'yes',
        DeceasedStatus.no => 'no',
        DeceasedStatus.unknown => 'unknown',
      };
  String get label => switch (this) {
        DeceasedStatus.yes => 'Sim',
        DeceasedStatus.no => 'Não',
        DeceasedStatus.unknown => 'Não sei',
      };
}

const kDeceasedStatusInOrder = DeceasedStatus.values;

DeceasedStatus? deceasedStatusFromKey(String? key) {
  for (final d in DeceasedStatus.values) {
    if (d.key == key) return d;
  }
  return null;
}

/// Pessoa do Genograma (Tela 3, "Minha Família").
/// Mesmo registro (`genogram_people`) usado pela Linha do Tempo.
///
/// Núcleo estrutural (identificação) + camada emocional da relação
/// (aprofundada depois). As Etapas 5 e 6 da spec são retiradas.
class FamilyPerson {
  const FamilyPerson({
    required this.id,
    required this.fullName,
    this.role,
    this.gender,
    this.ageApprox,
    this.deceasedStatus,
    this.deathAge,
    this.eventCount = 0,
    // Relação
    this.caregiverRole,
    this.closeness,
    this.conflict,
    this.bondType,
    this.bondChangeNote,
    this.feltInRelationship = const [],
    this.receivedNeeds = const [],
    this.wishedMoreNeeds = const [],
    this.gotWhatNeeded = false,
    this.currentRelationship,
    this.currentRelationshipNote,
  });

  final String id;
  final String fullName;
  final RelationshipRole? role;
  final PersonGender? gender;
  final int? ageApprox;
  final DeceasedStatus? deceasedStatus;
  final int? deathAge;

  /// Em quantos acontecimentos da Linha do Tempo essa pessoa aparece (§19).
  final int eventCount;

  // ── Camada emocional da relação ──────────────────────────────────────────
  final CaregiverRole? caregiverRole; // §22
  final int? closeness; // §23
  final int? conflict; // §23
  final BondType? bondType; // §23
  final String? bondChangeNote; // §23
  final List<FeltInRelationship> feltInRelationship; // §26
  final List<RelationalNeed> receivedNeeds; // §27
  final List<RelationalNeed> wishedMoreNeeds; // §28
  final bool gotWhatNeeded; // §28 — "Sinto que recebi o que precisava"
  final CurrentRelationship? currentRelationship; // §29
  final String? currentRelationshipNote; // §29

  bool get isDeceased => deceasedStatus == DeceasedStatus.yes;

  bool get hasRelationshipData =>
      caregiverRole != null ||
      closeness != null ||
      bondType != null ||
      feltInRelationship.isNotEmpty ||
      receivedNeeds.isNotEmpty ||
      currentRelationship != null;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory FamilyPerson.fromJson(Map<String, dynamic> json) {
    List<T> mapKeys<T>(String col, T? Function(String?) from) => [
          for (final k in (json[col] as List?) ?? const [])
            if (from(k as String?) case final v?) v,
        ];
    final wishedRaw =
        ((json['wished_more_needs'] as List?) ?? const []).cast<String?>();

    return FamilyPerson(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: relationshipRoleFromKey(json['relationship_to_patient'] as String?),
      gender: personGenderFromKey(json['gender'] as String?),
      ageApprox: (json['age_approx'] as num?)?.toInt(),
      deceasedStatus: deceasedStatusFromKey(json['deceased_status'] as String?),
      deathAge: (json['death_age'] as num?)?.toInt(),
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
      caregiverRole: caregiverRoleFromKey(json['caregiver_role'] as String?),
      closeness: (json['closeness'] as num?)?.toInt(),
      conflict: (json['conflict'] as num?)?.toInt(),
      bondType: bondTypeFromKey(json['bond_type'] as String?),
      bondChangeNote: json['bond_change_note'] as String?,
      feltInRelationship:
          mapKeys('felt_in_relationship', feltInRelationshipFromKey),
      receivedNeeds: mapKeys('received_needs', relationalNeedFromKey),
      wishedMoreNeeds: [
        for (final k in wishedRaw)
          if (k != 'got_what_needed')
            if (relationalNeedFromKey(k) case final v?) v,
      ],
      gotWhatNeeded: wishedRaw.contains('got_what_needed'),
      currentRelationship:
          currentRelationshipFromKey(json['current_relationship'] as String?),
      currentRelationshipNote: json['current_relationship_note'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'full_name': fullName.trim(),
        'relationship_to_patient': role?.key,
        'gender': gender?.key,
        'age_approx': ageApprox,
        'deceased_status': deceasedStatus?.key,
        'is_deceased': deceasedStatus == DeceasedStatus.yes,
        'death_age': deathAge,
        // Relação
        'caregiver_role': caregiverRole?.key,
        'closeness': closeness,
        'conflict': conflict,
        'bond_type': bondType?.key,
        'bond_change_note': bondChangeNote,
        'felt_in_relationship':
            feltInRelationship.map((f) => f.key).toList(),
        'received_needs': receivedNeeds.map((n) => n.key).toList(),
        'wished_more_needs': [
          ...wishedMoreNeeds.map((n) => n.key),
          if (gotWhatNeeded) 'got_what_needed',
        ],
        'current_relationship': currentRelationship?.key,
        'current_relationship_note': currentRelationshipNote,
      };
}
