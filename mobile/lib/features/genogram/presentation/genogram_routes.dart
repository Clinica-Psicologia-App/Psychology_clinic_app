import '../../profile/domain/profile_role.dart';

abstract final class GenogramRoutes {
  static const patientList = '/patient/genogram';
  static const patientPersonCreate = '/patient/genogram/people/new';
  static const patientRelationshipCreate =
      '/patient/genogram/relationships/new';

  static String patientPersonDetail(String personId) =>
      '/patient/genogram/people/$personId';

  static String patientPersonEdit(String personId) =>
      '/patient/genogram/people/$personId/edit';

  static String patientRelationshipDetail(String relationshipId) =>
      '/patient/genogram/relationships/$relationshipId';

  static String patientRelationshipEdit(String relationshipId) =>
      '/patient/genogram/relationships/$relationshipId/edit';

  static String staffList({
    required ProfileRole role,
    required String patientId,
  }) {
    switch (role) {
      case ProfileRole.platformAdmin:
        throw ArgumentError('Use rotas globais para platform admin');
      case ProfileRole.psychologist:
        return '/psychologist/patients/$patientId/genogram';
      case ProfileRole.patient:
        throw ArgumentError('Use patientList para role patient');
    }
  }

  static String staffPersonCreate({
    required ProfileRole role,
    required String patientId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/people/new';

  static String staffRelationshipCreate({
    required ProfileRole role,
    required String patientId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/relationships/new';

  static String staffPersonDetail({
    required ProfileRole role,
    required String patientId,
    required String personId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/people/$personId';

  static String staffPersonEdit({
    required ProfileRole role,
    required String patientId,
    required String personId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/people/$personId/edit';

  static String staffRelationshipDetail({
    required ProfileRole role,
    required String patientId,
    required String relationshipId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/relationships/$relationshipId';

  static String staffRelationshipEdit({
    required ProfileRole role,
    required String patientId,
    required String relationshipId,
  }) =>
      '${staffList(role: role, patientId: patientId)}/relationships/$relationshipId/edit';

  // Bootstrap: rota STANDALONE (top-level), não aninhada sob a página do
  // construtor — assim navegar do painel/diagrama (outro branch) não reconstrói
  // a página-pai nem colide GlobalKey.
  static const bootstrapByPath = '/psychologist/genogram-bootstrap/:patientId';
  static String bootstrapFor(String patientId) =>
      '/psychologist/genogram-bootstrap/$patientId';

  // Edição de pessoa STANDALONE (topo-nível), para abrir a partir do diagrama
  // sem reconstruir StaffPatientGenogramPage (evita o crash de GlobalKey que
  // acontecia ao cruzar de branch). Mesmo padrão do bootstrap.
  static const personEditByPath =
      '/psychologist/genogram-person-edit/:patientId/:personId';
  static String personEditFor(String patientId, String personId) =>
      '/psychologist/genogram-person-edit/$patientId/$personId';
}
