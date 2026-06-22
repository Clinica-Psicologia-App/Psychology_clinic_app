/// Campos editáveis de um paciente existente.
class UpdatePatientRequest {
  const UpdatePatientRequest({
    required this.patientId,
    this.fullName,
    this.phone,
    this.birthDate,
    this.gender,
    this.relationshipStatus,
    this.educationLevel,
    this.occupation,
    this.stateBirth,
    this.countryBirth,
    this.religiousOrientation,
    this.ethnicGroup,
    this.sexualOrientation,
    this.hasChildren,
    this.responsiblePsychologistId,
  });

  final String patientId;
  final String? fullName;
  final String? phone;
  final DateTime? birthDate;
  final String? gender;
  final String? relationshipStatus;
  final String? educationLevel;
  final String? occupation;
  final String? stateBirth;
  final String? countryBirth;
  final String? religiousOrientation;
  final String? ethnicGroup;
  final String? sexualOrientation;
  final bool? hasChildren;
  final String? responsiblePsychologistId;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fullName != null) map['full_name'] = fullName;
    if (phone != null) {
      map['phone'] = phone!.trim().isEmpty ? null : phone!.trim();
    }
    if (birthDate != null) {
      map['birth_date'] = birthDate!.toIso8601String().substring(0, 10);
    }
    if (gender != null) map['gender'] = gender;
    if (relationshipStatus != null) {
      map['relationship_status'] = relationshipStatus;
    }
    if (educationLevel != null) map['education_level'] = educationLevel;
    if (occupation != null) {
      map['occupation'] =
          occupation!.trim().isEmpty ? null : occupation!.trim();
    }
    if (stateBirth != null) {
      map['state_birth'] =
          stateBirth!.trim().isEmpty ? null : stateBirth!.trim();
    }
    if (countryBirth != null) {
      map['country_birth'] =
          countryBirth!.trim().isEmpty ? null : countryBirth!.trim();
    }
    if (religiousOrientation != null) {
      map['religious_orientation'] = religiousOrientation!.trim().isEmpty
          ? null
          : religiousOrientation!.trim();
    }
    if (ethnicGroup != null) {
      map['ethnic_group'] =
          ethnicGroup!.trim().isEmpty ? null : ethnicGroup!.trim();
    }
    if (sexualOrientation != null) {
      map['sexual_orientation'] = sexualOrientation;
    }
    if (hasChildren != null) map['has_children'] = hasChildren;
    if (responsiblePsychologistId != null) {
      map['responsible_psychologist_id'] = responsiblePsychologistId;
    }
    return map;
  }
}
