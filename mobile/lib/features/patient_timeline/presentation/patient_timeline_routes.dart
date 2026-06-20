import '../../profile/domain/profile_role.dart';

abstract final class PatientTimelineRoutes {
  static const patientList = '/patient/timeline';
  static const patientCreate = '/patient/timeline/new';

  static String patientDetail(String eventId) => '/patient/timeline/$eventId';

  static String patientEdit(String eventId) =>
      '/patient/timeline/$eventId/edit';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/timeline';
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
    required String eventId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/$eventId';

  static String staffEdit({
    required ProfileRole role,
    required String patientId,
    required String eventId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/$eventId/edit';
}
