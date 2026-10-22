import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_healthy_resources_page.dart';

List<RouteBase> staffHealthyResourcesRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'healthy-resources',
      builder: (context, state) => StaffPatientHealthyResourcesPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
    ),
  ];
}
