import '../../profile/domain/profile_role.dart';

abstract final class MentalMapRoutes {
  static const patientList = '/patient/mental-map';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/mental-map';
      case ProfileRole.patient:
        throw ArgumentError('Use patientList para role patient');
    }
  }

  /// Síntese "Conceitualização de caso" (módulo Síntese, lente do terapeuta).
  static String staffCaseConceptualization({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/case-conceptualization';
      case ProfileRole.platformAdmin:
      case ProfileRole.patient:
        throw ArgumentError('Conceitualização de caso é exclusiva do psicólogo');
    }
  }

  /// Edição dos campos do terapeuta da Conceitualização de caso.
  ///
  /// [focus] (ex.: `7.1`, `10`) rola o editor até o cartão do item.
  static String staffCaseConceptualizationEdit({
    required ProfileRole role,
    required String patientId,
    String? focus,
  }) {
    final base =
        '${staffCaseConceptualization(role: role, patientId: patientId)}/edit';
    return focus == null ? base : '$base?focus=$focus';
  }
}
