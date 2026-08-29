import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'genogram_bootstrap_page.dart';
import 'genogram_person_detail_page.dart';
import 'genogram_person_form_page.dart';
import 'genogram_relationship_detail_page.dart';
import 'genogram_relationship_form_page.dart';
import 'patient_genogram_page.dart';

List<RouteBase> patientGenogramRoutes() {
  return [
    GoRoute(
      path: 'genogram',
      builder: (_, __) => const PatientGenogramPage(),
      routes: [
        GoRoute(
          path: 'people/new',
          builder: (_, __) => const GenogramPersonFormPage(
            role: ProfileRole.patient,
          ),
        ),
        GoRoute(
          path: 'people/:personId',
          builder: (context, state) => GenogramPersonDetailPage(
            role: ProfileRole.patient,
            personId: state.pathParameters['personId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => GenogramPersonFormPage(
                role: ProfileRole.patient,
                personId: state.pathParameters['personId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'relationships/new',
          builder: (_, __) => const GenogramRelationshipFormPage(
            role: ProfileRole.patient,
          ),
        ),
        GoRoute(
          path: 'relationships/:relationshipId',
          builder: (context, state) => GenogramRelationshipDetailPage(
            role: ProfileRole.patient,
            relationshipId: state.pathParameters['relationshipId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => GenogramRelationshipFormPage(
                role: ProfileRole.patient,
                relationshipId: state.pathParameters['relationshipId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

List<RouteBase> staffPatientGenogramRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'genogram',
      builder: (context, state) => StaffPatientGenogramPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'people/new',
          builder: (context, state) => GenogramPersonFormPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: 'people/:personId',
          builder: (context, state) => GenogramPersonDetailPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            personId: state.pathParameters['personId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => GenogramPersonFormPage(
                role: role,
                patientId: state.pathParameters['patientId']!,
                personId: state.pathParameters['personId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'relationships/new',
          builder: (context, state) => GenogramRelationshipFormPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: 'relationships/:relationshipId',
          builder: (context, state) => GenogramRelationshipDetailPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            relationshipId: state.pathParameters['relationshipId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => GenogramRelationshipFormPage(
                role: role,
                patientId: state.pathParameters['patientId']!,
                relationshipId: state.pathParameters['relationshipId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'bootstrap',
          builder: (context, state) => GenogramBootstrapPage(
            patientId: state.pathParameters['patientId']!,
          ),
        ),
      ],
    ),
  ];
}
