import '../../profile/domain/profile_role.dart';

abstract final class PatientCheckInRoutes {
  static const patientList = '/patient/check-ins';
  static const patientCreate = '/patient/check-ins/new';

  static String patientDetail(String id) => '/patient/check-ins/$id';

  static String patientEdit(String id) => '/patient/check-ins/$id/edit';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.admin:
        return '/admin/patients/$patientId/check-ins';
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/check-ins';
      case ProfileRole.patient:
        throw ArgumentError('Use patientList para role patient');
    }
  }

  static String staffDetail({
    required ProfileRole role,
    required String patientId,
    required String checkInId,
  }) => '${staffList(role: role, patientId: patientId)}/$checkInId';
}
