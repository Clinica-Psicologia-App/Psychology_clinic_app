import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/patient_problem.dart';
import '../../domain/patient_problem_status.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientProblemStatusChip extends StatelessWidget {
  const PatientProblemStatusChip({super.key, required this.status});

  final PatientProblemStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_statusIcon(status), size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class PatientProblemIntensityBadge extends StatelessWidget {
  const PatientProblemIntensityBadge({super.key, required this.intensity});

  final int intensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Intensidade $intensity/10',
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PatientProblemListTile extends StatelessWidget {
  const PatientProblemListTile({
    super.key,
    required this.problem,
    required this.onTap,
  });

  final PatientProblem problem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.warning;
    final subtitleParts = <String>[];
    if (problem.category != null && problem.category!.trim().isNotEmpty) {
      subtitleParts.add(problem.category!.trim());
    }
    if (problem.description != null && problem.description!.trim().isNotEmpty) {
      subtitleParts.add(problem.description!.trim());
    }

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.16)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, Color(0xFFEEA84D)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.report_problem_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      problem.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitleParts.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitleParts.join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        PatientProblemStatusChip(status: problem.status),
                        if (problem.intensity != null)
                          PatientProblemIntensityBadge(
                            intensity: problem.intensity!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusColor(PatientProblemStatus status) {
  return switch (status) {
    PatientProblemStatus.active => AppColors.warning,
    PatientProblemStatus.improved => AppColors.cyan,
    PatientProblemStatus.resolved => AppColors.success,
    PatientProblemStatus.archived => AppColors.textMuted,
  };
}

IconData _statusIcon(PatientProblemStatus status) {
  return switch (status) {
    PatientProblemStatus.active => Icons.report_problem_outlined,
    PatientProblemStatus.improved => Icons.trending_up_rounded,
    PatientProblemStatus.resolved => Icons.check_circle_outline,
    PatientProblemStatus.archived => Icons.inventory_2_outlined,
  };
}
