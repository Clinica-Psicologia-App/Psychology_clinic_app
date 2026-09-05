import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/check_in_diary_stats.dart';
import '../../domain/patient_check_in.dart';
import 'mood_face.dart';

const _weekdayAbbr = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];

// ─────────────────────────────────────────────────────────────────────────────
// Capa — o que o paciente já escreveu, e como o humor vem andando
// ─────────────────────────────────────────────────────────────────────────────

class CheckInDiaryCover extends StatelessWidget {
  const CheckInDiaryCover({super.key, required this.stats});

  final CheckInDiaryStats stats;

  @override
  Widget build(BuildContext context) {
    final pages = stats.total == 1
        ? '1 página escrita'
        : '${stats.total} páginas escritas';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E5C63), Color(0xFF12857E), Color(0xFF15A79A)],
          stops: [0, 0.55, 1],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0E5C63).withValues(alpha: 0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'MEU DIÁRIO',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (stats.streakDays >= 2) _StreakChip(days: stats.streakDays),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            pages,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cada linha aqui é sua. Nada se perde entre uma sessão e outra.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          if (stats.hasSeries) ...[
            const SizedBox(height: 16),
            _MoodThread(stats: stats),
          ],
        ],
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 13,
            color: Color(0xFFFFC107),
          ),
          const SizedBox(width: 4),
          Text(
            '$days dias seguidos',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodThread extends StatelessWidget {
  const _MoodThread({required this.stats});

  final CheckInDiaryStats stats;

  String? get _trendLabel => switch (stats.trend) {
        MoodTrend.rising => 'em alta nos últimos dias',
        MoodTrend.steady => 'estável nos últimos dias',
        MoodTrend.falling => 'mais baixo nos últimos dias',
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final trend = _trendLabel;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SEU HUMOR',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              if (trend != null)
                Text(
                  trend,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7FFFD4),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 42,
            child: CustomPaint(
              painter: _MoodThreadPainter(stats.moodSeries),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodThreadPainter extends CustomPainter {
  _MoodThreadPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final dx = size.width / (values.length - 1);
    // Normaliza pelo intervalo observado: numa escala fixa de 0 a 10 a linha
    // fica quase reta e não conta nada. O que interessa é a forma da variação.
    final lo = values.reduce(math.min).toDouble();
    final hi = values.reduce(math.max).toDouble();
    final span = (hi - lo) < 1 ? 1.0 : hi - lo;

    Offset at(int i) => Offset(
          i * dx,
          size.height - 5 - ((values[i] - lo) / span) * (size.height - 12),
        );

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final p0 = at(i - 1);
      final p1 = at(i);
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x557FFFD4), Color(0x007FFFD4)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7FFFD4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    final last = at(values.length - 1);
    canvas.drawCircle(last, 4.5, Paint()..color = Colors.white);
    canvas.drawCircle(last, 2.6, Paint()..color = const Color(0xFF12857E));
  }

  @override
  bool shouldRepaint(_MoodThreadPainter old) => old.values != values;
}

// ─────────────────────────────────────────────────────────────────────────────
// Página em branco — convite de hoje
// ─────────────────────────────────────────────────────────────────────────────

class CheckInBlankPage extends StatelessWidget {
  const CheckInBlankPage({super.key, required this.onWrite});

  final VoidCallback onWrite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onWrite,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.turquoise.withValues(alpha: 0.45),
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.turquoise.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.turquoise,
                  size: 24,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A página de hoje está em branco',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const _RuledLines(),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.turquoise,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Escrever',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuledLines extends StatelessWidget {
  const _RuledLines();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final factor in [1.0, 0.72])
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: FractionallySizedBox(
              widthFactor: factor,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Divisor de mês — os capítulos do caderno
// ─────────────────────────────────────────────────────────────────────────────

class CheckInMonthDivider extends StatelessWidget {
  const CheckInMonthDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.outline,
                    theme.colorScheme.outline.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Página do diário
// ─────────────────────────────────────────────────────────────────────────────

class CheckInDiaryEntry extends StatelessWidget {
  const CheckInDiaryEntry({
    super.key,
    required this.checkIn,
    required this.onTap,
    this.isToday = false,
    this.isLast = false,
  });

  final PatientCheckIn checkIn;
  final VoidCallback onTap;

  /// Página de hoje: ganha borda turquesa e o selo "hoje".
  final bool isToday;

  /// Última página do caderno — o fio para de descer.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final at = checkIn.checkedInAt.toLocal();
    final mood = checkIn.moodScore;
    final tone =
        mood == null ? theme.colorScheme.outline : MoodFace.toneFor(mood);
    final notes = checkIn.notes?.trim() ?? '';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Data + fio que costura as páginas.
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  at.day.toString().padLeft(2, '0'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                Text(
                  _weekdayAbbr[at.weekday - 1],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: theme.colorScheme.outline.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isToday
                            ? AppColors.turquoise.withValues(alpha: 0.5)
                            : theme.colorScheme.outline,
                        width: isToday ? 1.4 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (mood != null)
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: tone.withValues(alpha: 0.13),
                                  shape: BoxShape.circle,
                                ),
                                child: MoodFace(score: mood, size: 20),
                              ),
                            if (mood != null) const SizedBox(width: 9),
                            Text(
                              _hhmm(at),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (isToday) ...[
                              const SizedBox(width: 6),
                              const _TodayTag(),
                            ],
                            const Spacer(),
                            _MiniScore(
                              label: 'Hum',
                              value: checkIn.moodScore,
                            ),
                            _MiniScore(
                              label: 'Ans',
                              value: checkIn.anxietyScore,
                              inverse: true,
                            ),
                            _MiniScore(
                              label: 'Ene',
                              value: checkIn.energyScore,
                            ),
                          ],
                        ),
                        if (notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          // Filete de citação: como é borda, acompanha sozinho
                          // a altura do texto, sem medir nada.
                          Container(
                            padding: const EdgeInsets.only(left: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                left: BorderSide(
                                  color: tone.withValues(alpha: 0.4),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              notes,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                height: 1.45,
                                fontStyle: FontStyle.italic,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
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

  static String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}

class _TodayTag extends StatelessWidget {
  const _TodayTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'hoje',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.turquoise,
        ),
      ),
    );
  }
}

/// Nota de margem: o número pequeno, colorido pela valência da dimensão.
class _MiniScore extends StatelessWidget {
  const _MiniScore({
    required this.label,
    required this.value,
    this.inverse = false,
  });

  final String label;
  final int? value;

  /// Dimensões em que nota alta é ruim (ansiedade, problemas).
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value;
    if (v == null) return const SizedBox.shrink();

    final goodness = inverse ? 1 - v / 10 : v / 10;
    final tone = goodness >= 0.66
        ? AppColors.success
        : goodness >= 0.33
            ? AppColors.warning
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              '$v',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: tone,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
