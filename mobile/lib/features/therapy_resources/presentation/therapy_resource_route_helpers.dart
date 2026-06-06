import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'assign_resource_to_patient_page.dart';
import 'patient_resources_page.dart';
import 'therapy_resource_detail_page.dart';
import 'therapy_resources_page.dart';

List<RouteBase> staffTherapyResourceRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'therapy-resources',
      builder: (context, state) => TherapyResourcesPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'assign/:resourceId',
          builder: (context, state) => AssignResourceToPatientPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            resourceId: state.pathParameters['resourceId']!,
          ),
        ),
        GoRoute(
          path: 'resource/:resourceId',
          builder: (context, state) => TherapyResourceDetailPage(
            role: role,
            patientId: state.pathParameters['patientId'],
            resourceId: state.pathParameters['resourceId']!,
          ),
        ),
      ],
    ),
  ];
}

List<RouteBase> patientTherapyResourceRoutes() {
  return [
    GoRoute(
      path: 'resources',
      builder: (_, __) => const PatientResourcesPage(),
      routes: [
        GoRoute(
          path: ':accessId',
          builder: (context, state) => TherapyResourceDetailPage(
            role: ProfileRole.patient,
            accessId: state.pathParameters['accessId']!,
          ),
        ),
      ],
    ),
  ];
}
