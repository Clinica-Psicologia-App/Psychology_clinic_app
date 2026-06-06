import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_check_in_detail_page.dart';
import 'patient_check_in_form_page.dart';
import 'patient_check_ins_page.dart';

List<RouteBase> patientCheckInRoutes() {
  return [
    GoRoute(
      path: 'check-ins',
      builder: (_, __) => const PatientCheckInsPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const PatientCheckInFormPage(),
        ),
        GoRoute(
          path: ':checkInId',
          builder: (context, state) => PatientCheckInDetailPage(
            role: ProfileRole.patient,
            checkInId: state.pathParameters['checkInId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => PatientCheckInFormPage(
                checkInId: state.pathParameters['checkInId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

List<RouteBase> staffPatientCheckInRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'check-ins',
      builder: (context, state) => StaffPatientCheckInsPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: ':checkInId',
          builder: (context, state) => PatientCheckInDetailPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            checkInId: state.pathParameters['checkInId']!,
          ),
        ),
      ],
    ),
  ];
}
