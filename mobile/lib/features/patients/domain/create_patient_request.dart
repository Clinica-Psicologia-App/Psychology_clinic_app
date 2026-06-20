/// Payload para `POST /create-patient`.
class CreatePatientRequest {
  const CreatePatientRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.responsiblePsychologistId,
    this.phone,
    this.cpf,
    this.birthDate,
    this.gender,
    this.relationshipStatus,
    this.educationLevel,
    this.occupation,
    this.countryBirth,
    this.stateBirth,
    this.religiousOrientation,
    this.ethnicGroup,
    this.sexualOrientation,
    this.hasChildren,
  });

  final String email;
  final String password;
  final String fullName;
  final String responsiblePsychologistId;
  final String? phone;
  final String? cpf;
  final DateTime? birthDate;
  final String? gender;
  final String? relationshipStatus;
  final String? educationLevel;
  final String? occupation;
  final String? countryBirth;
  final String? stateBirth;
  final String? religiousOrientation;
  final String? ethnicGroup;
  final String? sexualOrientation;
  final bool? hasChildren;

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName.trim(),
      'responsible_psychologist_id': responsiblePsychologistId,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (cpf != null && cpf!.trim().isNotEmpty) 'cpf': cpf!.trim(),
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().split('T').first,
      if (gender != null && gender!.trim().isNotEmpty) 'gender': gender!.trim(),
      if (relationshipStatus != null && relationshipStatus!.trim().isNotEmpty)
        'relationship_status': relationshipStatus!.trim(),
      if (educationLevel != null && educationLevel!.trim().isNotEmpty)
        'education_level': educationLevel!.trim(),
      if (occupation != null && occupation!.trim().isNotEmpty)
        'occupation': occupation!.trim(),
      if (countryBirth != null && countryBirth!.trim().isNotEmpty)
        'country_birth': countryBirth!.trim(),
      if (stateBirth != null && stateBirth!.trim().isNotEmpty)
        'state_birth': stateBirth!.trim(),
      if (religiousOrientation != null &&
          religiousOrientation!.trim().isNotEmpty)
        'religious_orientation': religiousOrientation!.trim(),
      if (ethnicGroup != null && ethnicGroup!.trim().isNotEmpty)
        'ethnic_group': ethnicGroup!.trim(),
      if (sexualOrientation != null && sexualOrientation!.trim().isNotEmpty)
        'sexual_orientation': sexualOrientation!.trim(),
      if (hasChildren != null) 'has_children': hasChildren,
    };
  }
}
