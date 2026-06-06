class CreatePatientInvitationRequest {
  const CreatePatientInvitationRequest({
    required this.email,
    required this.responsiblePsychologistId,
    this.fullName,
    this.phone,
  });

  final String email;
  final String responsiblePsychologistId;
  final String? fullName;
  final String? phone;

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'responsible_psychologist_id': responsiblePsychologistId,
      if (fullName != null && fullName!.trim().isNotEmpty)
        'full_name': fullName!.trim(),
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
    };
  }
}
