import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_therapy_goals_page.dart';
import 'therapy_goal_detail_page.dart';
import 'therapy_goal_form_page.dart';

List<RouteBase> patientTherapyGoalRoutes() {
  return [
    GoRoute(
      path: 'therapy-goals',
      builder: (_, __) => const PatientTherapyGoalsPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const TherapyGoalFormPage(
            role: ProfileRole.patient,
          ),
        ),
        GoRoute(
          path: ':goalId',
          builder: (context, state) => TherapyGoalDetailPage(
            role: ProfileRole.patient,
            goalId: state.pathParameters['goalId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => TherapyGoalFormPage(
                role: ProfileRole.patient,
                goalId: state.pathParameters['goalId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

List<RouteBase> staffTherapyGoalRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'therapy-goals',
      builder: (context, state) => StaffPatientTherapyGoalsPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => TherapyGoalFormPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: ':goalId',
          builder: (context, state) => TherapyGoalDetailPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            goalId: state.pathParameters['goalId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => TherapyGoalFormPage(
                role: role,
                patientId: state.pathParameters['patientId']!,
                goalId: state.pathParameters['goalId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}
