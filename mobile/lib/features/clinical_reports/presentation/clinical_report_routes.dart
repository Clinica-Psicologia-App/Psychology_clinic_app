import '../../profile/domain/profile_role.dart';

abstract final class ClinicalReportRoutes {
  static String staffOptions({
    required ProfileRole role,
    required String patientId,
  }) =>
      '/${role.name}/patients/$patientId/clinical-report';
}
