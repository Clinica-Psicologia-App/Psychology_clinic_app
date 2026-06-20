import 'patient_invitation_status.dart';

class PatientInvitation {
  const PatientInvitation({
    required this.id,
    required this.email,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    required this.invitedById,
    required this.responsiblePsychologistId,
    this.fullName,
    this.phone,
    this.acceptedAt,
    this.patientProfileId,
    this.patientId,
    this.invitedByName,
    this.responsiblePsychologistName,
  });

  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final PatientInvitationStatus status;
  final DateTime expiresAt;
  final DateTime? acceptedAt;
  final String? patientProfileId;
  final String? patientId;
  final DateTime createdAt;
  final String invitedById;
  final String responsiblePsychologistId;
  final String? invitedByName;
  final String? responsiblePsychologistName;

  bool get isPending => status == PatientInvitationStatus.pending;

  factory PatientInvitation.fromJson(Map<String, dynamic> json) {
    final invitedBy = json['invited_by_profile'];
    final responsible = json['responsible_psychologist_profile'];

    return PatientInvitation(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phone: json['phone'] as String?,
      status: patientInvitationStatusFromStorage(json['status'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      acceptedAt: _parseDateTime(json['accepted_at']),
      patientProfileId: json['patient_profile_id'] as String?,
      patientId: json['patient_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      invitedById: json['invited_by'] as String,
      responsiblePsychologistId: json['responsible_psychologist_id'] as String,
      invitedByName:
          invitedBy is Map ? invitedBy['full_name'] as String? : null,
      responsiblePsychologistName:
          responsible is Map ? responsible['full_name'] as String? : null,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
