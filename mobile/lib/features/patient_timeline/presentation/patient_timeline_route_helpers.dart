import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_timeline_event_detail_page.dart';
import 'patient_timeline_event_form_page.dart';
import 'patient_timeline_page.dart';

List<RouteBase> patientTimelineRoutes() {
  return [
    GoRoute(
      path: 'timeline',
      builder: (_, __) => const PatientTimelinePage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const PatientTimelineEventFormPage(
            role: ProfileRole.patient,
          ),
        ),
        GoRoute(
          path: ':eventId',
          builder: (context, state) => PatientTimelineEventDetailPage(
            role: ProfileRole.patient,
            eventId: state.pathParameters['eventId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => PatientTimelineEventFormPage(
                role: ProfileRole.patient,
                eventId: state.pathParameters['eventId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

List<RouteBase> staffPatientTimelineRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'timeline',
      builder: (context, state) => StaffPatientTimelinePage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'new',
          builder: (context, state) => PatientTimelineEventFormPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: ':eventId',
          builder: (context, state) => PatientTimelineEventDetailPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            eventId: state.pathParameters['eventId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => PatientTimelineEventFormPage(
                role: role,
                patientId: state.pathParameters['patientId']!,
                eventId: state.pathParameters['eventId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}
