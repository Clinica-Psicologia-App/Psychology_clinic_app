import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
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
            words: const ['Muito baixo', 'Baixo', 'Neutro', 'Bom', 'Muito bom'],
          ),
        if (checkIn.anxietyScore != null)
          _ScoreRow(
            label: 'Ansiedade',
            value: checkIn.anxietyScore!,
            positiveHigh: false,
            faces: const ['😌', '🙂', '😐', '😰', '😱'],
            words: const [
              'Tranquilo(a)',
              'Leve',
              'Moderada',
              'Alta',
              'Muito alta'
            ],
          ),
        if (checkIn.energyScore != null)
          _ScoreRow(
            label: 'Energia',
            value: checkIn.energyScore!,
            positiveHigh: true,
            faces: const ['😴', '😪', '🙂', '😀', '🤩'],
            words: const ['Exausto(a)', 'Baixa', 'Ok', 'Boa', 'Muita'],
          ),
        if (checkIn.problemIntensityScore != null)
          _ScoreRow(
            label: 'Problemas',
            value: checkIn.problemIntensityScore!,
            positiveHigh: false,
            faces: const ['🙂', '😐', '😕', '😣', '😖'],
            words: const [
              'Leve',
              'Ok',
              'Moderado',
              'Pesado',
              'Muito pesado'
            ],
          ),
      ],
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
    required this.words,
  });

  final String label;
  final int value;
  final bool positiveHigh;
  final List<String> faces;
  final List<String> words;

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
                  words[idx],
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
