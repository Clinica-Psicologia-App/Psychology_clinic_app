import 'package:flutter/material.dart';

import '../../domain/patient_problem.dart';
import '../../domain/patient_problem_status.dart';

class PatientProblemStatusChip extends StatelessWidget {
  const PatientProblemStatusChip({super.key, required this.status});

  final PatientProblemStatus status;

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
    final subtitleParts = <String>[];
    if (problem.category != null && problem.category!.trim().isNotEmpty) {
      subtitleParts.add(problem.category!.trim());
    }
    if (problem.description != null && problem.description!.trim().isNotEmpty) {
      subtitleParts.add(problem.description!.trim());
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          Icons.report_problem_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(problem.title),
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
            if (problem.intensity != null)
              PatientProblemIntensityBadge(intensity: problem.intensity!),
            if (problem.intensity != null) const SizedBox(width: 4),
            PatientProblemStatusChip(status: problem.status),
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

({Color background, Color foreground}) _style(
  ColorScheme colors,
  PatientProblemStatus status,
) {
  return switch (status) {
    PatientProblemStatus.active => (
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
      ),
    PatientProblemStatus.improved => (
        background: colors.secondaryContainer,
        foreground: colors.onSecondaryContainer,
      ),
    PatientProblemStatus.resolved => (
        background: colors.tertiaryContainer,
        foreground: colors.onTertiaryContainer,
      ),
    PatientProblemStatus.archived => (
        background: colors.surfaceContainerHighest,
        foreground: colors.onSurfaceVariant,
      ),
  };
}
