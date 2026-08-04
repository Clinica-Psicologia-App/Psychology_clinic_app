import 'package:go_router/go_router.dart';

import 'admin_psychoeducation_catalog_page.dart';
import 'admin_psychoeducation_editor_page.dart';
import 'psychoeducation_journey_page.dart';
import 'psychoeducation_module_page.dart';

/// Rotas da Biblioteca de Psicoeducação (paciente + curadoria do admin).
abstract final class PsychoeducationRoutes {
  // Paciente.
  static const patient = '/patient/psychoeducation';
  static String patientModule(String id) => '/patient/psychoeducation/$id';

  // Admin (curadoria).
  static const adminCatalog = '/platform/psychoeducation';
  static const adminNew = '/platform/psychoeducation/new';
  static String adminModule(String id) => '/platform/psychoeducation/$id';
}

/// Sub-rotas do paciente (montadas sob /patient).
List<RouteBase> psychoeducationPatientRoutes() {
  return [
    GoRoute(
      path: 'psychoeducation',
      builder: (_, __) => const PsychoeducationJourneyPage(),
      routes: [
        GoRoute(
          path: ':moduleId',
          builder: (_, state) => PsychoeducationModulePage(
            moduleId: state.pathParameters['moduleId']!,
          ),
        ),
      ],
    ),
  ];
}

/// Sub-rotas de curadoria (montadas sob /platform).
List<RouteBase> psychoeducationAdminRoutes() {
  return [
    GoRoute(
      path: 'psychoeducation',
      builder: (_, __) => const AdminPsychoeducationCatalogPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, __) => const AdminPsychoeducationEditorPage(),
        ),
        GoRoute(
          path: ':moduleId',
          builder: (_, state) => AdminPsychoeducationEditorPage(
            moduleId: state.pathParameters['moduleId'],
          ),
        ),
      ],
    ),
  ];
}
