import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'personality_assessment_form_page.dart';
import 'personality_assessment_list_page.dart';
import 'personality_dashboard_page.dart';
import 'personality_synthesis_page.dart';

/// Sub-rotas de Personalidade dentro de `/psychologist/patients/:patientId`.
List<RouteBase> staffPersonalityAssessmentRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'personality',
      builder: (context, state) => PersonalityAssessmentListPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => PersonalityAssessmentFormPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: ':assessmentId',
          builder: (context, state) => PersonalityDashboardPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            assessmentId: state.pathParameters['assessmentId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => PersonalityAssessmentFormPage(
                role: role,
                patientId: state.pathParameters['patientId']!,
                assessmentId: state.pathParameters['assessmentId']!,
              ),
            ),
            GoRoute(
              path: 'synthesis',
              builder: (context, state) => PersonalitySynthesisPage(
                role: role,
                patientId: state.pathParameters['patientId']!,
                assessmentId: state.pathParameters['assessmentId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}
