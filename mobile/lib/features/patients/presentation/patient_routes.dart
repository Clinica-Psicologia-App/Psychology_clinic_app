import '../../../core/router/route_access.dart';
import '../../profile/domain/profile_role.dart';
import '../../patient_invitations/presentation/patient_invitation_routes.dart';

/// Rotas do módulo de pacientes por role (staff apenas).
abstract final class PatientRoutes {
  static String list(ProfileRole role) {
    switch (role) {
      case ProfileRole.admin:
        return '/admin/patients';
      case ProfileRole.psychologist:
        return '/psychologist/patients';
      case ProfileRole.patient:
        throw StateError('Pacientes não disponível para role patient');
    }
  }

  static String create(ProfileRole role) => '${list(role)}/new';

  static String detail(ProfileRole role, String patientId) =>
      '${list(role)}/$patientId';

  static String invitationList(ProfileRole role) =>
      PatientInvitationRoutes.list(role);

  static String invitationCreate(ProfileRole role) =>
      PatientInvitationRoutes.create(role);

  static bool isStaffPatientsPath(String location) {
    return location.startsWith('/admin/patients') ||
        location.startsWith('/psychologist/patients');
  }

  static bool pathMatchesRole(String location, ProfileRole role) =>
      RouteAccess.isAllowed(location, role);
}
