import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_infographic_page.dart';

/// Caminhos da tela de infográfico do paciente (staff-only).
abstract final class PatientInfographicRoutes {
  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Infográfico não disponível para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/infographic';
      case ProfileRole.patient:
        throw ArgumentError('Infográfico é uma tela de staff');
    }
  }
}

List<RouteBase> staffPatientInfographicRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'infographic',
      builder: (context, state) => PatientInfographicPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
    ),
  ];
}
