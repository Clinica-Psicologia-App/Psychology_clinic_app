import '../../profile/domain/profile_role.dart';

abstract final class TherapyResourceRoutes {
  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw StateError('Staff clinic only');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/therapy-resources';
      case ProfileRole.patient:
        throw StateError('Staff only');
    }
  }

  static String assign({
    required ProfileRole role,
    required String patientId,
    required String resourceId,
  }) {
    return '${staffList(role: role, patientId: patientId)}/assign/$resourceId';
  }

  static String newResource({
    required ProfileRole role,
    required String patientId,
  }) {
    return '${staffList(role: role, patientId: patientId)}/new';
  }

  static String staffDetail({
    required ProfileRole role,
    required String patientId,
    required String resourceId,
  }) {
    return '${staffList(role: role, patientId: patientId)}/resource/$resourceId';
  }

  static String edit({
    required ProfileRole role,
    required String patientId,
    required String resourceId,
  }) {
    return '${staffDetail(role: role, patientId: patientId, resourceId: resourceId)}/edit';
  }

  static const patientList = '/patient/resources';

  static String patientDetail(String accessId) =>
      '/patient/resources/$accessId';
}
