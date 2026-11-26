import 'package:flutter/material.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_branding_assets.dart';
import 'desktop_admin_kit.dart';

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

/// Menu recolhido (só ≥ 1024). Vive na sessão para não "pular" ao navegar.
final ValueNotifier<bool> desktopAdminMenuCollapsed = ValueNotifier(false);

/// Item do menu lateral.
class DaMenuEntry {
  const DaMenuEntry({
    required this.icon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final String label;

  /// Cor do módulo.
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  /// Contador à direita (menu aberto) e na dica (menu recolhido).
  final int? count;
}

/// Grupo do menu, com rótulo em caixa alta.
class DaMenuGroup {
  const DaMenuGroup(this.label, this.entries);

  final String label;
  final List<DaMenuEntry> entries;
}

/// Menu lateral marinho a partir de 768 px (administrador e psicóloga): marca,
/// grupos com contadores, ação principal, recolher, perfil e versão. Trilho no
/// tablet (e recolhido).
class DesktopSideMenu extends StatelessWidget {
  const DesktopSideMenu({
    super.key,
    required this.m,
    required this.groups,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
    required this.profileName,
    required this.profileRole,
    required this.onProfileTap,
  });

  final DesktopAdminMetrics m;
  final List<DaMenuGroup> groups;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;
  final String profileName;
  final String profileRole;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return ValueListenableBuilder<bool>(
      valueListenable: desktopAdminMenuCollapsed,
      builder: (context, collapsedFlag, _) {
        final tablet = m.tablet;
        final collapsed = !tablet && collapsedFlag;
        final rail = tablet || collapsed;
        final width = collapsed ? 64.0 : m.sb;
        final side = tablet ? 6.0 : (collapsed ? 8.0 : 12.0);

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
                          for (final g in groups) ...[
                            _Group(label: g.label, rail: rail),
                            for (final e in g.entries)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: _MenuItem(item: e, m: m, rail: rail),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _Action(
                    m: m,
                    rail: rail,
                    label: actionLabel,
                    icon: actionIcon,
                    onTap: onAction,
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
                      name: profileName,
                      role: profileRole,
                      onTap: onProfileTap,
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
  });

  final DaMenuEntry item;
  final DesktopAdminMetrics m;
  final bool rail;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final e = widget.item;
    final sel = e.selected;
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
          if (e.count != null) ...[
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
              child: Text('${e.count}',
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
          onTap: e.onTap,
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
        message: e.count == null ? e.label : '${e.label} · ${e.count}',
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 400),
        child: child,
      );
    }
    return child;
  }
}

/// Ação principal no pé do menu ("Novo acesso", "Novo paciente").
class _Action extends StatefulWidget {
  const _Action({
    required this.m,
    required this.rail,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final DesktopAdminMetrics m;
  final bool rail;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_Action> createState() => _ActionState();
}

class _ActionState extends State<_Action> {
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
        label: widget.label,
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
                  Icon(widget.icon, size: 18, color: _text),
                  if (!widget.rail) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(widget.label,
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
      button = Tooltip(message: widget.label, child: button);
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
    required this.role,
    required this.onTap,
  });

  final bool rail;
  final String name;
  final String role;
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
                Text(role,
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
