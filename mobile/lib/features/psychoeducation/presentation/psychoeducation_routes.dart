import 'package:go_router/go_router.dart';

import 'admin_psychoeducation_catalog_page.dart';
import 'admin_psychoeducation_editor_page.dart';
import 'psychoeducation_journey_page.dart';
import 'psychoeducation_module_page.dart';
import 'psychoeducation_patient_exercises_page.dart';
import 'coping_cards_page.dart';

/// Rotas da Biblioteca de Psicoeducação (paciente + psicólogo + curadoria admin).
abstract final class PsychoeducationRoutes {
  // Paciente.
  static const patient = '/patient/psychoeducation';
  static const patientCopingCards = '/patient/psychoeducation/coping-cards';
  static String patientModule(String id) => '/patient/psychoeducation/$id';

  // Psicólogo (leitura da referência).
  static const psychologist = '/psychologist/psychoeducation';
  static String patientExercises(String patientId) =>
      '/psychologist/patients/$patientId/psychoeducation-exercises';
  static String psychologistModule(String id) =>
      '/psychologist/psychoeducation/$id';

  // Admin (curadoria).
  static const adminCatalog = '/platform/psychoeducation';
  static const adminNew = '/platform/psychoeducation/new';
  static String adminModule(String id) => '/platform/psychoeducation/$id';
}

List<RouteBase> psychoeducationStaffPatientRoutes() => [
      GoRoute(
        path: 'psychoeducation-exercises',
        builder: (_, state) => PsychoeducationPatientExercisesPage(
          patientId: state.pathParameters['patientId']!,
        ),
      ),
    ];

/// Sub-rotas do paciente (montadas sob /patient).
List<RouteBase> psychoeducationPatientRoutes() {
  return [
    GoRoute(
      path: 'psychoeducation',
      builder: (_, __) => PsychoeducationJourneyPage(
        moduleRouteBuilder: PsychoeducationRoutes.patientModule,
      ),
      routes: [
        GoRoute(
          path: 'coping-cards',
          builder: (_, __) => const CopingCardsPage(),
        ),
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

/// Sub-rotas do psicólogo (leitura; montadas sob /psychologist).
List<RouteBase> psychoeducationPsychologistRoutes() {
  return [
    GoRoute(
      path: 'psychoeducation',
      builder: (_, __) => PsychoeducationJourneyPage(
        moduleRouteBuilder: PsychoeducationRoutes.psychologistModule,
        staffView: true,
      ),
      routes: [
        GoRoute(
          path: ':moduleId',
          builder: (_, state) => PsychoeducationModulePage(
            moduleId: state.pathParameters['moduleId']!,
            staffView: true,
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
