import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'case_conceptualization_edit_page.dart';
import 'case_conceptualization_page.dart';
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
    GoRoute(
      path: 'case-conceptualization',
      builder: (context, state) => CaseConceptualizationPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => CaseConceptualizationEditPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
      ],
    ),
  ];
}
