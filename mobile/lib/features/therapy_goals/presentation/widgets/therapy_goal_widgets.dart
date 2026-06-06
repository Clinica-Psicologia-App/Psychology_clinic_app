import 'package:flutter/material.dart';

import '../../domain/therapy_goal.dart';
import '../../domain/therapy_goal_status.dart';

class TherapyGoalStatusChip extends StatelessWidget {
  const TherapyGoalStatusChip({super.key, required this.status});

  final TherapyGoalStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _style(theme.colorScheme, status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: style.foreground,
          fontWeight: FontWeight.w600,
        ),
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
      child: ListTile(
        leading: Icon(
          _iconForStatus(goal.status),
          color: theme.colorScheme.primary,
        ),
        title: Text(goal.title),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(
                subtitleParts.join('\n'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TherapyGoalStatusChip(status: goal.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right),
          ],
        ),
        isThreeLine: subtitleParts.length > 1,
        onTap: onTap,
      ),
    );
  }
}

IconData _iconForStatus(TherapyGoalStatus status) {
  return switch (status) {
    TherapyGoalStatus.active => Icons.flag_outlined,
    TherapyGoalStatus.completed => Icons.check_circle_outline,
    TherapyGoalStatus.archived => Icons.inventory_2_outlined,
  };
}

({Color background, Color foreground}) _style(
  ColorScheme colors,
  TherapyGoalStatus status,
) {
  return switch (status) {
    TherapyGoalStatus.active => (
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
      ),
    TherapyGoalStatus.completed => (
        background: colors.tertiaryContainer,
        foreground: colors.onTertiaryContainer,
      ),
    TherapyGoalStatus.archived => (
        background: colors.surfaceContainerHighest,
        foreground: colors.onSurfaceVariant,
      ),
  };
}
