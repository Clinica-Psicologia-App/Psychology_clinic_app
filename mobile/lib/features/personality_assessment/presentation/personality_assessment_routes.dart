import '../../profile/domain/profile_role.dart';

/// Rotas do módulo Avaliação → Personalidade (camada terapeuta).
abstract final class PersonalityAssessmentRoutes {
  static String _base(ProfileRole role, String patientId) {
    switch (role) {
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/personality';
      case ProfileRole.platformAdmin:
        throw ArgumentError('Sem rota de personalidade para platform admin.');
      case ProfileRole.patient:
        throw ArgumentError('Personalidade é exclusiva do staff.');
    }
  }

  static String staffList({required ProfileRole role, required String patientId}) =>
      _base(role, patientId);

  static String staffNew({required ProfileRole role, required String patientId}) =>
      '${_base(role, patientId)}/new';

  static String staffDetail({
    required ProfileRole role,
    required String patientId,
    required String assessmentId,
  }) =>
      '${_base(role, patientId)}/$assessmentId';

  static String staffEdit({
    required ProfileRole role,
    required String patientId,
    required String assessmentId,
  }) =>
      '${_base(role, patientId)}/$assessmentId/edit';

  static String staffSynthesis({
    required ProfileRole role,
    required String patientId,
    required String assessmentId,
  }) =>
      '${_base(role, patientId)}/$assessmentId/synthesis';
}
