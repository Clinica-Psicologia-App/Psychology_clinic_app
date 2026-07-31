import '../../features/profile/domain/profile_role.dart';

/// Controle de acesso a rotas por `profiles.role` (defesa em profundidade no router).
abstract final class RouteAccess {
  static const publicPaths = {
    '/',
    '/onboarding',
    '/login',
    '/accept-invitation',
    '/forgot-password',
    '/update-password',
    '/terms',
    '/privacy',
  };

  /// Rotas autenticadas comuns a todos os papéis (não têm prefixo de role).
  static const sharedPaths = {
    '/profile',
  };

  static bool isPublic(String location) => publicPaths.contains(location);

  static bool isShared(String location) => sharedPaths.contains(location);

  static bool isAllowed(String location, ProfileRole role) {
    if (isPublic(location) || isShared(location)) return true;

    switch (role) {
      case ProfileRole.platformAdmin:
        return location == '/platform' || location.startsWith('/platform/');
      case ProfileRole.psychologist:
        return location == '/psychologist' ||
            location.startsWith('/psychologist/');
      case ProfileRole.patient:
        return location == '/patient' || location.startsWith('/patient/');
    }
  }

  static String homeFor(ProfileRole role) {
    switch (role) {
      case ProfileRole.platformAdmin:
        return '/platform';
      case ProfileRole.psychologist:
        return '/psychologist';
      case ProfileRole.patient:
        return '/patient';
    }
  }
}
