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
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

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
                  child: _Greeting(name: name, greeting: greeting, big: big),
                ),
                const SizedBox(height: 20),
                MotionReveal(
                  delay: staggerDelay(1),
                  child: _Kpis(
                    big: big,
                    clinics: clinicsCount,
                    users: usersCount,
                    patients: patientsCount,
                  ),
                ),
                const SizedBox(height: 26),
                MotionReveal(
                  delay: staggerDelay(2),
                  child: _Section(
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
                  child: _Section(
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

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.greeting, required this.big});

  final String name;
  final String greeting;
  final bool big;

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
          DaInitials(initials, size: 44),
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
                Text('Administrador da plataforma',
                    style: daText(context, t, color: t.tx2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kpis extends StatelessWidget {
  const _Kpis({
    required this.big,
    required this.clinics,
    required this.users,
    required this.patients,
  });

  final bool big;
  final int? clinics;
  final int? users;
  final int? patients;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final cells = [
      (Icons.apartment_outlined, DesktopAdminTokens.blue, clinics, 'clínicas'),
      (Icons.badge_outlined, DesktopAdminTokens.purple, users, 'usuários'),
      (Icons.people_outline, const Color(0xFF00A39B), patients, 'pacientes'),
    ];
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
                            maxLines: 1,
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
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, n, __) => Text('$n', style: style),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.columns,
    required this.big,
  });

  final String title;
  final String subtitle;
  final List<DesktopAdminShortcut> items;
  final int columns;
  final bool big;

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
                              : _ShortcutCell(item: rows[r][c]!, big: big),
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
  const _ShortcutCell({required this.item, required this.big});

  final DesktopAdminShortcut item;
  final bool big;

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
            constraints: BoxConstraints(minHeight: widget.big ? 88 : 72),
            padding: EdgeInsets.symmetric(
                horizontal: widget.big ? 22 : 16, vertical: widget.big ? 20 : 14),
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
