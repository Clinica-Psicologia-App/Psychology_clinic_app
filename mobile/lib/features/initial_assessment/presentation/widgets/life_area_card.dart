import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/life_area.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Cartão de uma área de vida (Bloco 3). Coleta satisfação (1–10), um
/// sofrimento opcional (0–10) e a resposta à pergunta guiada.
class LifeAreaCard extends StatelessWidget {
  const LifeAreaCard({
    super.key,
    required this.area,
    required this.score,
    required this.suffering,
    required this.guidedController,
    required this.onScoreChanged,
    required this.onSufferingChanged,
    this.readOnly = false,
  });

  final LifeArea area;
  final int? score; // 1–10
  final int? suffering; // 0–10 (null = sem sofrimento informado)
  final TextEditingController guidedController;
  final ValueChanged<int> onScoreChanged;
  final ValueChanged<int?> onSufferingChanged;
  final bool readOnly;

  Color _scoreColor(int? value) {
    if (value == null) return AppColors.disabled;
    if (value >= 7) return AppColors.success;
    if (value >= 4) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _scoreColor(score);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho: área + nota grande
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        area.label,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        area.description,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    score?.toString() ?? '—',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Satisfação 1–10
            Row(
              children: [
                Text('Satisfação',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: AppColors.textSecondary)),
                Expanded(
                  child: Slider(
                    value: (score ?? 5).toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: (score ?? 5).toString(),
                    activeColor: color,
                    onChanged: readOnly
                        ? null
                        : (v) => onScoreChanged(v.round()),
                  ),
                ),
              ],
            ),
            // Pergunta guiada
            const SizedBox(height: 4),
            TextField(
              controller: guidedController,
              readOnly: readOnly,
              minLines: 1,
              maxLines: 3,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                labelText: area.guidedQuestion,
                isDense: true,
              ),
            ),
            // Sofrimento opcional
            const SizedBox(height: 4),
            _SufferingRow(
              suffering: suffering,
              readOnly: readOnly,
              onChanged: onSufferingChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SufferingRow extends StatelessWidget {
  const _SufferingRow({
    required this.suffering,
    required this.onChanged,
    required this.readOnly,
  });

  final int? suffering;
  final ValueChanged<int?> onChanged;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = suffering != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: enabled,
              visualDensity: VisualDensity.compact,
              onChanged: readOnly
                  ? null
                  : (v) => onChanged((v ?? false) ? 0 : null),
            ),
            Expanded(
              child: Text(
                'Isso tem causado sofrimento?',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            if (enabled)
              Text(
                '${suffering ?? 0}/10',
                style: theme.textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
          ],
        ),
        if (enabled)
          Slider(
            value: (suffering ?? 0).toDouble(),
            max: 10,
            divisions: 10,
            label: (suffering ?? 0).toString(),
            activeColor: AppColors.error,
            onChanged: readOnly ? null : (v) => onChanged(v.round()),
          ),
      ],
    );
  }
}
