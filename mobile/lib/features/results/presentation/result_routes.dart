import '../../profile/domain/profile_role.dart';

abstract final class ResultRoutes {
  static String list({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.admin:
        return '/admin/patients/$patientId/results';
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/results';
      case ProfileRole.patient:
        throw StateError('Paciente não acessa resultados nesta etapa');
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
