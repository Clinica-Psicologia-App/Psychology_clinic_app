import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// KPI animado para dashboards clínicos (apresentação visual, sem alterar valores).
class ClinicalKpiChip extends StatelessWidget {
  const ClinicalKpiChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.accentColor,
    this.animateFromZero = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? accentColor;
  final bool animateFromZero;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? AppColors.cyan;
    final numeric = int.tryParse(value);
    final duration = AppAnimations.resolve(
      context,
      const Duration(milliseconds: 320),
    );

    return Semantics(
      label: '$label: $value',
      child: Container(
        constraints: const BoxConstraints(minWidth: 120),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Icon(icon, size: 18, color: accent),
              ),
            if (numeric != null && animateFromZero)
              TweenAnimationBuilder<int>(
                duration: duration,
                curve: AppAnimations.standardCurve,
                tween: IntTween(begin: 0, end: numeric),
                builder: (context, animated, _) {
                  return Text(
                    '$animated',
                    style: theme.textTheme.metricValue,
                  );
                },
              )
            else
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.metricValue,
              ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: theme.textTheme.metricLabel,
            ),
          ],
        ),
      ),
    );
  }
}
