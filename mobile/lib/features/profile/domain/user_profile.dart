import 'avatar_config.dart';
import 'avatar_type.dart';
import 'profile_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.clinicId,
    required this.role,
    required this.fullName,
    required this.email,
    required this.isActive,
    this.phone,
    this.createdAt,
    this.avatarType = AvatarType.initials,
    this.photoUrl,
    this.avatarConfig,
    this.avatarUpdatedAt,
  });

  final String id;
  final String clinicId;
  final ProfileRole role;
  final String fullName;
  final String email;
  final bool isActive;
  final String? phone;
  final DateTime? createdAt;

  /// Fonte de avatar escolhida pelo usuário. Pode não ser a efetivamente
  /// exibível — use [effectiveAvatarType], que degrada com segurança.
  final AvatarType avatarType;

  /// URL da foto já resolvida e versionada, pronta para `Image.network`.
  /// Montada uma única vez no mapper (ver [UserProfile.fromJson]); nenhum widget
  /// deve concatenar parâmetros de cache por conta própria.
  final String? photoUrl;

  /// Configuração do avatar geométrico. Renderizada no cliente, sem Storage.
  final AvatarConfig? avatarConfig;

  final DateTime? avatarUpdatedAt;

  /// O que realmente dá para desenhar agora. Uma foto sem URL ou um avatar
  /// personalizado sem configuração caem em [AvatarType.initials] — assim a UI
  /// nunca fica com espaço vazio ou ícone de imagem quebrada.
  AvatarType get effectiveAvatarType {
    switch (avatarType) {
      case AvatarType.photo:
        return _hasPhoto ? AvatarType.photo : AvatarType.initials;
      case AvatarType.custom:
        return avatarConfig != null ? AvatarType.custom : AvatarType.initials;
      case AvatarType.initials:
        // Registros antigos podem ter foto sem avatar_type definido.
        return _hasPhoto ? AvatarType.photo : AvatarType.initials;
    }
  }

  bool get _hasPhoto => (photoUrl ?? '').trim().isNotEmpty;

  /// Iniciais do nome — fallback universal.
  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    AvatarType? avatarType,
    String? photoUrl,
    AvatarConfig? avatarConfig,
    DateTime? avatarUpdatedAt,
  }) {
    return UserProfile(
      id: id,
      clinicId: clinicId,
      role: role,
      fullName: fullName ?? this.fullName,
      email: email,
      isActive: isActive,
      phone: phone ?? this.phone,
      createdAt: createdAt,
      avatarType: avatarType ?? this.avatarType,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      avatarUpdatedAt: avatarUpdatedAt ?? this.avatarUpdatedAt,
    );
  }

  /// [publicUrlOf] traduz um path do bucket em URL pública. Vem da camada de
  /// dados para que o domínio siga sem dependência do Supabase.
  factory UserProfile.fromJson(
    Map<String, dynamic> json, {
    String Function(String path)? publicUrlOf,
  }) {
    final role = ProfileRole.tryParse(json['role'] as String?);
    if (role == null) {
      throw FormatException('Invalid profile role: ${json['role']}');
    }

    final avatarUpdatedAt = _parseDate(json['avatar_updated_at']);

    return UserProfile(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      role: role,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? true,
      phone: json['phone'] as String?,
      createdAt: _parseDate(json['created_at']),
      avatarType: AvatarType.fromKey(json['avatar_type'] as String?),
      photoUrl: resolvePhotoUrl(
        avatarPath: json['avatar_path'] as String?,
        legacyAvatarUrl: json['avatar_url'] as String?,
        avatarUpdatedAt: avatarUpdatedAt,
        publicUrlOf: publicUrlOf,
      ),
      avatarConfig: AvatarConfig.fromJson(
        json['avatar_config'] is Map
            ? Map<String, dynamic>.from(json['avatar_config'] as Map)
            : null,
      ),
      avatarUpdatedAt: avatarUpdatedAt,
    );
  }

  /// Ponto único de montagem da URL da foto.
  ///
  /// Precedência: `avatar_path` (formato atual) → `avatar_url` (legado, guarda
  /// a URL completa) → nulo. O sufixo `?v=` deriva de `avatar_updated_at` para
  /// que a troca de foto apareça na hora, já que o path do arquivo é estável.
  static String? resolvePhotoUrl({
    required String? avatarPath,
    required String? legacyAvatarUrl,
    required DateTime? avatarUpdatedAt,
    String Function(String path)? publicUrlOf,
  }) {
    String? base;

    final path = avatarPath?.trim();
    if (path != null && path.isNotEmpty && publicUrlOf != null) {
      base = publicUrlOf(path);
    } else {
      final legacy = legacyAvatarUrl?.trim();
      if (legacy != null && legacy.isNotEmpty) base = legacy;
    }

    if (base == null || base.isEmpty) return null;
    if (avatarUpdatedAt == null) return base;

    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}v=${avatarUpdatedAt.millisecondsSinceEpoch}';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
