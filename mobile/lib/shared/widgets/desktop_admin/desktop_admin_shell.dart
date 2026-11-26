import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'desktop_admin_kit.dart';
import 'desktop_admin_menu.dart';

export 'desktop_side_menu.dart' show desktopAdminMenuCollapsed;

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

enum DesktopAdminNav { home, clinics, users, patients }

/// Entrada da área de conteúdo: fade-in + subida curta. Menu, barra, abas e
/// fio de gradiente ficam fora dela.
const daContentEntranceKey = ValueKey<String>('da-content-entrance');
const kDaContentEntranceDuration = Duration(milliseconds: 220);
const kDaContentEntranceRise = 8.0;

/// Trava de toque da casca enquanto a rota dela está saindo.
const daLeavingGuardKey = ValueKey<String>('da-leaving-guard');

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
    final shell = Scaffold(
      backgroundColor: t.bg,
      body: DefaultTextStyle(
        style: daText(context, t),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DesktopAdminMenu(nav: nav, m: m),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DesktopTopBar(
                          m: m,
                          title: title,
                          subtitle: subtitle,
                          actions: actions,
                          showCrumb: showCrumb,
                          crumbs: crumbs,
                        ),
                        if (tabs != null) tabs!,
                        Expanded(
                            child: DesktopContentEntrance(
                                child: Material(
                                    type: MaterialType.transparency,
                                    child: body))),
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
    return DesktopHideWhileLeaving(child: shell);
  }
}

/// Anima só o conteúdo: ao montar a tela e quando ela volta a aparecer porque
/// a de cima saiu (voltar). Sem animação com [MediaQuery.disableAnimations].
class DesktopContentEntrance extends StatefulWidget {
  const DesktopContentEntrance({super.key, required this.child});

  final Widget child;

  @override
  State<DesktopContentEntrance> createState() => _DesktopContentEntranceState();
}

class _DesktopContentEntranceState extends State<DesktopContentEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: kDaContentEntranceDuration);
  late final CurvedAnimation _curved =
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);

  /// Animação da rota que cobre esta.
  Animation<double>? _covering;
  bool _animate = true;
  bool _entered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    final covering = ModalRoute.of(context)?.secondaryAnimation;
    if (covering != _covering) {
      _covering?.removeStatusListener(_onCovering);
      _covering = covering?..addStatusListener(_onCovering);
    }
    if (!_animate) {
      _controller.value = 1;
    } else if (!_entered) {
      _controller.forward();
    }
    _entered = true;
  }

  void _onCovering(AnimationStatus status) {
    if (status == AnimationStatus.reverse && _animate) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _covering?.removeStatusListener(_onCovering);
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: daContentEntranceKey,
      opacity: _curved,
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _curved,
        child: widget.child,
        builder: (_, child) => Transform.translate(
          offset: Offset(0, kDaContentEntranceRise * (1 - _curved.value)),
          child: child,
        ),
      ),
    );
  }
}

/// A rota não tem transição de página (a casca fica parada), mas ao voltar a
/// tela que sai ainda ficaria por cima até o fim da rota. Ela some na hora,
/// para a de baixo aparecer já entrando, e deixa de receber toques.
class DesktopHideWhileLeaving extends StatelessWidget {
  const DesktopHideWhileLeaving({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null) return child;
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (_, child) {
        final leaving = animation.status == AnimationStatus.reverse;
        return IgnorePointer(
          key: daLeavingGuardKey,
          ignoring: leaving,
          child: Opacity(opacity: leaving ? 0 : 1, child: child),
        );
      },
    );
  }
}

/// Barra superior da casca: trilha, título, subtítulo e ações.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    required this.m,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.showCrumb = false,
    this.crumbs = const [],
    this.titleTrailing,
  });

  /// Selo logo depois do título (opcional).
  final Widget? titleTrailing;

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
          if (titleTrailing != null) ...[
            const SizedBox(width: 10),
            titleTrailing!,
          ],
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
          duration: daHoverDuration(context),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _hover ? t.hov : daClear(t.hov),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(widget.label,
              style: daText(context, t, color: _hover ? t.tx : t.tx2)),
        ),
      ),
    );
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
