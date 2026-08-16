import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/life_area.dart';

const Map<LifeArea, Color> _kAreaColors = {
  LifeArea.workCareer:          Color(0xFF3D72B4),
  LifeArea.loveRomance:         Color(0xFFC05048),
  LifeArea.family:              Color(0xFF8A4AAF),
  LifeArea.friends:             Color(0xFF1E8C6B),
  LifeArea.aloneTime:           Color(0xFF00A89E),
  LifeArea.physicalHealth:      Color(0xFF6B9E3A),
  LifeArea.emotionalHealth:     Color(0xFFC8426A),
  LifeArea.selfCare:            Color(0xFFD4891A),
  LifeArea.routineOrganization: Color(0xFF5B7898),
};

const Map<LifeArea, String> _kShortLabel = {
  LifeArea.workCareer:          'Trabalho',
  LifeArea.loveRomance:         'Amor',
  LifeArea.family:              'Família',
  LifeArea.friends:             'Amigos',
  LifeArea.aloneTime:           'Tempo',
  LifeArea.physicalHealth:      'S. Física',
  LifeArea.emotionalHealth:     'S. Emoc.',
  LifeArea.selfCare:            'Autocuidad.',
  LifeArea.routineOrganization: 'Rotina',
};

/// Roda da Vida — layout Opção B:
/// Roda pequena à esquerda + lista lateral com mini-barras à direita.
/// A roda não exibe labels; a identidade de cada área está na lista.
class LifeAreaWheelChart extends StatelessWidget {
  const LifeAreaWheelChart({super.key, required this.scores});

  final Map<LifeArea, int?> scores;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = scores.values.whereType<int>().toList();
    final avg =
        filled.isEmpty ? null : filled.reduce((a, b) => a + b) / filled.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Roda ──────────────────────────────────────────────────────
            SizedBox(
              width: 148,
              height: 148,
              child: CustomPaint(
                painter: _WheelPainter(
                  scores: scores,
                  surfaceColor: theme.cardColor,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // ── Lista lateral ─────────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final area in kLifeAreasInOrder)
                    _AreaRow(area: area, score: scores[area]),
                ],
              ),
            ),
          ],
        ),
        // ── Chip de média ───────────────────────────────────────────────
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 8),
        if (avg != null)
          _AvgChip(avg: avg)
        else
          Text(
            'Preencha as áreas abaixo para ver o resultado',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}

// ── _AreaRow ─────────────────────────────────────────────────────────────────

class _AreaRow extends StatelessWidget {
  const _AreaRow({required this.area, required this.score});

  final LifeArea area;
  final int? score;

  Color _scoreColor(int s) {
    if (s >= 7) return AppColors.success;
    if (s >= 4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = _kAreaColors[area]!;
    final sc = score;
    final labelColor = sc != null ? _scoreColor(sc) : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  _kShortLabel[area]!,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                sc?.toString() ?? '–',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (sc ?? 0) / 10,
              backgroundColor: color.withValues(alpha: 0.13),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _AvgChip ─────────────────────────────────────────────────────────────────

class _AvgChip extends StatelessWidget {
  const _AvgChip({required this.avg});

  final double avg;

  Color get _color {
    if (avg >= 7) return AppColors.success;
    if (avg >= 4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            avg.toStringAsFixed(1).replaceAll('.', ','),
            style: theme.textTheme.titleMedium?.copyWith(
              color: _color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'média geral de satisfação',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ── _WheelPainter ─────────────────────────────────────────────────────────────
// Sem labels — a identidade de cada área está na lista lateral.

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.scores, required this.surfaceColor});

  final Map<LifeArea, int?> scores;
  final Color surfaceColor;

  static const double _gap = 0.055;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = (size.shortestSide / 2) * 0.88;
    final innerR = outerR * 0.14;
    final n = kLifeAreasInOrder.length;
    final sectorAngle = (2 * math.pi) / n;
    const startOffset = -math.pi / 2;

    for (var i = 0; i < n; i++) {
      final area = kLifeAreasInOrder[i];
      final score = scores[area] ?? 0;
      final color = _kAreaColors[area]!;
      final start = startOffset + i * sectorAngle;
      final sweep = sectorAngle - _gap;
      final fillR = innerR + (score / 10) * (outerR - innerR);

      // ghost bg
      canvas.drawPath(
        _sectorPath(cx, cy, innerR, outerR, start + _gap / 2, sweep),
        Paint()
          ..color = color.withValues(alpha: 0.13)
          ..style = PaintingStyle.fill,
      );

      // fill
      if (score > 0) {
        canvas.drawPath(
          _sectorPath(cx, cy, innerR, fillR, start + _gap / 2, sweep),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }

    // center disc
    canvas.drawCircle(
      Offset(cx, cy),
      innerR - 1,
      Paint()..color = surfaceColor,
    );
  }

  Path _sectorPath(
    double cx,
    double cy,
    double innerR,
    double outerR,
    double startAngle,
    double sweep,
  ) {
    final path = Path()
      ..moveTo(cx + math.cos(startAngle) * outerR,
          cy + math.sin(startAngle) * outerR)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
          startAngle, sweep, false)
      ..lineTo(cx + math.cos(startAngle + sweep) * innerR,
          cy + math.sin(startAngle + sweep) * innerR)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
          startAngle + sweep, -sweep, false)
      ..close();
    return path;
  }

  @override
  bool shouldRepaint(_WheelPainter old) => true;
}
