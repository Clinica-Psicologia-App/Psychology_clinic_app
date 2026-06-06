class PatientInvitationDraft {
  const PatientInvitationDraft({
    this.fullName,
    this.email,
    this.phone,
    this.responsiblePsychologistId,
  });

  final String? fullName;
  final String? email;
  final String? phone;
  final String? responsiblePsychologistId;
}
