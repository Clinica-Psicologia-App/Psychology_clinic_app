class AcceptPatientInvitationRequest {
  const AcceptPatientInvitationRequest({
    required this.token,
    required this.password,
    required this.profile,
    this.termsVersion = '2026-06-15',
    this.privacyVersion = '2026-06-15',
  });

  final String token;
  final String password;
  final AcceptPatientInvitationProfile profile;
  final String termsVersion;
  final String privacyVersion;

  Map<String, dynamic> toJson() {
    return {
      'token': token.trim(),
      'password': password,
      'profile': profile.toJson(),
      'legal_consent': {
        'terms_version': termsVersion,
        'privacy_version': privacyVersion,
      },
    };
  }
}

class AcceptPatientInvitationProfile {
  const AcceptPatientInvitationProfile({
    required this.fullName,
    this.phone,
    this.cpf,
    this.birthDate,
    this.gender,
    this.relationshipStatus,
    this.educationLevel,
    this.occupation,
    this.birthCountryState,
    this.religiousOrientation,
    this.ethnicGroup,
    this.sexualOrientation,
    this.hasChildren,
  });

  final String fullName;
  final String? phone;
  final String? cpf;
  final DateTime? birthDate;
  final String? gender;
  final String? relationshipStatus;
  final String? educationLevel;
  final String? occupation;
  final String? birthCountryState;
  final String? religiousOrientation;
  final String? ethnicGroup;
  final String? sexualOrientation;
  final bool? hasChildren;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName.trim(),
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
      if (birthCountryState != null && birthCountryState!.trim().isNotEmpty)
        'birth_country_state': birthCountryState!.trim(),
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
