import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/therapy_goal.dart';
import '../../domain/therapy_goal_status.dart';

class TherapyGoalStatusChip extends StatelessWidget {
  const TherapyGoalStatusChip({super.key, required this.status});

  final TherapyGoalStatus status;

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
          Icon(_iconForStatus(status), size: 12, color: color),
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

class TherapyGoalListTile extends StatelessWidget {
  const TherapyGoalListTile({
    super.key,
    required this.goal,
    required this.onTap,
  });

  final TherapyGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = AppColors.turquoise;
    final subtitleParts = <String>[];
    if (goal.description != null && goal.description!.trim().isNotEmpty) {
      subtitleParts.add(goal.description!.trim());
    }
    if (goal.targetDate != null) {
      final d = goal.targetDate!;
      subtitleParts.add(
        'Meta: ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
      );
    }

    return Card(
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
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.78)],
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
                child: Icon(
                  _iconForStatus(goal.status),
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
                      goal.title,
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
                    TherapyGoalStatusChip(status: goal.status),
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

Color _statusColor(TherapyGoalStatus status) {
  return switch (status) {
    TherapyGoalStatus.active => AppColors.turquoise,
    TherapyGoalStatus.completed => AppColors.success,
    TherapyGoalStatus.archived => AppColors.textMuted,
  };
}

IconData _iconForStatus(TherapyGoalStatus status) {
  return switch (status) {
    TherapyGoalStatus.active => Icons.flag_outlined,
    TherapyGoalStatus.completed => Icons.check_circle_outline,
    TherapyGoalStatus.archived => Icons.inventory_2_outlined,
  };
}
