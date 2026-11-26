import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_branding_assets.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/clinics/providers/clinics_providers.dart';
import '../../../features/profile/domain/profile_role.dart';
import '../../../features/profile/presentation/profile_routes.dart';
import '../../../features/user_management/presentation/user_management_page.dart';
import '../../../features/user_management/providers/user_management_providers.dart';
import 'desktop_admin_kit.dart';
import 'desktop_admin_shell.dart';

const _navy = Color(0xFF0D1B3D);
const _navyDeep = Color(0xFF0A1530);
const _brandFill = LinearGradient(
  colors: [Color(0xFF00A39B), Color(0xFF2F6FE4)],
);

// Texto e realces sobre o azul-marinho (igual nos temas claro e escuro).
const _text = Colors.white;
const _textSoft = Color(0xD1FFFFFF);
const _textFaint = Color(0x8CFFFFFF);
const _line = Color(0x1FFFFFFF);
const _hoverFill = Color(0x17FFFFFF);
const _accent = Color(0xFF4FD1C5);

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

/// Menu lateral do admin a partir de 768 px: marca, grupos Gestão (com
/// contadores) e Conteúdo, "Novo acesso", recolher, perfil e versão. Trilho no
/// tablet (e recolhido).
class DesktopAdminMenu extends ConsumerWidget {
  const DesktopAdminMenu({super.key, required this.nav, required this.m});

  final DesktopAdminNav nav;
  final DesktopAdminMetrics m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DesktopAdminTokens.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final openContent = _contentFor(location);
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final name = profile?.fullName ?? 'Administrador';
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

    return ValueListenableBuilder<bool>(
      valueListenable: desktopAdminMenuCollapsed,
      builder: (context, collapsedFlag, _) {
        final tablet = m.tablet;
        final collapsed = !tablet && collapsedFlag;
        final rail = tablet || collapsed;
        final width = collapsed ? 64.0 : m.sb;
        final side = tablet ? 6.0 : (collapsed ? 8.0 : 12.0);

        Widget item(_Item e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _MenuItem(
                item: e,
                m: m,
                rail: rail,
                count: e.nav == null ? null : counts[e.nav],
                selected: openContent != null
                    ? e == openContent
                    : e.nav == nav,
                onTap: () {
                  if (location != e.route) context.go(e.route);
                },
              ),
            );

        return AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: width,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_navy, _navyDeep],
            ),
            border: Border(right: BorderSide(color: t.bd)),
          ),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            child: Padding(
              padding: EdgeInsets.fromLTRB(side, 14, side, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(rail: rail),
                  Expanded(
                    child: SingleChildScrollView(
                      primary: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Group(label: 'GESTÃO', rail: rail),
                          for (final e in _management) item(e),
                          _Group(label: 'CONTEÚDO', rail: rail),
                          for (final e in _content) item(e),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NewAccess(
                    m: m,
                    rail: rail,
                    onTap: () => showNewAccessForm(context, ref),
                  ),
                  if (!tablet) ...[
                    const SizedBox(height: 4),
                    _Collapse(collapsed: collapsed),
                  ],
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.only(top: 10),
                    decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: _line))),
                    child: _Profile(
                      rail: rail,
                      name: name,
                      onTap: () => context.push(ProfileRoutes.me),
                    ),
                  ),
                  if (!rail)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 4),
                      child: Text(EnvConfig.versionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              daText(context, t, size: 10.5, color: _textFaint)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Ícone da marca (cérebro) em quadro branco, ampliado para tirar a margem do
/// arquivo.
class _BrainTile extends StatelessWidget {
  const _BrainTile({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
        border: Border.all(color: _line),
      ),
      child: Transform.scale(
        scale: 1.4,
        child: Image.asset(AppBrandingAssets.icon,
            fit: BoxFit.contain, filterQuality: FilterQuality.medium),
      ),
    );
  }
}

/// Ícone grande e nome em texto.
class _Brand extends StatelessWidget {
  const _Brand({required this.rail});

  final bool rail;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    if (rail) {
      return const Center(child: _BrainTile(size: 48));
    }
    return SizedBox(
      height: 68,
      child: Row(
        children: [
          const _BrainTile(size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text.rich(
                    TextSpan(
                      style: daText(context, t,
                          size: 20, weight: FontWeight.w700, color: _text),
                      children: const [
                        TextSpan(text: 'Esquema'),
                        TextSpan(
                            text: 'Core', style: TextStyle(color: _accent)),
                      ],
                    ),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('raciocínio clínico em mapa',
                      maxLines: 1,
                      style:
                          daText(context, t, size: 10.5, color: _textFaint)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.label, required this.rail});

  final String label;
  final bool rail;

  @override
  Widget build(BuildContext context) {
    if (rail) {
      return Container(
        height: 1,
        margin: const EdgeInsets.fromLTRB(8, 12, 8, 12),
        color: _line,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
      child: Text(label,
          style: daText(context, DesktopAdminTokens.of(context),
                  size: 11, weight: FontWeight.w700, color: _textFaint)
              .copyWith(letterSpacing: 0.9)),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({
    required this.item,
    required this.m,
    required this.rail,
    required this.selected,
    required this.count,
    required this.onTap,
  });

  final _Item item;
  final DesktopAdminMetrics m;
  final bool rail;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final e = widget.item;
    final sel = widget.selected;
    final tablet = widget.m.tablet;
    // Sobre o preenchimento da marca (item aberto) tudo fica branco.
    final fg = sel ? _text : _textSoft;

    final tile = Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: sel
            ? Colors.white.withValues(alpha: 0.16)
            : e.color.withValues(alpha: 0.26),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(e.icon,
          size: 19,
          color: sel ? _text : Color.lerp(e.color, Colors.white, 0.45)),
    );

    final label = Text(e.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: daText(context, t,
            size: tablet
                ? 10.5
                : (widget.m.size == DesktopAdminSize.desktop ? 15 : 14),
            weight: sel ? FontWeight.w700 : FontWeight.w500,
            color: fg));

    final Widget content;
    if (tablet) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          tile,
          const SizedBox(height: 3),
          FittedBox(fit: BoxFit.scaleDown, child: label),
        ],
      );
    } else if (widget.rail) {
      content = Center(child: tile);
    } else {
      content = Row(
        children: [
          const SizedBox(width: 8),
          tile,
          const SizedBox(width: 12),
          Expanded(child: label),
          if (widget.count != null) ...[
            Container(
              constraints: const BoxConstraints(minWidth: 28),
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel
                    ? Colors.white.withValues(alpha: 0.22)
                    : e.color.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text('${widget.count}',
                  style: daText(context, t,
                      size: 11.5, weight: FontWeight.w700, color: fg)),
            ),
            const SizedBox(width: 8),
          ],
        ],
      );
    }

    Widget child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        selected: sel,
        label: e.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: daHoverDuration(context),
            height: tablet ? 62 : 46,
            decoration: BoxDecoration(
              color: sel
                  ? null
                  : (_hover ? _hoverFill : daClear(_hoverFill)),
              gradient: sel ? _brandFill : null,
              borderRadius: BorderRadius.circular(11),
            ),
            child: content,
          ),
        ),
      ),
    );
    if (widget.rail && !tablet) {
      child = Tooltip(
        message: widget.count == null ? e.label : '${e.label} · ${widget.count}',
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: child,
      );
    }
    return child;
  }
}

/// Atalho "Novo acesso": o mesmo formulário da tela Usuários.
class _NewAccess extends StatefulWidget {
  const _NewAccess({
    required this.m,
    required this.rail,
    required this.onTap,
  });

  final DesktopAdminMetrics m;
  final bool rail;
  final VoidCallback onTap;

  @override
  State<_NewAccess> createState() => _NewAccessState();
}

class _NewAccessState extends State<_NewAccess> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    // Realce: um véu sobre o degradê, que parte transparente da própria cor.
    final veil = Colors.white.withValues(alpha: 0.14);
    Widget button = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        label: 'Novo acesso',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Container(
            height: widget.m.tablet ? 48 : 44,
            decoration: BoxDecoration(
              gradient: _brandFill,
              borderRadius: BorderRadius.circular(11),
            ),
            child: AnimatedContainer(
              duration: daHoverDuration(context),
              decoration: BoxDecoration(
                color: _hover ? veil : daClear(veil),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_alt_1_outlined,
                      size: 18, color: _text),
                  if (!widget.rail) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text('Novo acesso',
                          maxLines: 1,
                          style: daText(context, t,
                              size: 14,
                              weight: FontWeight.w700,
                              color: _text)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.rail) {
      button = Tooltip(message: 'Novo acesso', child: button);
    }
    return button;
  }
}

class _Collapse extends StatefulWidget {
  const _Collapse({required this.collapsed});

  final bool collapsed;

  @override
  State<_Collapse> createState() => _CollapseState();
}

class _CollapseState extends State<_Collapse> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.collapsed;
    return Tooltip(
      message: c ? 'Expandir menu' : 'Recolher menu',
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => desktopAdminMenuCollapsed.value = !c,
          child: AnimatedContainer(
            duration: daHoverDuration(context),
            height: 38,
            decoration: BoxDecoration(
              color: _hover ? _hoverFill : daClear(_hoverFill),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisAlignment:
                  c ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (!c) const SizedBox(width: 14),
                const Icon(Icons.view_sidebar_outlined,
                    size: 18, color: _textFaint),
                if (!c) ...[
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text('Recolher menu',
                        maxLines: 1,
                        style: daText(context, DesktopAdminTokens.of(context),
                            weight: FontWeight.w500, color: _textSoft)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Profile extends StatelessWidget {
  const _Profile({
    required this.rail,
    required this.name,
    required this.onTap,
  });

  final bool rail;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1
                ? parts.first.substring(0, 1)
                : parts.first.substring(0, 1) + parts.last.substring(0, 1))
            .toUpperCase();
    Widget row = Row(
      mainAxisAlignment:
          rail ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        DaInitials(initials, size: 36),
        if (!rail) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t,
                        weight: FontWeight.w600, color: _text)),
                Text('Administrador da plataforma',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        daText(context, t, size: 10.5, color: _textFaint)),
              ],
            ),
          ),
        ],
      ],
    );
    row = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
    return rail ? Tooltip(message: name, child: row) : row;
  }
}
