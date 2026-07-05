import 'package:flutter/material.dart';

import '../../domain/journey_step.dart';
import '../../domain/journey_step_availability.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/app_page_header.dart';
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
    final compact = MediaQuery.sizeOf(context).width < 600;

    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 8, compact ? 12 : 16, 24),
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: 12,
            left: compact ? 0 : 48,
            right: compact ? 0 : 8,
          ),
          child: const AppSectionHeader(
            title: 'Próximos passos',
            subtitle: 'Acompanhe o que está disponível e o que já foi enviado.',
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
                    compact: compact,
                  ),
                  SizedBox(width: compact ? 8 : 12),
                  Expanded(
                    child: MotionReveal(
                      delay: Duration(milliseconds: 45 * index),
                      child: JourneyStepCard(
                        step: step,
                        onTap: () => onStepTap(step),
                      ),
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
    required this.compact,
  });

  final JourneyStep step;
  final bool showConnector;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeColor = _nodeColor(theme.colorScheme, step.availability);

    return SizedBox(
      width: compact ? 32 : 36,
      child: Column(
        children: [
          Container(
            width: compact ? 30 : 32,
            height: compact ? 30 : 32,
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
