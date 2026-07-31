/// Fonte ativa da imagem de perfil. Espelha a coluna `profiles.avatar_type`,
/// que tem CHECK constraint com exatamente estes valores.
enum AvatarType {
  /// Iniciais do nome sobre cor sólida. É o padrão e o fallback universal.
  initials('initials'),

  /// Foto real enviada pelo usuário, armazenada no bucket `avatars`.
  photo('photo'),

  /// Avatar geométrico desenhado no cliente a partir de `avatar_config`.
  /// Não consome Storage.
  custom('custom');

  const AvatarType(this.key);

  final String key;

  /// Valor desconhecido cai em [initials] — nunca lança. Registros antigos e
  /// versões futuras do app não podem quebrar a leitura do perfil.
  static AvatarType fromKey(String? key) {
    for (final type in values) {
      if (type.key == key) return type;
    }
    return initials;
  }
}
