import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/clinics/providers/clinics_providers.dart';
import '../../../features/profile/domain/profile_role.dart';
import '../../../features/profile/presentation/profile_routes.dart';
import '../../../features/user_management/presentation/user_management_page.dart';
import '../../../features/user_management/providers/user_management_providers.dart';
import 'desktop_admin_kit.dart';
import 'desktop_admin_shell.dart';
import 'desktop_side_menu.dart';

class _Item {
  const _Item(this.icon, this.label, this.route, this.color, {this.nav});

  final IconData icon;
  final String label;
  final String route;

  /// Cor do módulo.
  final Color color;

  /// Itens de gestão são marcados pela tela; os de conteúdo, pela rota.
  final DesktopAdminNav? nav;
}

const _management = [
  _Item(Icons.home_outlined, 'Início', '/platform', DesktopAdminTokens.teal,
      nav: DesktopAdminNav.home),
  _Item(Icons.apartment_outlined, 'Clínicas', '/platform/clinics',
      DesktopAdminTokens.blue,
      nav: DesktopAdminNav.clinics),
  _Item(Icons.badge_outlined, 'Usuários', '/platform/users',
      DesktopAdminTokens.purple,
      nav: DesktopAdminNav.users),
  _Item(Icons.people_outline, 'Pacientes', '/platform/patient-overview',
      DesktopAdminTokens.cyan,
      nav: DesktopAdminNav.patients),
];

const _content = [
  _Item(Icons.library_books_outlined, 'Questionários',
      '/platform/questionnaire-catalog', Color(0xFFF59E0B)),
  _Item(Icons.movie_filter_outlined, 'Biblioteca', '/platform/library',
      Color(0xFFEC4899)),
  _Item(Icons.auto_stories_outlined, 'Psicoeducação',
      '/platform/psychoeducation', Color(0xFF10B981)),
];

/// Item de conteúdo aberto (a aba Permissões é parte de Questionários).
_Item? _contentFor(String location) {
  if (location == '/platform/questionnaires') return _content.first;
  for (final item in _content) {
    if (location == item.route || location.startsWith('${item.route}/')) {
      return item;
    }
  }
  return null;
}

/// Menu lateral do admin a partir de 768 px: o [DesktopSideMenu] com os grupos
/// Gestão (com contadores) e Conteúdo e a ação "Novo acesso".
class DesktopAdminMenu extends ConsumerWidget {
  const DesktopAdminMenu({super.key, required this.nav, required this.m});

  final DesktopAdminNav nav;
  final DesktopAdminMetrics m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final openContent = _contentFor(location);
    final profile = ref.watch(authControllerProvider).valueOrNull;
    // Mesmos providers (e mesmas contas) do Início, que fica por baixo de
    // todas as telas do admin: nenhuma consulta nova.
    final clinics = ref.watch(clinicsProvider).valueOrNull;
    final users = ref.watch(clinicUsersProvider).valueOrNull;
    final counts = <DesktopAdminNav, int?>{
      DesktopAdminNav.clinics: clinics?.length,
      DesktopAdminNav.users: users?.length,
      DesktopAdminNav.patients: users
          ?.where((u) => u.role == ProfileRole.psychologist)
          .fold<int>(0, (sum, u) => sum + u.assignedPatientsCount),
    };

    DaMenuEntry entry(_Item e) => DaMenuEntry(
          icon: e.icon,
          label: e.label,
          color: e.color,
          count: e.nav == null ? null : counts[e.nav],
          selected:
              openContent != null ? e == openContent : e.nav == nav,
          onTap: () {
            if (location != e.route) context.go(e.route);
          },
        );

    return DesktopSideMenu(
      m: m,
      groups: [
        DaMenuGroup('GESTÃO', [for (final e in _management) entry(e)]),
        DaMenuGroup('CONTEÚDO', [for (final e in _content) entry(e)]),
      ],
      actionLabel: 'Novo acesso',
      actionIcon: Icons.person_add_alt_1_outlined,
      onAction: () => showNewAccessForm(context, ref),
      profileName: profile?.fullName ?? 'Administrador',
      profileRole: 'Administrador da plataforma',
      onProfileTap: () => context.push(ProfileRoutes.me),
    );
  }
}
