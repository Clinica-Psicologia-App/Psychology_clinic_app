import '../../profile/domain/profile_role.dart';

class ClinicUser {
  const ClinicUser({
    required this.id,
    required this.clinicId,
    required this.clinicName,
    required this.clinicType,
    required this.clinicIsActive,
    required this.fullName,
    required this.email,
    required this.role,
    required this.isActive,
    this.canReceivePatients = true,
    this.patientAssignmentLimit,
    this.assignedPatientsCount = 0,
    this.pendingPatientInvitationsCount = 0,
    this.phone,
    this.crp,
    this.createdAt,
  });

  final String id;
  final String clinicId;
  final String clinicName;
  final String clinicType;
  final bool clinicIsActive;
  final String fullName;
  final String email;
  final String? phone;
  final ProfileRole role;
  final String? crp;
  final bool isActive;
  final bool canReceivePatients;
  final int? patientAssignmentLimit;
  final int assignedPatientsCount;
  final int pendingPatientInvitationsCount;
  final DateTime? createdAt;

  factory ClinicUser.fromJson(Map<String, dynamic> json) {
    final role = ProfileRole.tryParse(json['role'] as String?);
    if (role == null) {
      throw FormatException('Invalid profile role: ${json['role']}');
    }

    return ClinicUser(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String? ?? '',
      clinicName: _clinicField(json, 'name') ?? 'Clínica',
      clinicType: _clinicField(json, 'clinic_type') ?? 'clinic',
      clinicIsActive: _clinicBool(json, 'is_active') ?? true,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: role,
      crp: json['crp'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      canReceivePatients: json['can_receive_patients'] as bool? ?? true,
      patientAssignmentLimit: json['patient_assignment_limit'] as int?,
      assignedPatientsCount: json['assigned_patients_count'] as int? ?? 0,
      pendingPatientInvitationsCount:
          json['pending_patient_invitations_count'] as int? ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  bool get isPersonalClinic => clinicType == 'personal';

  int get reservedPatientSlots =>
      assignedPatientsCount + pendingPatientInvitationsCount;

  bool get hasPatientAssignmentLimit => patientAssignmentLimit != null;

  bool get reachedPatientAssignmentLimit =>
      patientAssignmentLimit != null &&
      reservedPatientSlots >= patientAssignmentLimit!;

  String get patientAccessSummary {
    if (role != ProfileRole.psychologist) return '';
    if (!canReceivePatients) return 'Novos pacientes bloqueados';
    final limit = patientAssignmentLimit;
    if (limit == null) {
      return '$reservedPatientSlots pacientes/convites · sem limite';
    }
    return '$reservedPatientSlots/$limit pacientes/convites';
  }

  String get clinicTypeLabel {
    return isPersonalClinic ? 'Individual' : 'Clínica';
  }

  bool canBeDeletedBy({
    required String? currentProfileId,
    required bool actorIsPlatformAdmin,
  }) {
    if (!actorIsPlatformAdmin || id == currentProfileId || isActive) {
      return false;
    }
    return role == ProfileRole.platformAdmin ||
        role == ProfileRole.psychologist;
  }
}

String? _clinicField(Map<String, dynamic> json, String field) {
  final clinic = json['clinic'];
  if (clinic is Map && clinic[field] != null) {
    return clinic[field].toString();
  }
  final clinics = json['clinics'];
  if (clinics is Map && clinics[field] != null) {
    return clinics[field].toString();
  }
  return json['clinic_$field']?.toString();
}

bool? _clinicBool(Map<String, dynamic> json, String field) {
  final clinic = json['clinic'];
  if (clinic is Map && clinic[field] is bool) return clinic[field] as bool;
  final clinics = json['clinics'];
  if (clinics is Map && clinics[field] is bool) return clinics[field] as bool;
  final value = json['clinic_$field'];
  return value is bool ? value : null;
}
