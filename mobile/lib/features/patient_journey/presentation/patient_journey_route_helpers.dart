import 'package:go_router/go_router.dart';

import '../domain/journey_step_id.dart';
import 'journey_placeholder_page.dart';
import 'patient_journey_page.dart';

List<RouteBase> patientJourneyRoutes() {
  return [
    GoRoute(
      path: 'journey',
      builder: (_, __) => const PatientJourneyPage(),
      routes: [
        GoRoute(
          path: 'upcoming/:stepId',
          builder: (context, state) {
            final step = journeyStepIdFromRouteKey(
              state.pathParameters['stepId'],
            );
            if (step == null) {
              return const JourneyPlaceholderPage(title: 'Módulo');
            }
            return JourneyPlaceholderPage.forStep(step);
          },
        ),
      ],
    ),
  ];
}
