import '../../../features/profile/domain/avatar_config.dart';
import '../../../features/profile/domain/avatar_type.dart';

/// Bloco 1 — "Conhecendo Você". Vive na tabela `patients` (visível ao
/// paciente). A escrita pelo paciente passa pela edge function
/// `update-patient-basics`, já que a RLS de `patients` só permite UPDATE
/// por staff.
///
/// Os campos sócio-demográficos opcionais (sexualOrientation, etc.) são
/// visíveis ao terapeuta no cabeçalho de Bloco 1 e ficam nulos quando o
/// solicitante é o próprio paciente (a query não os seleciona nesse contexto).
class PatientBasics {
  const PatientBasics({
    this.fullName,
    this.preferredName,
    this.birthDate,
    this.occupation,
    this.livesWith,
    this.hasChildren,
    this.usesMedication,
    this.medicationNotes,
    this.psychiatricFollowup,
    this.psychiatristNotes,
    this.importantToKnow,
    // Dados complementares — visíveis ao terapeuta no Bloco 1.
    this.educationLevel,
    this.relationshipStatus,
    this.sexualOrientation,
    this.countryBirth,
    this.ethnicGroup,
    this.religiousOrientation,
    // Avatar — vem do join com profiles.
    this.avatarType = AvatarType.initials,
    this.photoUrl,
    this.avatarConfig,
  });

  /// Somente leitura para o paciente (identidade é gerida pela equipe).
  final String? fullName;
  final String? preferredName;
  final DateTime? birthDate;
  final String? occupation;
  final String? livesWith;
  final bool? hasChildren;
  final bool? usesMedication;
  final String? medicationNotes;
  final bool? psychiatricFollowup;
  final String? psychiatristNotes;
  final String? importantToKnow;

  // Dados complementares — staff-only no contexto do Conhecer.
  final String? educationLevel;
  final String? relationshipStatus;
  final String? sexualOrientation;
  final String? countryBirth;
  final String? ethnicGroup;
  final String? religiousOrientation;

  // Avatar (do perfil).
  final AvatarType avatarType;
  final String? photoUrl;
  final AvatarConfig? avatarConfig;

  /// Iniciais derivadas do nome completo (fallback para avatar tipo initials).
  String get initials {
    final name = (fullName ?? preferredName ?? '').trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  bool get hasDemographicExtras =>
      educationLevel != null ||
      relationshipStatus != null ||
      sexualOrientation != null ||
      countryBirth != null ||
      ethnicGroup != null ||
      religiousOrientation != null;

  String? get displayEducationLevel => _humanize(educationLevel, const {
        'elementary': 'Ensino fundamental',
        'high_school': 'Ensino médio',
        'undergraduate': 'Ensino superior',
        'graduate': 'Pós-graduação',
        'nao_informado': 'Não informado',
      });

  String? get displayRelationshipStatus =>
      _humanize(relationshipStatus, const {
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

  String? get displaySexualOrientation => _humanize(sexualOrientation, const {
        'heterosexual': 'Heterossexual',
        'homosexual': 'Homossexual',
        'bisexual': 'Bissexual',
        'asexual': 'Assexual',
        'pansexual': 'Pansexual',
        'nao_informado': 'Não informado',
      });

  static String? _humanize(String? raw, Map<String, String> map) {
    if (raw == null || raw.isEmpty) return null;
    return map[raw.toLowerCase()] ?? raw;
  }

  /// Idade derivada da data de nascimento.
  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    final hadBirthday = now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) years--;
    return years < 0 ? null : years;
  }

  factory PatientBasics.fromJson(
    Map<String, dynamic> json, {
    String Function(String path)? publicUrlOf,
  }) {
    final profile = json['access_profile'];
    final p = profile is Map
        ? Map<String, dynamic>.from(profile)
        : const <String, dynamic>{};

    final avatarUpdatedAt = p['avatar_updated_at'] == null
        ? null
        : DateTime.tryParse(p['avatar_updated_at'] as String);

    String? resolvedPhotoUrl;
    final path = (p['avatar_path'] as String?)?.trim();
    if (path != null && path.isNotEmpty && publicUrlOf != null) {
      final base = publicUrlOf(path);
      resolvedPhotoUrl = avatarUpdatedAt != null
          ? '$base?v=${avatarUpdatedAt.millisecondsSinceEpoch}'
          : base;
    } else {
      resolvedPhotoUrl = (p['avatar_url'] as String?)?.trim();
      if (resolvedPhotoUrl?.isEmpty ?? false) resolvedPhotoUrl = null;
    }

    return PatientBasics(
      fullName: json['full_name'] as String?,
      preferredName: json['preferred_name'] as String?,
      birthDate: _parseDate(json['birth_date']),
      occupation: json['occupation'] as String?,
      livesWith: json['lives_with'] as String?,
      hasChildren: json['has_children'] as bool?,
      usesMedication: json['uses_medication'] as bool?,
      medicationNotes: json['medication_notes'] as String?,
      psychiatricFollowup: json['psychiatric_followup'] as bool?,
      psychiatristNotes: json['psychiatrist_notes'] as String?,
      importantToKnow: json['important_to_know'] as String?,
      educationLevel: json['education_level'] as String?,
      relationshipStatus: json['relationship_status'] as String?,
      sexualOrientation: json['sexual_orientation'] as String?,
      countryBirth: json['country_birth'] as String?,
      ethnicGroup: json['ethnic_group'] as String?,
      religiousOrientation: json['religious_orientation'] as String?,
      avatarType: AvatarType.fromKey(p['avatar_type'] as String?),
      photoUrl: resolvedPhotoUrl,
      avatarConfig: AvatarConfig.fromJson(
        p['avatar_config'] is Map
            ? Map<String, dynamic>.from(p['avatar_config'] as Map)
            : null,
      ),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
