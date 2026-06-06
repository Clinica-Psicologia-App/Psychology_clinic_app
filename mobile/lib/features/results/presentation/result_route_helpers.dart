import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_result_details_page.dart';
import 'patient_results_page.dart';

List<RouteBase> resultsRoutesFor({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'results',
      builder: (context, state) => PatientResultsPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: ':responseId',
          builder: (context, state) => PatientResultDetailsPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            responseId: state.pathParameters['responseId']!,
          ),
        ),
      ],
    ),
  ];
}
