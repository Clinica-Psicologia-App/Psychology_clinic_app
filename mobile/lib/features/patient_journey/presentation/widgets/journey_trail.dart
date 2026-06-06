import 'package:flutter/material.dart';

import '../../domain/journey_step.dart';
import '../../domain/journey_step_availability.dart';
import 'journey_step_card.dart';

/// Lista vertical com conector visual entre passos da trilha.
class JourneyTrail extends StatelessWidget {
  const JourneyTrail({
    super.key,
    required this.steps,
    required this.onStepTap,
  });

  final List<JourneyStep> steps;
  final void Function(JourneyStep step) onStepTap;

  @override
  Widget build(BuildContext context) {
    final sorted = List<JourneyStep>.from(steps)
      ..sort((a, b) => a.order.compareTo(b.order));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 48),
          child: Text(
            'Passos da trilha',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        ...List.generate(sorted.length, (index) {
          final step = sorted[index];
          final isLast = index == sorted.length - 1;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TrailRail(
                    step: step,
                    showConnector: !isLast,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: JourneyStepCard(
                      step: step,
                      onTap: () => onStepTap(step),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _TrailRail extends StatelessWidget {
  const _TrailRail({
    required this.step,
    required this.showConnector,
  });

  final JourneyStep step;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeColor = _nodeColor(theme.colorScheme, step.availability);

    return SizedBox(
      width: 36,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeColor.background,
              border: Border.all(color: nodeColor.border, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              '${step.order}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: nodeColor.foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (showConnector)
            Expanded(
              child: Container(
                width: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: theme.colorScheme.outlineVariant,
              ),
            ),
        ],
      ),
    );
  }
}

({Color background, Color border, Color foreground}) _nodeColor(
  ColorScheme colors,
  JourneyStepAvailability availability,
) {
  return switch (availability) {
    JourneyStepAvailability.completed => (
        background: colors.tertiaryContainer,
        border: colors.tertiary,
        foreground: colors.onTertiaryContainer,
      ),
    JourneyStepAvailability.available => (
        background: colors.primaryContainer,
        border: colors.primary,
        foreground: colors.onPrimaryContainer,
      ),
    JourneyStepAvailability.inProgress => (
        background: colors.secondaryContainer,
        border: colors.secondary,
        foreground: colors.onSecondaryContainer,
      ),
    JourneyStepAvailability.inDevelopment => (
        background: colors.surfaceContainerHighest,
        border: colors.outline,
        foreground: colors.onSurfaceVariant,
      ),
    JourneyStepAvailability.blocked => (
        background: colors.errorContainer.withValues(alpha: 0.4),
        border: colors.error,
        foreground: colors.onErrorContainer,
      ),
  };
}
