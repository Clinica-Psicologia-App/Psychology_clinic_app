import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'clinical_report_options_page.dart';

List<RouteBase> staffClinicalReportRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'clinical-report',
      builder: (context, state) => ClinicalReportOptionsPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
    ),
  ];
}
