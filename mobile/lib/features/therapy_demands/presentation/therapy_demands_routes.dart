import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'therapy_demands_page.dart';

abstract final class TherapyDemandsRoutes {
  static String staff({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/demands';
      case ProfileRole.platformAdmin:
        return '/platform/patients/$patientId/demands';
      case ProfileRole.patient:
        throw ArgumentError('Demandas terapêuticas é uma tela da equipe.');
    }
  }
}

List<RouteBase> staffTherapyDemandsRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'demands',
      builder: (context, state) => TherapyDemandsPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
    ),
  ];
}
