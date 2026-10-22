import '../../profile/domain/profile_role.dart';

abstract final class HealthyResourcesRoutes {
  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/healthy-resources';
      case ProfileRole.patient:
        throw ArgumentError('Módulo não disponível para paciente');
    }
  }
}
