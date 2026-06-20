import '../../profile/domain/profile_role.dart';

abstract final class PatientProblemRoutes {
  static const patientList = '/patient/problems';
  static const patientCreate = '/patient/problems/new';

  static String patientDetail(String problemId) =>
      '/patient/problems/$problemId';

  static String patientEdit(String problemId) =>
      '/patient/problems/$problemId/edit';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/problems';
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
    required String problemId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/$problemId';

  static String staffEdit({
    required ProfileRole role,
    required String patientId,
    required String problemId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/$problemId/edit';
}
