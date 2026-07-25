import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/journey_step.dart';
import '../../domain/journey_step_availability.dart';
import '../../domain/journey_step_id.dart';

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
    final enabled =
        step.availability != JourneyStepAvailability.blocked && onTap != null;
    final accent = _accentForStep(step);
    final compact = AppBreakpoints.isCompact(context);

    return AnimatedContainer(
      duration: AppAnimations.standard,
      curve: AppAnimations.standardCurve,
      decoration: BoxDecoration(
        color: enabled ? AppColors.surface : AppColors.disabledSurface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.lgAll,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppRadius.lgAll,
            child: Padding(
              padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                _StepHeader(
                  step: step,
                  accent: accent,
                  enabled: enabled,
                  compact: compact,
                ),
                if (step.progressHint != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: AppRadius.smAll,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.insights_outlined, size: 16, color: accent),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            step.progressHint!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
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
      ),
    ),
  );
  }

  static AppStatusTone _toneFor(JourneyStepAvailability availability) {
    return switch (availability) {
      JourneyStepAvailability.available => AppStatusTone.available,
      JourneyStepAvailability.inProgress => AppStatusTone.inProgress,
      JourneyStepAvailability.completed => AppStatusTone.completed,
      JourneyStepAvailability.inDevelopment => AppStatusTone.development,
      JourneyStepAvailability.blocked => AppStatusTone.blocked,
    };
  }

  static Color _accentForStep(JourneyStep step) {
    return switch (step.id) {
      JourneyStepId.initialAssessment => AppColors.moduleDashboard,
      JourneyStepId.questionnaires => AppColors.moduleQuestionnaires,
      JourneyStepId.mentalMap => AppColors.moduleMentalMap,
      JourneyStepId.checkIn => AppColors.moduleCheckIn,
      JourneyStepId.timeline => AppColors.moduleTimeline,
      JourneyStepId.therapyGoals => AppColors.moduleGoals,
      JourneyStepId.problems => AppColors.moduleProblems,
      JourneyStepId.library => AppColors.moduleResources,
      JourneyStepId.results => AppColors.moduleDashboard,
      JourneyStepId.dailyMonitor => AppColors.moduleMonitor,
      JourneyStepId.genogram => AppColors.moduleGenogram,
    };
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.accent,
    required this.enabled,
    required this.compact,
  });

  final JourneyStep step;
  final Color accent;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: AppRadius.mdAll,
      ),
      child: Icon(step.icon, color: accent, size: 22),
    );
    final status = StatusChip(
      label: step.availability.label,
      tone: JourneyStepCard._toneFor(step.availability),
    );
    final chevron = enabled
        ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
        : null;

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  step.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (chevron != null) chevron,
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          status,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        icon,
        const SizedBox(width: AppSpacing.sm),
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
              const SizedBox(height: AppSpacing.xxs),
              Text(
                step.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        status,
        if (chevron != null) ...[
          const SizedBox(width: AppSpacing.xxs),
          chevron,
        ],
      ],
    );
  }
}
