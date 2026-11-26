import 'package:flutter/material.dart';

import '../app_motion.dart';
import 'desktop_admin_kit.dart';
import 'desktop_admin_shell.dart';

/// Atalho do Início do admin (mesmos títulos, textos e destinos do celular).
class DesktopAdminShortcut {
  const DesktopAdminShortcut({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.count,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  /// Contador antes da seta (Início da psicóloga).
  final int? count;
}

/// Um número do painel do Início: ícone, cor, valor ("—" sem valor) e rótulo.
typedef DesktopKpi = (IconData, Color, int?, String);

/// Início do admin em desktop: saudação, 3 números e atalhos em grade plana.
class DesktopAdminHome extends StatelessWidget {
  const DesktopAdminHome({
    super.key,
    required this.name,
    required this.greeting,
    required this.clinicsCount,
    required this.usersCount,
    required this.patientsCount,
    required this.attendance,
    required this.structure,
  });

  final String name;
  final String greeting;
  final int? clinicsCount;
  final int? usersCount;
  final int? patientsCount;
  final List<DesktopAdminShortcut> attendance;
  final List<DesktopAdminShortcut> structure;

  @override
  Widget build(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final big = m.size == DesktopAdminSize.desktop;
    return DesktopAdminShell(
      nav: DesktopAdminNav.home,
      title: 'Início',
      showCrumb: false,
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(m.pad, big ? 24 : 18, m.pad, 32),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: big ? 1400 : 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MotionReveal(
                  delay: staggerDelay(0),
                  child: DesktopGreeting(
                    name: name,
                    greeting: greeting,
                    subtitle: 'Administrador da plataforma',
                    big: big,
                  ),
                ),
                const SizedBox(height: 20),
                MotionReveal(
                  delay: staggerDelay(1),
                  child: DesktopKpis(
                    big: big,
                    cells: [
                      (
                        Icons.apartment_outlined,
                        DesktopAdminTokens.blue,
                        clinicsCount,
                        'clínicas'
                      ),
                      (
                        Icons.badge_outlined,
                        DesktopAdminTokens.purple,
                        usersCount,
                        'usuários'
                      ),
                      (
                        Icons.people_outline,
                        const Color(0xFF00A39B),
                        patientsCount,
                        'pacientes'
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                MotionReveal(
                  delay: staggerDelay(2),
                  child: DesktopShortcutSection(
                    title: 'Atendimento',
                    subtitle:
                        'Fluxos ligados diretamente ao cuidado dos pacientes.',
                    items: attendance,
                    columns: 2,
                    big: big,
                  ),
                ),
                const SizedBox(height: 24),
                MotionReveal(
                  delay: staggerDelay(3),
                  child: DesktopShortcutSection(
                    title: 'Estrutura da plataforma',
                    subtitle:
                        'Configurações globais, acessos administrativos e instrumentos.',
                    items: structure,
                    columns: m.tablet ? 2 : 3,
                    big: big,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Saudação do Início: avatar (iniciais, se [leading] não vier), período do
/// dia, nome em degradê e uma linha de contexto.
class DesktopGreeting extends StatelessWidget {
  const DesktopGreeting({
    super.key,
    required this.name,
    required this.greeting,
    required this.subtitle,
    required this.big,
    this.leading,
  });

  final String name;
  final String greeting;
  final String subtitle;
  final bool big;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final initials = () {
      final p = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
      if (p.isEmpty) return '?';
      if (p.length == 1) return p.first.substring(0, 1).toUpperCase();
      return (p.first.substring(0, 1) + p.last.substring(0, 1)).toUpperCase();
    }();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          leading ?? DaInitials(initials, size: 44),
          const SizedBox(width: 16),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: daText(context, t,
                            size: 11, weight: FontWeight.w600, color: t.tx3)
                        .copyWith(letterSpacing: 1.1)),
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (r) => const LinearGradient(
                    colors: [
                      Color(0xFF00A39B),
                      DesktopAdminTokens.blue,
                      DesktopAdminTokens.purple,
                    ],
                    stops: [0, 0.5, 1],
                  ).createShader(r),
                  child: Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t,
                              size: big ? 36 : 28,
                              weight: FontWeight.w700,
                              color: Colors.white)
                          .copyWith(letterSpacing: -0.6, height: 1.15)),
                ),
                Text(subtitle, style: daText(context, t, color: t.tx2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Três números lado a lado, com divisórias.
class DesktopKpis extends StatelessWidget {
  const DesktopKpis({super.key, required this.big, required this.cells});

  final bool big;
  final List<DesktopKpi> cells;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.rz,
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) VerticalDivider(width: 1, thickness: 1, color: t.bd),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: big ? 26 : 20, vertical: big ? 22 : 16),
                  child: Row(
                    children: [
                      DaIconBox(cells[i].$1,
                          color: cells[i].$2, size: 40, radius: 10),
                      const SizedBox(width: 14),
                      _Count(value: cells[i].$3, big: big),
                      const SizedBox(width: 14),
                      Flexible(
                        child: Text(cells[i].$4,
                            // Rótulo longo quebra no tablet em vez de sumir.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: daText(context, t,
                                weight: FontWeight.w500, color: t.tx2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Número que sobe até o valor (600 ms); sem valor mostra "—".
class _Count extends StatelessWidget {
  const _Count({required this.value, required this.big});

  final int? value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final style = daText(context, t,
            size: big ? 38 : 30, weight: FontWeight.w700)
        .copyWith(
            letterSpacing: -0.6,
            height: 1,
            fontFeatures: const [FontFeature.tabularFigures()]);
    final v = value;
    if (v == null) return Text('—', style: style);
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: v),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, n, __) => Text('$n', style: style),
    );
  }
}

/// Título, subtítulo e atalhos em grade plana de [columns] colunas. [compact]
/// usa linhas mais baixas (coluna lateral do Início da psicóloga).
class DesktopShortcutSection extends StatelessWidget {
  const DesktopShortcutSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.columns,
    required this.big,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final List<DesktopAdminShortcut> items;
  final int columns;
  final bool big;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final rows = <List<DesktopAdminShortcut?>>[];
    for (var i = 0; i < items.length; i += columns) {
      rows.add([
        for (var j = 0; j < columns; j++) i + j < items.length ? items[i + j] : null,
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: daText(context, t, size: 15, weight: FontWeight.w600)),
        Padding(
          padding: const EdgeInsets.only(top: 1, bottom: 10),
          child: Text(subtitle, style: daText(context, t, color: t.tx2)),
        ),
        Container(
          decoration: BoxDecoration(
            color: t.bd,
            border: Border.all(color: t.bd2),
            borderRadius: BorderRadius.circular(12),
          ),
          // Na coluna da psicóloga a borda é redesenhada por cima, para os
          // cantos arredondados não ficarem cobertos pelas linhas.
          foregroundDecoration: compact
              ? BoxDecoration(
                  border: Border.all(color: t.bd2),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var r = 0; r < rows.length; r++) ...[
                if (r > 0) const SizedBox(height: 1),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var c = 0; c < columns; c++) ...[
                        if (c > 0) const SizedBox(width: 1),
                        Expanded(
                          child: rows[r][c] == null
                              ? ColoredBox(color: t.rz)
                              : _ShortcutCell(
                                  item: rows[r][c]!,
                                  big: big,
                                  compact: compact),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ShortcutCell extends StatefulWidget {
  const _ShortcutCell({
    required this.item,
    required this.big,
    required this.compact,
  });

  final DesktopAdminShortcut item;
  final bool big;
  final bool compact;

  @override
  State<_ShortcutCell> createState() => _ShortcutCellState();
}

class _ShortcutCellState extends State<_ShortcutCell> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final it = widget.item;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        label: it.title,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: it.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(
                minHeight: widget.compact
                    ? (widget.big ? 64 : 56)
                    : (widget.big ? 88 : 72)),
            padding: EdgeInsets.symmetric(
                horizontal: widget.big ? 22 : 16,
                vertical: widget.compact ? 9 : (widget.big ? 20 : 14)),
            color: _hover ? t.hov : t.rz,
            child: Row(
              children: [
                DaIconBox(it.icon, color: it.color, size: 38, radius: 10),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(it.title,
                          style: daText(context, t,
                              size: 14, weight: FontWeight.w600)),
                      Text(it.subtitle,
                          style: daText(context, t, size: 12.5, color: t.tx2)),
                    ],
                  ),
                ),
                if (it.count != null) ...[
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    decoration: BoxDecoration(
                      color: _hover ? t.hov2 : t.hov,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${it.count}',
                        style: daText(context, t,
                            size: 12,
                            weight: FontWeight.w600,
                            color: t.tx2)),
                  ),
                  const SizedBox(width: 12),
                ],
                AnimatedSlide(
                  duration: const Duration(milliseconds: 150),
                  offset: _hover ? const Offset(0.2, 0) : Offset.zero,
                  child: Icon(Icons.arrow_forward,
                      size: 16,
                      color: _hover ? it.color : t.tx3.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
