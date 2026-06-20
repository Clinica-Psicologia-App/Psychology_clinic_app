import '../../profile/domain/profile_role.dart';

abstract final class DailyMonitorRoutes {
  static const patientList = '/patient/daily-monitors';
  static const patientCreate = '/patient/daily-monitors/new';

  static String patientDetail(String id) => '/patient/daily-monitors/$id';

  static String patientEdit(String id) => '/patient/daily-monitors/$id/edit';

  static String staffHistory({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw StateError('Staff clinic only');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/daily-monitors';
      case ProfileRole.patient:
        throw StateError('Staff only');
    }
  }

  static String staffDetail({
    required ProfileRole role,
    required String patientId,
    required String monitorId,
  }) {
    return '${staffHistory(role: role, patientId: patientId)}/$monitorId';
  }
}
