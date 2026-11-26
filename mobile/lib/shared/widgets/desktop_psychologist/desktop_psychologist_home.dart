import 'package:flutter/material.dart';

import '../app_motion.dart';
import '../desktop_admin/desktop_admin_home.dart';
import '../desktop_admin/desktop_admin_kit.dart';
import '../loading_skeleton.dart';
import 'desktop_psychologist_shell.dart';

/// Uma notificação do Início (mesmos textos, cores e destino do celular).
class DesktopPsychologistAlert {
  const DesktopPsychologistAlert({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.subtitle,
    required this.pill,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final String title;
  final String subtitle;
  final String pill;
  final String semanticsLabel;
  final VoidCallback onTap;
}

/// Bloco de atalhos da coluna lateral ("Meus pacientes", "Avaliação e
/// recursos"). [anchor] é o alvo do tutorial.
class DesktopPsychologistSection {
  const DesktopPsychologistSection({
    required this.anchor,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final Key anchor;
  final String title;
  final String subtitle;
  final List<DesktopAdminShortcut> items;
}

/// Início da psicóloga a partir de 768 px: saudação, 3 números, notificações em
/// painel e os atalhos sempre abertos.
class DesktopPsychologistHome extends StatelessWidget {
  const DesktopPsychologistHome({
    super.key,
    required this.name,
    required this.greeting,
    required this.contextLine,
    required this.avatar,
    required this.areaLabel,
    required this.onHelp,
    required this.kpis,
    required this.alerts,
    required this.alertsLoading,
    required this.sections,
  });

  final String name;
  final String greeting;
  final String contextLine;
  final Widget avatar;
  final String areaLabel;
  final VoidCallback onHelp;
  final List<DesktopKpi> kpis;

  /// Vazio = sem painel de notificações (como no celular).
  final List<DesktopPsychologistAlert> alerts;
  final bool alertsLoading;
  final List<DesktopPsychologistSection> sections;

  @override
  Widget build(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final big = m.size == DesktopAdminSize.desktop;
    final hasAlerts = alertsLoading || alerts.isNotEmpty;

    Widget section(int i) => KeyedSubtree(
          key: sections[i].anchor,
          child: MotionReveal(
            delay: staggerDelay(3 + i),
            child: DesktopShortcutSection(
              title: sections[i].title,
              subtitle: sections[i].subtitle,
              items: sections[i].items,
              columns: 1,
              big: big,
              compact: true,
            ),
          ),
        );

    final stacked = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 24),
          section(i),
        ],
      ],
    );

    final panel = MotionReveal(
      delay: staggerDelay(2),
      child: _Notifications(alerts: alerts, loading: alertsLoading, big: big),
    );

    final Widget work;
    if (m.tablet) {
      work = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasAlerts) ...[panel, const SizedBox(height: 24)],
          stacked,
        ],
      );
    } else if (hasAlerts) {
      work = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: panel),
          SizedBox(width: big ? 32 : 24),
          SizedBox(width: big ? 420 : 340, child: stacked),
        ],
      );
    } else {
      // Sem notificações, os dois blocos dividem a largura.
      work = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) SizedBox(width: big ? 32 : 24),
            Expanded(child: section(i)),
          ],
        ],
      );
    }

    return DesktopPsychologistFrame(
      title: 'Início',
      actions: [
        _AreaTag(areaLabel),
        DaButton(
          icon: Icons.help_outline,
          tooltip: 'Rever tutorial',
          kind: DaButtonKind.ghost,
          onPressed: onHelp,
        ),
      ],
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
                    subtitle: contextLine,
                    leading: avatar,
                    big: big,
                  ),
                ),
                const SizedBox(height: 20),
                MotionReveal(
                  delay: staggerDelay(1),
                  child: DesktopKpis(big: big, cells: kpis),
                ),
                const SizedBox(height: 26),
                work,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Etiqueta da área ("Profissional") na barra superior.
class _AreaTag extends StatelessWidget {
  const _AreaTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = DesktopAdminTokens.of(context).dark;
    return DaTag(
      label,
      bg: dark ? const Color(0xFF0F3B3A) : const Color(0xFFCCFBF1),
      fg: dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
    );
  }
}

class _Notifications extends StatefulWidget {
  const _Notifications({
    required this.alerts,
    required this.loading,
    required this.big,
  });

  final List<DesktopPsychologistAlert> alerts;
  final bool loading;
  final bool big;

  @override
  State<_Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<_Notifications> {
  static const _initialCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final alerts = widget.alerts;
    final hasMore = alerts.length > _initialCount;
    final visible = _expanded ? alerts : alerts.take(_initialCount).toList();
    final rows = <Widget>[
      if (widget.loading)
        for (var i = 0; i < _initialCount; i++) _SkeletonRow(big: widget.big)
      else ...[
        for (final alert in visible)
          _AlertRow(alert: alert, big: widget.big),
        if (hasMore)
          _MoreRow(
            label:
                _expanded ? 'Mostrar menos' : 'Ver todas (${alerts.length})',
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 22,
          child: Row(
            children: [
              const Icon(Icons.notifications_outlined,
                  size: 17, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text('Notificações',
                  style: daText(context, t, size: 15, weight: FontWeight.w600)),
              if (!widget.loading) ...[
                const SizedBox(width: 8),
                DaTag(
                  '${alerts.length}',
                  bg: t.dark
                      ? const Color(0xFF4A3410)
                      : const Color(0xFFFEF3C7),
                  fg: t.dark
                      ? const Color(0xFFFCD34D)
                      : const Color(0xFF92400E),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: t.rz,
            border: Border.all(color: t.bd2),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: t.bd),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.big});

  final bool big;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: big ? 68 : 60,
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            LoadingSkeleton(height: 32, width: 32),
            SizedBox(width: 14),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LoadingSkeleton(height: 10, width: 160),
                SizedBox(height: 8),
                LoadingSkeleton(height: 10, width: 120),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertRow extends StatefulWidget {
  const _AlertRow({required this.alert, required this.big});

  final DesktopPsychologistAlert alert;
  final bool big;

  @override
  State<_AlertRow> createState() => _AlertRowState();
}

class _AlertRowState extends State<_AlertRow> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final a = widget.alert;
    return Semantics(
      label: a.semanticsLabel,
      excludeSemantics: true,
      button: true,
      onTap: a.onTap,
      child: InkWell(
        onTap: a.onTap,
        mouseCursor: SystemMouseCursors.click,
        onHover: (v) => setState(() => _hover = v),
        onFocusChange: (v) => setState(() => _focus = v),
        hoverColor: Colors.transparent,
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          constraints: BoxConstraints(minHeight: widget.big ? 68 : 60),
          padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
          color: _hover || _focus ? t.hov : daClear(t.hov),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: a.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(a.icon, size: 17, color: a.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: daText(context, t, weight: FontWeight.w600)),
                    Text(a.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: daText(context, t, size: 12, color: t.tx2)),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              DaTag(a.pill, bg: a.background, fg: a.color),
              const SizedBox(width: 14),
              AnimatedSlide(
                duration: daHoverDuration(context),
                offset: _hover ? const Offset(0.2, 0) : Offset.zero,
                child: Icon(Icons.chevron_right, size: 16, color: t.tx3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Ver todas (n)" / "Mostrar menos".
class _MoreRow extends StatelessWidget {
  const _MoreRow({
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final color = t.dark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      hoverColor: t.hov,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: daText(context, t,
                    weight: FontWeight.w600, color: color)),
            const SizedBox(width: 4),
            Icon(expanded ? Icons.expand_less : Icons.expand_more,
                size: 16, color: color),
          ],
        ),
      ),
    );
  }
}
