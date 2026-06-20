import '../../profile/domain/profile_role.dart';

abstract final class PatientInvitationRoutes {
  static const accept = '/accept-invitation';

  static String list(ProfileRole role) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw StateError('Convites não disponíveis para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patient-invitations';
      case ProfileRole.patient:
        throw StateError('Convites não disponíveis para patient');
    }
  }

  static String create(ProfileRole role) => '${list(role)}/new';
}
