import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import 'patient_library_page.dart';
import 'staff_library_catalog_page.dart';
import 'staff_library_work_page.dart';

/// Rotas da Biblioteca (paciente + catálogo clínico do psicólogo).
abstract final class PatientLibraryRoutes {
  static const patient = '/patient/library-stream';

  static String staffCatalog({
    required ProfileRole role,
    required String patientId,
  }) =>
      '/psychologist/patients/$patientId/library';

  static String staffWork({
    required ProfileRole role,
    required String patientId,
    required String workId,
  }) =>
      '/psychologist/patients/$patientId/library/$workId';
}

List<RouteBase> patientLibraryRoutes() {
  return [
    GoRoute(
      path: 'library-stream',
      builder: (_, __) => const PatientLibraryPage(),
    ),
  ];
}

List<RouteBase> staffPatientLibraryRoutes({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'library',
      builder: (context, state) => StaffLibraryCatalogPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: ':workId',
          builder: (context, state) => StaffLibraryWorkPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            workId: state.pathParameters['workId']!,
          ),
        ),
      ],
    ),
  ];
}
