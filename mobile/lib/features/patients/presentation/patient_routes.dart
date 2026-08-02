import '../../../core/router/route_access.dart';
import '../../profile/domain/profile_role.dart';
import '../../patient_invitations/presentation/patient_invitation_routes.dart';

/// Para onde ir depois que o usuário escolhe um paciente na lista.
///
/// Usado quando a lista de pacientes é aberta a partir de um atalho
/// específico (ex.: "Liberar para paciente", "Resultados") em vez do fluxo
/// padrão, que abre o hub de detalhes do paciente.
enum PatientSelectionIntent {
  /// Sem atalho: abre a tela de gestão da carteira, e a escolha leva ao hub
  /// de detalhes do paciente.
  none,

  /// Abre direto a tela de questionários do paciente.
  questionnaires,

  /// Abre direto a tela de resultados do paciente.
  results,

  /// Abre o hub do paciente, de onde saem mapa mental, linha do tempo,
  /// genograma e metas — que vivem em grupos distintos e não têm uma tela
  /// única que as reúna.
  formulation,

  /// Abre direto a lista de recursos terapêuticos do paciente.
  therapyResources,
}

/// Rotas do módulo de pacientes por role (staff apenas).
abstract final class PatientRoutes {
  static String list(ProfileRole role) {
    switch (role) {
      case ProfileRole.platformAdmin:
        // O admin não lê pacientes individuais: a migration 20260720120011
        // tirou esse acesso por privacidade clínica, e a RLS devolve zero
        // linhas. A tela dele é /platform/patient-overview, com contagens
        // agregadas por psicólogo. Lançar aqui evita que alguém reintroduza
        // uma navegação que só levaria a uma lista permanentemente vazia.
        throw StateError(
          'Admin não acessa pacientes individuais — use a visão agregada',
        );
      case ProfileRole.psychologist:
        return '/psychologist/patients';
      case ProfileRole.patient:
        throw StateError('Pacientes não disponível para role patient');
    }
  }

  static String create(ProfileRole role) => '${list(role)}/new';

  static String detail(ProfileRole role, String patientId) =>
      '${list(role)}/$patientId';

  static String edit(ProfileRole role, String patientId) =>
      '${detail(role, patientId)}/edit';

  static String invitationList(ProfileRole role) =>
      PatientInvitationRoutes.list(role);

  static String invitationCreate(ProfileRole role) =>
      PatientInvitationRoutes.create(role);

  static bool isStaffPatientsPath(String location) {
    return location.startsWith('/psychologist/patients') ||
        location.startsWith('/platform/patients');
  }

  static bool pathMatchesRole(String location, ProfileRole role) =>
      RouteAccess.isAllowed(location, role);
}
