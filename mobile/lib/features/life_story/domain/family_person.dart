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

/// Pessoa do Genograma (Tela 3, "Minha Família") — identificação e estrutura.
/// Mesmo registro (`genogram_people`) usado pela Linha do Tempo.
///
/// A camada emocional da relação (vínculo, necessidades, clima) entra depois;
/// esta classe cobre o núcleo estrutural.
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

  bool get isDeceased => deceasedStatus == DeceasedStatus.yes;

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
    return FamilyPerson(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: relationshipRoleFromKey(json['relationship_to_patient'] as String?),
      gender: personGenderFromKey(json['gender'] as String?),
      ageApprox: (json['age_approx'] as num?)?.toInt(),
      deceasedStatus: deceasedStatusFromKey(json['deceased_status'] as String?),
      deathAge: (json['death_age'] as num?)?.toInt(),
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
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
      };
}
