/// Paciente da clínica (visão de listagem/detalhe).
class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.cpf,
    this.birthDate,
    this.profileId,
    required this.responsiblePsychologistId,
    this.responsiblePsychologistName,
    this.accessStatus,
    this.createdAt,
  });

  final String id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? cpf;
  final DateTime? birthDate;
  final String? profileId;
  final String responsiblePsychologistId;
  final String? responsiblePsychologistName;
  final PatientAccessStatus? accessStatus;
  final DateTime? createdAt;

  factory Patient.fromJson(Map<String, dynamic> json) {
    final responsible = json['responsible_psychologist'];
    final accessProfile = json['access_profile'];

    return Patient(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      cpf: json['cpf'] as String?,
      birthDate: _parseDate(json['birth_date']),
      profileId: json['profile_id'] as String?,
      responsiblePsychologistId:
          json['responsible_psychologist_id'] as String,
      responsiblePsychologistName: responsible is Map
          ? responsible['full_name'] as String?
          : null,
      accessStatus: _accessStatusFromJson(profileId: json['profile_id'], accessProfile: accessProfile),
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static PatientAccessStatus? _accessStatusFromJson({
    required dynamic profileId,
    required dynamic accessProfile,
  }) {
    if (profileId == null) return PatientAccessStatus.noAppAccess;
    if (accessProfile is Map && accessProfile['is_active'] == false) {
      return PatientAccessStatus.inactive;
    }
    if (accessProfile is Map && accessProfile['is_active'] == true) {
      return PatientAccessStatus.active;
    }
    return PatientAccessStatus.active;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

enum PatientAccessStatus {
  active,
  inactive,
  noAppAccess,
}

extension PatientAccessStatusLabel on PatientAccessStatus {
  String get label {
    switch (this) {
      case PatientAccessStatus.active:
        return 'Ativo';
      case PatientAccessStatus.inactive:
        return 'Inativo';
      case PatientAccessStatus.noAppAccess:
        return 'Sem acesso ao app';
    }
  }
}
