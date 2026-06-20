import 'genogram_gender.dart';

class GenogramPerson {
  const GenogramPerson({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.createdBy,
    required this.fullName,
    this.nickname,
    this.relationshipToPatient,
    this.gender,
    this.birthYear,
    this.deathYear,
    required this.isDeceased,
    this.notes,
    required this.isSensitive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? createdBy;
  final String fullName;
  final String? nickname;
  final String? relationshipToPatient;
  final GenogramGender? gender;
  final int? birthYear;
  final int? deathYear;
  final bool isDeceased;
  final String? notes;
  final bool isSensitive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get displayName {
    if (nickname != null && nickname!.trim().isNotEmpty) {
      return '${fullName.trim()} (${nickname!.trim()})';
    }
    return fullName.trim();
  }

  String? get lifeSpanLabel {
    if (birthYear == null && deathYear == null) return null;
    if (birthYear != null && deathYear != null) {
      return '$birthYear - $deathYear';
    }
    if (birthYear != null) return 'Nasc. $birthYear';
    return 'Falec. $deathYear';
  }

  factory GenogramPerson.fromJson(Map<String, dynamic> json) {
    return GenogramPerson(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      createdBy: json['created_by'] as String?,
      fullName: json['full_name'] as String,
      nickname: json['nickname'] as String?,
      relationshipToPatient: json['relationship_to_patient'] as String?,
      gender: genogramGenderFromStorage(json['gender'] as String?),
      birthYear: json['birth_year'] as int?,
      deathYear: json['death_year'] as int?,
      isDeceased: json['is_deceased'] as bool? ?? false,
      notes: json['notes'] as String?,
      isSensitive: json['is_sensitive'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}
