import '../../profile/domain/profile_role.dart';

abstract final class QuestionnaireRoutes {
  static const adminAccess = '/platform/questionnaire-access';

  /// Catálogo de instrumentos (platform admin).
  static const adminCatalog = '/platform/questionnaire-catalog';

  /// Criação de um novo instrumento.
  static const adminCatalogNew = '$adminCatalog/new';

  /// Edição de um instrumento existente.
  static String adminCatalogDetail(String questionnaireId) =>
      '$adminCatalog/$questionnaireId';

  static String list({
    required ProfileRole role,
    String? patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.patient:
        return '/patient/questionnaires';
      case ProfileRole.psychologist:
        if (patientId == null) {
          throw ArgumentError('patientId obrigatório para psychologist');
        }
        return '/psychologist/patients/$patientId/questionnaires';
    }
  }

  static String intro({
    required ProfileRole role,
    String? patientId,
  }) {
    return '${list(role: role, patientId: patientId)}/intro';
  }

  static String answer({
    required ProfileRole role,
    String? patientId,
  }) {
    return '${list(role: role, patientId: patientId)}/answer';
  }

  static String success({
    required ProfileRole role,
    String? patientId,
  }) {
    return '${list(role: role, patientId: patientId)}/success';
  }

  static bool isQuestionnairePath(String location) {
    return location.contains('/questionnaires');
  }
}
