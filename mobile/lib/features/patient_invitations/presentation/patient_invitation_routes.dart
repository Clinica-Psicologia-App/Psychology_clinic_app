import '../../profile/domain/profile_role.dart';

abstract final class PatientInvitationRoutes {
  static const accept = '/accept-invitation';

  static String list(ProfileRole role) {
    switch (role) {
      case ProfileRole.admin:
        return '/admin/patient-invitations';
      case ProfileRole.psychologist:
        return '/psychologist/patient-invitations';
      case ProfileRole.patient:
        throw StateError('Convites nao disponiveis para patient');
    }
  }

  static String create(ProfileRole role) => '${list(role)}/new';
}
