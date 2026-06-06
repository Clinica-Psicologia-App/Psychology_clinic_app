import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'create_daily_monitor_page.dart';
import 'daily_monitor_detail_page.dart';
import 'patient_daily_monitor_history_page.dart';
import 'patient_daily_monitors_page.dart';

List<RouteBase> patientDailyMonitorRoutes() {
  return [
    GoRoute(
      path: 'daily-monitors',
      builder: (_, __) => const PatientDailyMonitorsPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const CreateDailyMonitorPage(),
        ),
        GoRoute(
          path: ':monitorId',
          builder: (context, state) => DailyMonitorDetailPage(
            role: ProfileRole.patient,
            monitorId: state.pathParameters['monitorId']!,
          ),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) => CreateDailyMonitorPage(
                monitorId: state.pathParameters['monitorId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

List<RouteBase> staffDailyMonitorRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'daily-monitors',
      builder: (context, state) => PatientDailyMonitorHistoryPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: ':monitorId',
          builder: (context, state) => DailyMonitorDetailPage(
            role: role,
            patientId: state.pathParameters['patientId'],
            monitorId: state.pathParameters['monitorId']!,
            readOnly: true,
          ),
        ),
      ],
    ),
  ];
}
