import '../../profile/domain/profile_role.dart';

abstract final class ResultRoutes {
  static String list({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw StateError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/results';
      case ProfileRole.patient:
        // O paciente vê apenas os próprios resultados liberados; a rota
        // resolve o patientId internamente.
        return '/patient/results';
    }
  }

  static String detail({
    required ProfileRole role,
    required String patientId,
    required String responseId,
  }) {
    return '${list(role: role, patientId: patientId)}/$responseId';
  }
}
