import 'package:flutter/material.dart';

import '../../domain/journey_step.dart';
import '../../domain/journey_step_availability.dart';

class JourneyStepCard extends StatelessWidget {
  const JourneyStepCard({
    super.key,
    required this.step,
    required this.onTap,
  });

  final JourneyStep step;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusStyle = _statusStyle(colors, step.availability);
    final showChevron =
        step.availability != JourneyStepAvailability.blocked && onTap != null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: step.availability == JourneyStepAvailability.available ? 1 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colors.primaryContainer.withValues(alpha: 0.6),
                    child: Icon(step.icon, color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: step.availability.label,
                    background: statusStyle.background,
                    foreground: statusStyle.foreground,
                  ),
                  if (showChevron) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: colors.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              if (step.progressHint != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.progressHint!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.primary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

({Color background, Color foreground}) _statusStyle(
  ColorScheme colors,
  JourneyStepAvailability availability,
) {
  return switch (availability) {
    JourneyStepAvailability.available => (
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
      ),
    JourneyStepAvailability.inProgress => (
        background: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
      ),
    JourneyStepAvailability.completed => (
        background: colors.tertiaryContainer,
        foreground: colors.onTertiaryContainer,
      ),
    JourneyStepAvailability.inDevelopment => (
        background: colors.surfaceContainerHighest,
        foreground: colors.onSurfaceVariant,
      ),
    JourneyStepAvailability.blocked => (
        background: colors.errorContainer.withValues(alpha: 0.35),
        foreground: colors.onErrorContainer,
      ),
  };
}
