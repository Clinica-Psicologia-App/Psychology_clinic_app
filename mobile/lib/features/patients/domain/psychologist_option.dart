/// Psicólogo da clínica para seleção no cadastro (admin).
class PsychologistOption {
  const PsychologistOption({
    required this.id,
    required this.fullName,
    this.email,
    this.canReceivePatients = true,
    this.patientAssignmentLimit,
    this.assignedPatientsCount = 0,
    this.pendingPatientInvitationsCount = 0,
  });

  final String id;
  final String fullName;
  final String? email;
  final bool canReceivePatients;
  final int? patientAssignmentLimit;
  final int assignedPatientsCount;
  final int pendingPatientInvitationsCount;

  factory PsychologistOption.fromJson(Map<String, dynamic> json) {
    return PsychologistOption(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      canReceivePatients: json['can_receive_patients'] as bool? ?? true,
      patientAssignmentLimit: json['patient_assignment_limit'] as int?,
      assignedPatientsCount: json['assigned_patients_count'] as int? ?? 0,
      pendingPatientInvitationsCount:
          json['pending_patient_invitations_count'] as int? ?? 0,
    );
  }

  int get reservedPatientSlots =>
      assignedPatientsCount + pendingPatientInvitationsCount;

  bool get reachedPatientAssignmentLimit =>
      patientAssignmentLimit != null && reservedPatientSlots >= patientAssignmentLimit!;

  bool get canAssignNewPatient =>
      canReceivePatients && !reachedPatientAssignmentLimit;

  String get accessSummary {
    if (!canReceivePatients) return 'bloqueado para novos pacientes';
    final limit = patientAssignmentLimit;
    if (limit == null) return '$reservedPatientSlots em uso · sem limite';
    return '$reservedPatientSlots/$limit vagas em uso';
  }

  String get displayLabel =>
      email != null && email!.isNotEmpty
          ? '$fullName ($email) · $accessSummary'
          : '$fullName · $accessSummary';
}
