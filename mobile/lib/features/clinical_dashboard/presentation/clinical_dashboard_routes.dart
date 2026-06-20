import '../../profile/domain/profile_role.dart';

abstract final class ClinicalDashboardRoutes {
  static const patientList = '/patient/clinical-dashboard';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/clinical-dashboard';
      case ProfileRole.patient:
        throw ArgumentError('Use patientList para role patient');
    }
  }

  static String staffResultDetail({
    required ProfileRole role,
    required String patientId,
    required String responseId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/results/$responseId';
}
