import '../../profile/domain/profile_role.dart';

abstract final class InitialAssessmentRoutes {
  // Tela 1 — Conhecendo Você
  static const patient = '/patient/initial-assessment';

  // Tela 2 — Minha História (Linha do Tempo)
  static const patientHistory = '/patient/initial-assessment/history';

  // Tela 3 — Minha Família (Genograma)
  static const patientFamily = '/patient/initial-assessment/family';

  static String staff({
    required ProfileRole role,
    required String patientId,
  }) =>
      _staffBase(role: role, patientId: patientId);

  static String staffHistory({
    required ProfileRole role,
    required String patientId,
  }) =>
      '${_staffBase(role: role, patientId: patientId)}/history';

  static String staffFamily({
    required ProfileRole role,
    required String patientId,
  }) =>
      '${_staffBase(role: role, patientId: patientId)}/family';

  static String _staffBase({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/initial-assessment';
      case ProfileRole.platformAdmin:
        throw ArgumentError('Sem rota de admin para avaliação inicial.');
      case ProfileRole.patient:
        throw ArgumentError('Use patient para role patient.');
    }
  }
}
