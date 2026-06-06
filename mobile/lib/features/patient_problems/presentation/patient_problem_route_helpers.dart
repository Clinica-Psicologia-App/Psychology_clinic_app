import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_problem_detail_page.dart';
import 'patient_problem_form_page.dart';
import 'patient_problems_page.dart';

List<RouteBase> patientProblemRoutes() {
  return [
    GoRoute(
      path: 'problems',
      builder: (_, __) => const PatientProblemsPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const PatientProblemFormPage(
            role: ProfileRole.patient,
          ),
        ),
        GoRoute(
          path: ':problemId',
          builder: (context, state) => PatientProblemDetailPage(
            role: ProfileRole.patient,
            problemId: state.pathParameters['problemId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => PatientProblemFormPage(
                role: ProfileRole.patient,
                problemId: state.pathParameters['problemId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

List<RouteBase> staffPatientProblemRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'problems',
      builder: (context, state) => StaffPatientProblemsPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => PatientProblemFormPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: ':problemId',
          builder: (context, state) => PatientProblemDetailPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            problemId: state.pathParameters['problemId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => PatientProblemFormPage(
                role: role,
                patientId: state.pathParameters['patientId']!,
                problemId: state.pathParameters['problemId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}
