import '../../profile/domain/profile_role.dart';

abstract final class PersonalityReferenceRoutes {
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
