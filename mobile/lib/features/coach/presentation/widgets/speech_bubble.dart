import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/clay_card.dart';

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    required this.onNext,
    required this.onSkip,
    required this.isLast,
    required this.index,
    required this.total,
  });

  final String text;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLast;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      accentColor: AppColors.turquoise,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1} de $total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.turquoise,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              text,
              key: const ValueKey('coach_bubble_text'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                TextButton(
                  key: const ValueKey('coach_skip_button'),
                  onPressed: onSkip,
                  child: const Text('Pular'),
                ),
                FilledButton(
                  key: const ValueKey('coach_next_button'),
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.turquoise,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isLast ? 'Concluir' : 'Próximo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
