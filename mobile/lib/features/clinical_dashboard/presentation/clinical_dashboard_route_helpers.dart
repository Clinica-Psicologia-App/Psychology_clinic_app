import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_clinical_dashboard_page.dart';

List<RouteBase> patientClinicalDashboardRoutes() {
  return [
    GoRoute(
      path: 'clinical-dashboard',
      builder: (_, __) => const PatientClinicalDashboardPage(),
    ),
  ];
}

List<RouteBase> staffClinicalDashboardRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'clinical-dashboard',
      builder: (context, state) => StaffPatientClinicalDashboardPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
    ),
  ];
}
