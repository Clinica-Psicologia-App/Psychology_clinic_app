import '../../profile/domain/profile_role.dart';

abstract final class MentalMapRoutes {
  static const patientList = '/patient/mental-map';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.admin:
        return '/admin/patients/$patientId/mental-map';
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/mental-map';
      case ProfileRole.patient:
        throw ArgumentError('Use patientList para role patient');
    }
  }
}
