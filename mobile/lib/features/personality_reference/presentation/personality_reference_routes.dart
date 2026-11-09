import '../../profile/domain/profile_role.dart';

abstract final class PersonalityReferenceRoutes {
  /// Guia clínico aberto no cartão de uma faceta (índices na ordem do guia).
  static String staffFacet({
    required ProfileRole role,
    required String patientId,
    required int factorIndex,
    required int facetIndex,
  }) =>
      '${staffList(role: role, patientId: patientId)}'
      '?factor=$factorIndex&facet=$facetIndex';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/personality-reference';
      case ProfileRole.patient:
        throw ArgumentError(
            'Personalidade estática não é exposta ao paciente.');
    }
  }
}
