import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/patient_invitations/presentation/patient_invitation_routes.dart';
import '../../../features/patient_invitations/providers/patient_invitations_providers.dart';
import '../../../features/patients/presentation/patient_routes.dart';
import '../../../features/patients/providers/patients_providers.dart';
import '../../../features/profile/domain/profile_role.dart';
import '../../../features/profile/presentation/profile_routes.dart';
import '../../../features/questionnaires/presentation/questionnaire_routes.dart';
import '../desktop_admin/desktop_admin_kit.dart';
import '../desktop_admin/desktop_side_menu.dart';

/// Menu lateral da psicóloga a partir de 768 px: o mesmo [DesktopSideMenu] do
/// administrador, com os grupos Atendimento (com contadores) e Recursos e a
/// ação "Novo paciente".
class DesktopPsychologistMenu extends ConsumerWidget {
  const DesktopPsychologistMenu({
    super.key,
    required this.location,
    required this.home,
    required this.m,
    required this.leave,
  });

  /// Endereço aberto.
  final String location;

  /// Endereço do Início (prefixo de todos os outros).
  final String home;
  final DesktopAdminMetrics m;

  /// Executa a navegação respeitando a confirmação da tela aberta: [go] numa
  /// tela comum; [leaving] (se vier) depois que uma tela com confirmação aceita
  /// a saída.
  final Future<void> Function(VoidCallback go, {VoidCallback? leaving}) leave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).valueOrNull;
    // Mesmos providers (e mesmas contas) do Início, que fica por baixo de
    // todas as telas da psicóloga: nenhuma consulta nova.
    final patients = ref.watch(patientsListProvider).valueOrNull;
    final invitations = ref.watch(patientInvitationsListProvider).valueOrNull;

    DaMenuEntry entry(IconData icon, String label, Color color, String route,
            [int? count]) =>
        DaMenuEntry(
          icon: icon,
          label: label,
          color: color,
          count: count,
          selected: location == route ||
              (route != home && location.startsWith('$route/')),
          onTap: () {
            if (location != route) leave(() => context.go(route));
          },
        );

    final newPatient = PatientRoutes.create(ProfileRole.psychologist);

    return DesktopSideMenu(
      m: m,
      groups: [
        DaMenuGroup('ATENDIMENTO', [
          entry(Icons.home_outlined, 'Início', DesktopAdminTokens.teal, home),
          entry(
            Icons.people_outline,
            'Pacientes',
            DesktopAdminTokens.blue,
            PatientRoutes.list(ProfileRole.psychologist),
            patients?.where((p) => p.isActive).length,
          ),
          entry(
            Icons.mark_email_unread_outlined,
            'Convites',
            DesktopAdminTokens.purple,
            PatientInvitationRoutes.list(ProfileRole.psychologist),
            invitations?.where((i) => i.isPending).length,
          ),
        ]),
        DaMenuGroup('RECURSOS', [
          entry(
            Icons.assignment_outlined,
            'Questionários',
            const Color(0xFFF59E0B),
            QuestionnaireRoutes.psychologistCatalog,
          ),
        ]),
      ],
      actionLabel: 'Novo paciente',
      actionIcon: Icons.person_add_alt_1_outlined,
      onAction: () {
        if (location == newPatient) return;
        // Empilha como hoje; saindo de uma tela com descarte confirmado, ela
        // não pode continuar por baixo.
        leave(
          () => context.push(newPatient),
          leaving: () => context.go(newPatient),
        );
      },
      profileName: profile?.fullName ?? 'Profissional',
      profileRole: 'Profissional',
      onProfileTap: () => context.push(ProfileRoutes.me),
    );
  }
}
