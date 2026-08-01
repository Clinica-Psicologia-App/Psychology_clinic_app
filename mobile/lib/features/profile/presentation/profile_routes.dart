/// Rotas do perfil do usuário — compartilhadas pelos três papéis.
abstract final class ProfileRoutes {
  static const me = '/profile';

  /// Editor do avatar geométrico. Precisa estar em `RouteAccess.sharedPaths`
  /// junto de [me]: a checagem lá é por igualdade exata, não por prefixo.
  static const avatarEditor = '/profile/avatar';
}
