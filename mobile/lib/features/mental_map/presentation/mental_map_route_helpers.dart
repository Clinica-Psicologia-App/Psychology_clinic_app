import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_mental_map_page.dart';

List<RouteBase> patientMentalMapRoutes() {
  return [
    GoRoute(
      path: 'mental-map',
      builder: (_, __) => const PatientMentalMapPage(),
    ),
  ];
}

List<RouteBase> staffPatientMentalMapRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'mental-map',
      builder: (context, state) => StaffPatientMentalMapPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
    ),
  ];
}
