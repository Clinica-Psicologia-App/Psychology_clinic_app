import 'package:go_router/go_router.dart';

import 'patient_library_page.dart';

/// Rotas da Biblioteca do paciente (estilo streaming).
abstract final class PatientLibraryRoutes {
  static const patient = '/patient/library-stream';
}

List<RouteBase> patientLibraryRoutes() {
  return [
    GoRoute(
      path: 'library-stream',
      builder: (_, __) => const PatientLibraryPage(),
    ),
  ];
}
