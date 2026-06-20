import '../../profile/domain/profile_role.dart';

abstract final class TherapyGoalRoutes {
  static const patientList = '/patient/therapy-goals';
  static const patientCreate = '/patient/therapy-goals/new';

  static String patientDetail(String goalId) =>
      '/patient/therapy-goals/$goalId';

  static String patientEdit(String goalId) =>
      '/patient/therapy-goals/$goalId/edit';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/therapy-goals';
      case ProfileRole.patient:
        throw ArgumentError('Use patientList para role patient');
    }
  }

  static String staffCreate({
    required ProfileRole role,
    required String patientId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/new';

  static String staffDetail({
    required ProfileRole role,
    required String patientId,
    required String goalId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/$goalId';

  static String staffEdit({
    required ProfileRole role,
    required String patientId,
    required String goalId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/$goalId/edit';
}
