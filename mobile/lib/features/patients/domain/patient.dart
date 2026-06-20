/// Paciente da clínica (visão de listagem/detalhe).
class Patient {
  const Patient({
    required this.id,
    required this.fullName,
    this.email,
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
    this.intakeSummary,
    this.currentLifeContext,
    this.therapyDemands,
    this.profileId,
    this.responsiblePsychologistId,
    this.responsiblePsychologistName,
    this.accessStatus,
    this.isActive = true,
    this.inactivatedAt,
    this.createdAt,
    this.supportsIntakeContext = true,
  });

  final String id;
  final String fullName;
  final String? email;
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
  final String? intakeSummary;
  final String? currentLifeContext;
  final String? therapyDemands;
  final String? profileId;
  final String? responsiblePsychologistId;
  final String? responsiblePsychologistName;
  final PatientAccessStatus? accessStatus;
  final bool isActive;
  final DateTime? inactivatedAt;
  final DateTime? createdAt;
  final bool supportsIntakeContext;

  String? get displayGender => _humanizeClinicalValue(gender, const {
        'female': 'Feminino',
        'feminino': 'Feminino',
        'male': 'Masculino',
        'masculino': 'Masculino',
        'non_binary': 'Não binário',
        'other': 'Outro',
        'outro': 'Outro',
        'unknown': 'Não informado',
        'nao_informado': 'Não informado',
      });

  String? get displayRelationshipStatus =>
      _humanizeClinicalValue(relationshipStatus, const {
        'single': 'Solteiro(a)',
        'solteiro': 'Solteiro(a)',
        'married': 'Casado(a)',
        'casado': 'Casado(a)',
        'divorced': 'Divorciado(a)',
        'divorciado': 'Divorciado(a)',
        'widowed': 'Viúvo(a)',
        'viuvo': 'Viúvo(a)',
        'stable_union': 'União estável',
        'uniao_estavel': 'União estável',
        'nao_informado': 'Não informado',
      });

  String? get displayEducationLevel =>
      _humanizeClinicalValue(educationLevel, const {
        'elementary': 'Ensino fundamental',
        'high_school': 'Ensino médio',
        'undergraduate': 'Ensino superior',
        'graduate': 'Pós-graduação',
        'nao_informado': 'Não informado',
      });

  String? get displaySexualOrientation =>
      _humanizeClinicalValue(sexualOrientation, const {
        'heterosexual': 'Heterossexual',
        'homosexual': 'Homossexual',
        'bisexual': 'Bissexual',
        'asexual': 'Assexual',
        'pansexual': 'Pansexual',
        'nao_informado': 'Não informado',
      });

  String? get displayEthnicGroup => _humanizeClinicalValue(ethnicGroup);

  factory Patient.fromJson(
    Map<String, dynamic> json, {
    bool supportsIntakeContext = true,
  }) {
    final responsible = json['responsible_psychologist'];
    final accessProfile = json['access_profile'];

    return Patient(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      cpf: json['cpf'] as String?,
      birthDate: _parseDate(json['birth_date']),
      gender: json['gender'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
      educationLevel: json['education_level'] as String?,
      occupation: json['occupation'] as String?,
      countryBirth: json['country_birth'] as String?,
      stateBirth: json['state_birth'] as String?,
      religiousOrientation: json['religious_orientation'] as String?,
      ethnicGroup: json['ethnic_group'] as String?,
      sexualOrientation: json['sexual_orientation'] as String?,
      hasChildren: json['has_children'] as bool?,
      intakeSummary: json['intake_summary'] as String?,
      currentLifeContext: json['current_life_context'] as String?,
      therapyDemands: json['therapy_demands'] as String?,
      profileId: json['profile_id'] as String?,
      responsiblePsychologistId: json['responsible_psychologist_id'] as String?,
      responsiblePsychologistName:
          responsible is Map ? responsible['full_name'] as String? : null,
      accessStatus: _accessStatusFromJson(
        profileId: json['profile_id'],
        accessProfile: accessProfile,
      ),
      isActive: json['is_active'] as bool? ?? true,
      inactivatedAt: _parseDateTime(json['inactivated_at']),
      createdAt: _parseDateTime(json['created_at']),
      supportsIntakeContext: supportsIntakeContext,
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

  static String? _humanizeClinicalValue(
    String? value, [
    Map<String, String> labels = const {},
  ]) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    final mapped = labels[normalized];
    if (mapped != null) return mapped;

    final words = normalized
        .replaceAll('-', '_')
        .split('_')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;
    final text = words.join(' ');
    return '${text[0].toUpperCase()}${text.substring(1)}';
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
