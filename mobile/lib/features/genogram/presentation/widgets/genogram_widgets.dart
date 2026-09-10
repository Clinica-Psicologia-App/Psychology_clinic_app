import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/genogram_data.dart';
import '../../domain/genogram_person.dart';
import '../../domain/genogram_relationship.dart';
import '../../domain/genogram_relationship_type.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class GenogramGraphicNotice extends StatelessWidget {
  const GenogramGraphicNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Visualização em árvore gráfica será adicionada em versão futura. '
                'Por enquanto, use as listas de pessoas e relações abaixo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GenogramSummaryCard extends StatelessWidget {
  const GenogramSummaryCard({super.key, required this.data});

  final GenogramData data;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _Stat(
              icon: Icons.person_outline,
              label: 'Pessoas',
              value: '${data.people.length}',
            ),
            const SizedBox(width: AppSpacing.xl),
            _Stat(
              icon: Icons.link,
              label: 'Relações',
              value: '${data.relationships.length}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.moduleGenogram;
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withValues(alpha: 0.78)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Legenda do genograma ──────────────────────────────────────────────────────

class GenogramLegendCard extends StatefulWidget {
  const GenogramLegendCard({super.key});

  @override
  State<GenogramLegendCard> createState() => _GenogramLegendCardState();
}

class _GenogramLegendCardState extends State<GenogramLegendCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Column(
        children: [
          InkWell(
            borderRadius: AppRadius.lgAll,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Legenda dos símbolos',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendSection(context, 'Símbolos de pessoa', [
                    _LegendItem(
                      painter: _SquarePainter(),
                      label: 'Masculino',
                    ),
                    _LegendItem(
                      painter: _CirclePainter(),
                      label: 'Feminino',
                    ),
                    _LegendItem(
                      painter: _DiamondPainter(),
                      label: 'Gênero desconhecido / não-binário',
                    ),
                    _LegendItem(
                      painter: _TrianglePainter(filled: false),
                      label: 'Aborto espontâneo',
                    ),
                    _LegendItem(
                      painter: _TrianglePainter(filled: true),
                      label: 'Natimorto',
                    ),
                    _LegendItem(
                      painter: _TrianglePainter(filled: true, withX: true),
                      label: 'Interrupção voluntária',
                    ),
                    _LegendItem(
                      painter: _DeceasedPainter(),
                      label: 'Falecido (X sobre o símbolo)',
                    ),
                    _LegendItem(
                      painter: _IllnessPainter(),
                      label: 'Adoecimento (metade inferior preenchida)',
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _legendSection(context, 'Vínculos estruturais', [
                    _LegendItem(
                      painter: _LinePainter(style: _LineStyle.solid),
                      label: 'Casamento / união atual',
                    ),
                    _LegendItem(
                      painter: _LinePainter(style: _LineStyle.separated),
                      label: 'Separados (1 barra)',
                    ),
                    _LegendItem(
                      painter: _LinePainter(style: _LineStyle.divorced),
                      label: 'Divorciados (2 barras)',
                    ),
                    _LegendItem(
                      painter: _LinePainter(style: _LineStyle.dashed),
                      label: 'Filiação adotiva (tracejado)',
                    ),
                    _LegendItem(
                      painter: _LinePainter(style: _LineStyle.twin),
                      label: 'Gêmeos (convergência em Λ)',
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  _legendSection(context, 'Vínculos emocionais', [
                    _LegendItem(
                      painter: _LinePainter(
                        style: _LineStyle.doubleLine,
                        color: const Color(0xFF2E7D6B),
                      ),
                      label: 'Próxima / íntima',
                    ),
                    _LegendItem(
                      painter: _LinePainter(
                        style: _LineStyle.dashed,
                        color: const Color(0xFF6B7A90),
                      ),
                      label: 'Distante',
                    ),
                    _LegendItem(
                      painter: _LinePainter(
                        style: _LineStyle.zigzag,
                        color: const Color(0xFFB5651D),
                      ),
                      label: 'Conflituosa',
                    ),
                    _LegendItem(
                      painter: _LinePainter(
                        style: _LineStyle.doubleLineZigzag,
                        color: const Color(0xFF2E7D6B),
                      ),
                      label: 'Próxima e conflituosa',
                    ),
                    _LegendItem(
                      painter: _LinePainter(
                        style: _LineStyle.slashed,
                        color: const Color(0xFFB03A3A),
                      ),
                      label: 'Rompida',
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _legendSection(
      BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ...items,
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.painter, required this.label});

  final CustomPainter painter;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 48,
            height: 28,
            child: CustomPaint(painter: painter),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painters da legenda ───────────────────────────────────────────────────────

const _legendNavy = Color(0xFF0D1B3D);

class _SquarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 10.0;
    canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Paint()..color = _legendNavy..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 10,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(c, 10,
        Paint()..color = _legendNavy..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DiamondPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 10.0;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r, c.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawPath(path,
        Paint()..color = _legendNavy..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({this.filled = false, this.withX = false});
  final bool filled;
  final bool withX;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 9.0;
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r, c.dy + r * 0.7)
      ..lineTo(c.dx - r, c.dy + r * 0.7)
      ..close();
    if (filled) {
      canvas.drawPath(path, Paint()..color = _legendNavy..style = PaintingStyle.fill);
    }
    canvas.drawPath(path,
        Paint()..color = _legendNavy..strokeWidth = 1.8..style = PaintingStyle.stroke);
    if (withX) {
      final x = Paint()..color = Colors.white..strokeWidth = 1.4..style = PaintingStyle.stroke;
      const s = 4.0, oy = 2.0;
      canvas.drawLine(
          Offset(c.dx - s, c.dy - s + oy), Offset(c.dx + s, c.dy + s + oy), x);
      canvas.drawLine(
          Offset(c.dx + s, c.dy - s + oy), Offset(c.dx - s, c.dy + s + oy), x);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _DeceasedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 10.0;
    canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Paint()..color = _legendNavy..strokeWidth = 2..style = PaintingStyle.stroke);
    final x = Paint()..color = _legendNavy..strokeWidth = 1.8..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), x);
    canvas.drawLine(Offset(c.dx + r, c.dy - r), Offset(c.dx - r, c.dy + r), x);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _IllnessPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    const r = 10.0;
    canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(c.dx - r - 1, c.dy, c.dx + r + 1, c.dy + r + 1));
    canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Paint()..color = const Color(0xFF2A5A8A).withValues(alpha: 0.75)..style = PaintingStyle.fill);
    canvas.restore();
    canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        Paint()..color = _legendNavy..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

enum _LineStyle { solid, separated, divorced, dashed, twin, doubleLine, zigzag, slashed, doubleLineZigzag }

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.style, this.color = _legendNavy});
  final _LineStyle style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final a = Offset(4, size.height / 2);
    final b = Offset(size.width - 4, size.height / 2);

    switch (style) {
      case _LineStyle.solid:
        canvas.drawLine(a, b, paint);
      case _LineStyle.separated:
        canvas.drawLine(a, b, paint);
        final mx = size.width / 2;
        final my = size.height / 2;
        canvas.drawLine(
            Offset(mx - 4, my + 6), Offset(mx + 4, my - 6),
            Paint()..color = const Color(0xFFB03A3A)..strokeWidth = 2..style = PaintingStyle.stroke);
      case _LineStyle.divorced:
        canvas.drawLine(a, b, paint);
        final mx = size.width / 2;
        final my = size.height / 2;
        final dp = Paint()..color = const Color(0xFFB03A3A)..strokeWidth = 2..style = PaintingStyle.stroke;
        for (final off in [-3.5, 3.5]) {
          canvas.drawLine(
              Offset(mx + off - 4, my + 6), Offset(mx + off + 4, my - 6), dp);
        }
      case _LineStyle.dashed:
        _dashed(canvas, a, b, paint);
      case _LineStyle.twin:
        final apex = Offset(size.width / 2, size.height / 2 - 8);
        canvas.drawLine(a, apex, paint);
        canvas.drawLine(b, apex, paint);
        canvas.drawLine(
            Offset(4, size.height / 2 + 2),
            Offset(size.width - 4, size.height / 2 + 2),
            paint..color = color.withValues(alpha: 0.3));
      case _LineStyle.doubleLine:
        final n = const Offset(0, 2.4);
        canvas.drawLine(a + n, b + n, paint);
        canvas.drawLine(a - n, b - n, paint);
      case _LineStyle.zigzag:
        _zigzag(canvas, a, b, paint);
      case _LineStyle.slashed:
        canvas.drawLine(a, b, paint);
        final mid = (a + b) / 2;
        final normal = const Offset(0, 5);
        for (final off in [-3.0, 3.0]) {
          final c = mid + Offset(off, 0);
          canvas.drawLine(c + normal, c - normal, paint);
        }
      case _LineStyle.doubleLineZigzag:
        final n = const Offset(0, 2.4);
        canvas.drawLine(a + n, b + n, paint..color = const Color(0xFF2E7D6B));
        canvas.drawLine(a - n, b - n, paint);
        _zigzag(canvas, a, b, paint..color = const Color(0xFFB5651D));
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 5.0, gap = 4.0;
    final total = (b - a).distance;
    final unit = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      canvas.drawLine(
          a + unit * d, a + unit * math.min(d + dash, total), paint);
      d += dash + gap;
    }
  }

  void _zigzag(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    final unit = (b - a) / total;
    const step = 7.0, amp = 3.5;
    final path = Path()..moveTo(a.dx, a.dy);
    var d = 0.0, s = 1.0;
    while (d < total) {
      final next = math.min(d + step, total);
      final mid = a + unit * ((d + next) / 2) + Offset(0, amp * s);
      final e = a + unit * next;
      path.lineTo(mid.dx, mid.dy);
      path.lineTo(e.dx, e.dy);
      s = -s;
      d = next;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Person tile ───────────────────────────────────────────────────────────────

class GenogramPersonTile extends StatelessWidget {
  const GenogramPersonTile({
    super.key,
    required this.person,
    required this.onTap,
  });

  final GenogramPerson person;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensitive = person.isSensitive;
    // Confidencialidade discreta (cadeado + roxo), não alarme.
    final accent = sensitive ? AppColors.purple : AppColors.moduleGenogram;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: sensitive
          ? AppColors.purple.withValues(alpha: 0.05)
          : theme.colorScheme.surface,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  sensitive ? Icons.lock_outline : Icons.person_outline,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensitive ? 'Conteúdo sensível' : person.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (sensitive)
                      Text(
                        'Toque para abrir com aviso.',
                        style: theme.textTheme.bodySmall,
                      )
                    else ...[
                      if (person.relationshipToPatient != null &&
                          person.relationshipToPatient!.trim().isNotEmpty)
                        Text(
                          person.relationshipToPatient!.trim(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (person.lifeSpanLabel != null)
                            StatusChip(
                              label: person.lifeSpanLabel!,
                              tone: AppStatusTone.neutral,
                              icon: Icons.calendar_today_outlined,
                            ),
                          if (person.isDeceased)
                            const StatusChip(
                              label: 'Falecido',
                              tone: AppStatusTone.neutral,
                              icon: Icons.history_outlined,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GenogramRelationshipTile extends StatelessWidget {
  const GenogramRelationshipTile({
    super.key,
    required this.relationship,
    required this.data,
    required this.onTap,
  });

  final GenogramRelationship relationship;
  final GenogramData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensitive = relationship.isSensitive;
    final aName = data.personNameById(relationship.personAId);
    final bName = data.personNameById(relationship.personBId);
    // Confidencialidade discreta (cadeado + roxo), não alarme.
    final accent = sensitive ? AppColors.purple : AppColors.moduleTimeline;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: sensitive
          ? AppColors.purple.withValues(alpha: 0.05)
          : theme.colorScheme.surface,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  sensitive ? Icons.lock_outline : Icons.link,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensitive
                          ? 'Relação com conteúdo sensível'
                          : relationship.labelBetween(aName, bName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (sensitive)
                      Text(
                        'Toque para abrir com aviso.',
                        style: theme.textTheme.bodySmall,
                      )
                    else ...[
                      StatusChip(
                        label: relationship.relationshipType.label,
                        tone: AppStatusTone.info,
                        icon: Icons.sync_alt_outlined,
                      ),
                      if (relationship.notes != null &&
                          relationship.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          relationship.notes!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.arrow_forward_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
