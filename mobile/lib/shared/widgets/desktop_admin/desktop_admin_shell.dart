import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_branding_assets.dart';
import '../../../features/auth/providers/auth_providers.dart';
import '../../../features/profile/presentation/profile_routes.dart';
import 'desktop_admin_kit.dart';

/// Localizações do admin que já usam a casca de desktop. O [AppNavShell]
/// antigo não desenha o próprio menu nelas (a casca tem o seu). As demais
/// telas entram aqui nas etapas seguintes.
const desktopAdminLocations = <String>{
  '/platform',
  '/platform/users',
  '/platform/clinics',
  '/platform/patient-overview',
  '/platform/plans',
  '/platform/questionnaires',
  '/platform/questionnaire-catalog',
  '/platform/library',
  '/platform/psychoeducation',
};

/// Editor do questionário (`.../questionnaire-catalog/new` e `/:id`) usa a
/// casca; a prévia (`.../preview`) é tela cheia, sem casca.
bool usesDesktopAdminShell(String location, double width) {
  if (width < kDesktopAdminMinWidth) return false;
  if (desktopAdminLocations.contains(location)) return true;
  const catalog = '/platform/questionnaire-catalog/';
  if (location.startsWith(catalog)) return !location.endsWith('/preview');
  // Editores da Biblioteca e da Psicoeducação (new e /:id).
  return location.startsWith('/platform/library/') ||
      location.startsWith('/platform/psychoeducation/');
}

/// O layout é do admin desktop (casca ou prévia em tela cheia): o menu
/// antigo do [AppNavShell] não deve aparecer.
bool desktopAdminOwnsLayout(String location, double width) =>
    usesDesktopAdminShell(location, width) ||
    (width >= kDesktopAdminMinWidth &&
        location.startsWith('/platform/questionnaire-catalog/') &&
        location.endsWith('/preview'));

/// Item da trilha de navegação da barra superior.
class DaCrumb {
  const DaCrumb(this.label, this.route);
  final String label;
  final String route;
}

/// Menu recolhido (só ≥ 1024). Vive na sessão para não "pular" ao navegar.
final ValueNotifier<bool> desktopAdminMenuCollapsed = ValueNotifier(false);

enum DesktopAdminNav { home, clinics, users, patients }

class _NavEntry {
  const _NavEntry(this.id, this.icon, this.label, this.route);
  final DesktopAdminNav id;
  final IconData icon;
  final String label;
  final String route;
}

const _entries = [
  _NavEntry(DesktopAdminNav.home, Icons.home_outlined, 'Início', '/platform'),
  _NavEntry(DesktopAdminNav.clinics, Icons.apartment_outlined, 'Clínicas',
      '/platform/clinics'),
  _NavEntry(DesktopAdminNav.users, Icons.badge_outlined, 'Usuários',
      '/platform/users'),
  _NavEntry(DesktopAdminNav.patients, Icons.people_outline, 'Pacientes',
      '/platform/patient-overview'),
];

/// Casca do administrador a partir de 768 px: menu lateral (recolhível; trilho
/// de 76 px no tablet), barra superior com trilha, título, subtítulo e ações.
class DesktopAdminShell extends ConsumerWidget {
  const DesktopAdminShell({
    super.key,
    required this.nav,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.showCrumb = true,
    this.crumbs = const [DaCrumb('Início', '/platform')],
    this.tabs,
  });

  final DesktopAdminNav nav;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget body;
  final bool showCrumb;

  /// Trilha antes do título (padrão: Início ›).
  final List<DaCrumb> crumbs;

  /// Abas sublinhadas logo abaixo da barra superior (opcional).
  final Widget? tabs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return Scaffold(
      backgroundColor: t.bg,
      body: DefaultTextStyle(
        style: daText(context, t),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Sidebar(nav: nav, m: m),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _TopBar(
                          m: m,
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          showCrumb: showCrumb,
                          crumbs: crumbs,
                        ),
                        if (tabs != null) tabs!,
                        Expanded(
                            child: Material(
                                type: MaterialType.transparency,
                                child: body)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(gradient: DesktopAdminTokens.brandGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.m,
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.showCrumb,
    required this.crumbs,
  });

  final List<DaCrumb> crumbs;
  final DesktopAdminMetrics m;
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final bool showCrumb;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      height: m.tb,
      padding: EdgeInsets.symmetric(horizontal: m.pad),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd))),
      child: Row(
        children: [
          if (showCrumb)
            for (final c in crumbs) ...[
              _Crumb(label: c.label, onTap: () => context.go(c.route)),
              Icon(Icons.chevron_right, size: 15, color: t.tx3),
              const SizedBox(width: 4),
            ],
          Text(
            title,
            style: daText(context, t,
                size: m.size == DesktopAdminSize.desktop ? 18 : 16,
                weight: FontWeight.w600),
          ),
          if (subtitle != null && !m.tablet)
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: 16),
                  padding: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: t.bd2))),
                  child: Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t, color: t.tx3)),
                ),
              ),
            )
          else
            const Spacer(),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            actions[i],
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatefulWidget {
  const _Crumb({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_Crumb> createState() => _CrumbState();
}

class _CrumbState extends State<_Crumb> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hover ? t.hov : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(widget.label,
              style: daText(context, t, color: _hover ? t.tx : t.tx2)),
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.nav, required this.m});

  final DesktopAdminNav nav;
  final DesktopAdminMetrics m;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = DesktopAdminTokens.of(context);
    final profile = ref.watch(authControllerProvider).valueOrNull;
    return ValueListenableBuilder<bool>(
      valueListenable: desktopAdminMenuCollapsed,
      builder: (context, collapsedFlag, _) {
        final tablet = m.tablet;
        final collapsed = !tablet && collapsedFlag;
        final width = tablet ? m.sb : (collapsed ? 64.0 : m.sb);
        final rail = tablet || collapsed;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: width,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: t.side,
            border: Border(right: BorderSide(color: t.bd)),
          ),
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  tablet ? 6 : (collapsed ? 11 : 12), 18, tablet ? 6 : (collapsed ? 11 : 12), 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Brand(rail: rail),
                  if (!rail)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
                      child: Text('PLATAFORMA',
                          style: daText(context, t,
                              size: 10.5,
                              weight: FontWeight.w600,
                              color: t.tx3)
                              .copyWith(letterSpacing: 0.84)),
                    )
                  else
                    SizedBox(height: tablet ? 18 : 24),
                  for (final e in _entries)
                    Padding(
                      padding: EdgeInsets.only(bottom: tablet ? 4 : 2),
                      child: _NavItem(
                        entry: e,
                        selected: e.id == nav,
                        rail: rail,
                        tablet: tablet,
                        m: m,
                      ),
                    ),
                  const Spacer(),
                  if (!tablet)
                    _CollapseButton(collapsed: collapsed, m: m),
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: t.bd))),
                    child: _Footer(
                      rail: rail,
                      name: profile?.fullName ?? 'Administrador',
                      initials: _initials(profile?.fullName ?? 'Administrador'),
                      onTap: () => context.push(ProfileRoutes.me),
                    ),
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

String _initials(String name) {
  final p = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (p.isEmpty) return '?';
  if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
  return (p.first.substring(0, 1) + p.last.substring(0, 1)).toUpperCase();
}

class _Brand extends StatelessWidget {
  const _Brand({required this.rail});

  final bool rail;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment:
            rail ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          if (!rail) const SizedBox(width: 4),
          Image.asset(AppBrandingAssets.icon,
              width: 32, height: 32, fit: BoxFit.contain),
          if (!rail) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    maxLines: 1,
                    text: TextSpan(
                      style: daText(context, t, size: 15, weight: FontWeight.w700),
                      children: [
                        const TextSpan(text: 'Esquema'),
                        TextSpan(text: 'Core', style: TextStyle(color: t.tq)),
                      ],
                    ),
                  ),
                  Text('raciocínio clínico em mapa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t, size: 10.5, color: t.tx3)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.entry,
    required this.selected,
    required this.rail,
    required this.tablet,
    required this.m,
  });

  final _NavEntry entry;
  final bool selected;
  final bool rail;
  final bool tablet;
  final DesktopAdminMetrics m;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final e = widget.entry;
    final sel = widget.selected;
    final fg = sel || _hover ? t.tx : t.tx2;
    final icon = Icon(e.icon, size: widget.tablet ? 20 : 18, color: sel ? t.tq : fg);
    final label = Text(e.label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: daText(context, t,
            size: widget.tablet ? 10.5 : null,
            weight: widget.tablet ? FontWeight.w500 : (sel ? FontWeight.w600 : FontWeight.w500),
            color: fg));
    Widget content = widget.tablet
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [icon, const SizedBox(height: 3), label],
          )
        : Row(
            mainAxisAlignment:
                widget.rail ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (!widget.rail) const SizedBox(width: 12),
              icon,
              if (!widget.rail) ...[const SizedBox(width: 12), Flexible(child: label)],
            ],
          );
    Widget item = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        selected: sel,
        label: e.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!sel) context.go(e.route);
          },
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: double.infinity,
                height: widget.tablet ? 58 : widget.m.ctl,
                decoration: BoxDecoration(
                  color: sel ? t.rz : (_hover ? t.hov2 : Colors.transparent),
                  border: Border.all(
                      color: sel ? t.bd2 : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: content,
              ),
              if (sel)
                Positioned(
                  left: 0,
                  top: 9,
                  bottom: 9,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          DesktopAdminTokens.teal,
                          DesktopAdminTokens.blue,
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (widget.rail && !widget.tablet) {
      item = Tooltip(
          message: e.label,
          preferBelow: false,
          waitDuration: const Duration(milliseconds: 400),
          child: item);
    }
    return item;
  }
}

class _CollapseButton extends StatefulWidget {
  const _CollapseButton({required this.collapsed, required this.m});

  final bool collapsed;
  final DesktopAdminMetrics m;

  @override
  State<_CollapseButton> createState() => _CollapseButtonState();
}

class _CollapseButtonState extends State<_CollapseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
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
            duration: const Duration(milliseconds: 150),
            height: widget.m.ctl,
            decoration: BoxDecoration(
              color: _hover ? t.hov2 : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment:
                  c ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                if (!c) const SizedBox(width: 12),
                Icon(Icons.view_sidebar_outlined, size: 18, color: t.tx3),
                if (!c) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text('Recolher menu',
                        maxLines: 1,
                        style: daText(context, t,
                            weight: FontWeight.w500, color: t.tx3)),
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.rail,
    required this.name,
    required this.initials,
    required this.onTap,
  });

  final bool rail;
  final String name;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final avatar = DaInitials(initials);
    Widget row = Row(
      mainAxisAlignment:
          rail ? MainAxisAlignment.center : MainAxisAlignment.start,
      children: [
        if (!rail) const SizedBox(width: 4),
        avatar,
        if (!rail) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t, weight: FontWeight.w600)),
                Text('Administrador da plataforma',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t, size: 11, color: t.tx3)),
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


/// Abas sublinhadas (Catálogo | Permissões): o item ativo tem fio de 2 px com
/// o gradiente da marca.
class DaTabs extends StatelessWidget {
  const DaTabs({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<(IconData, String)> items;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: m.pad),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd))),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Semantics(
                  button: true,
                  selected: i == selected,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i != selected) onChanged(i);
                    },
                    child: Container(
                      height: m.ctl,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i == selected
                              ? const BorderSide(
                                  color: DesktopAdminTokens.teal, width: 2)
                              : const BorderSide(
                                  color: Colors.transparent, width: 2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(items[i].$1,
                              size: 16, color: i == selected ? t.tq : t.tx2),
                          const SizedBox(width: 8),
                          Text(items[i].$2,
                              style: daText(context, t,
                                  weight: i == selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: i == selected ? t.tx : t.tx2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
