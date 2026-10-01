import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/check_in_mode.dart';
import '../../domain/patient_check_in.dart';

class ScoreSliderField extends StatelessWidget {
  const ScoreSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.lowLabel,
    this.highLabel,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? lowLabel;
  final String? highLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            Text(
              '$value',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
        if (lowLabel != null || highLabel != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lowLabel ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                highLabel ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class CheckInScoresSummary extends StatelessWidget {
  const CheckInScoresSummary({super.key, required this.checkIn});

  final PatientCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (checkIn.moodScore != null)
          _ScoreRow(
            label: 'Humor',
            value: checkIn.moodScore!,
            positiveHigh: true,
            faces: const ['😭', '😞', '😐', '🙂', '😄'],
            labels: kMoodLabels,
          ),
        if (checkIn.anxietyScore != null)
          _ScoreRow(
            label: 'Ansiedade',
            value: checkIn.anxietyScore!,
            positiveHigh: false,
            faces: const ['😌', '🙂', '😐', '😰', '😱'],
            labels: kAnxietyLabels,
          ),
        if (checkIn.energyScore != null)
          _ScoreRow(
            label: 'Energia',
            value: checkIn.energyScore!,
            positiveHigh: true,
            faces: const ['😴', '😪', '🙂', '😀', '🤩'],
            labels: kEnergyLabels,
          ),
        if (checkIn.sleepScore != null)
          _ScoreRow(
            label: 'Sono',
            value: checkIn.sleepScore!,
            positiveHigh: true,
            faces: const ['😵', '😴', '😪', '😌', '😇'],
            labels: kSleepLabels,
          ),
        if (checkIn.stressScore != null)
          _ScoreRow(
            label: 'Estresse',
            value: checkIn.stressScore!,
            positiveHigh: false,
            faces: const ['😌', '🙂', '😐', '😤', '🤯'],
            labels: kStressLabels,
          ),
      ],
    );
  }
}

class CheckInEmotionsCard extends StatelessWidget {
  const CheckInEmotionsCard({super.key, required this.checkIn});

  final PatientCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final emotions = checkIn.moodEmotions;
    if (emotions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.favorite_outline, size: 16,
                color: AppColors.turquoise),
            const SizedBox(width: 6),
            Text(
              'Como se sentiu',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.turquoise,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: emotions.map((e) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppColors.turquoise.withValues(alpha: 0.3)),
              ),
              child: Text(
                e,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.turquoise,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class CheckInModesCard extends StatelessWidget {
  const CheckInModesCard({super.key, required this.checkIn});

  final PatientCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final modes = checkIn.effectiveModes;
    if (modes.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.psychology_outlined, size: 16,
                color: AppColors.purple),
            const SizedBox(width: 6),
            Text(
              'Modos identificados',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.purple,
              ),
            ),
          ]),
          const SizedBox(height: 10),
          ...modes.map((mode) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.patientLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (mode.nickname != null &&
                          mode.nickname!.trim().isNotEmpty)
                        Text(
                          '"${mode.nickname}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.purple,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      Text(
                        mode.clinicalName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

/// Linha de escala no resumo: carinha (reflete o valor) + nome + rótulo em
/// palavra + mini-barra e o valor. A cor segue a valência da dimensão.
class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.positiveHigh,
    required this.faces,
    required this.labels,
  });

  final String label;
  final int value;
  final bool positiveHigh;
  final List<String> faces;
  final Map<int, String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goodness = positiveHigh ? value / 10 : 1 - value / 10;
    final tone = goodness >= 0.66
        ? AppColors.success
        : goodness >= 0.33
            ? AppColors.warning
            : AppColors.error;
    final idx =
        ((value / 10) * (faces.length - 1)).round().clamp(0, faces.length - 1);
    final word = labels[value] ?? '$value';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(faces[idx], style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w700, fontSize: 12),
                ),
                Text(
                  word,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: tone,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (value / 10).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: tone.withValues(alpha: 0.15),
                    color: tone,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$value',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ],
      ),
    );
  }
}
