import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/patient_response_summary.dart';
import '../../domain/questionnaire_response_status.dart';

class ResponseSummaryTile extends StatelessWidget {
  const ResponseSummaryTile({
    super.key,
    required this.summary,
    required this.onTap,
  });

  final PatientResponseSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = summary.completedAt;
    final dateLabel = completed != null
        ? MaterialLocalizations.of(context).formatFullDate(completed)
        : 'Sem conclusão';
    final statusTone = switch (summary.status) {
      QuestionnaireResponseStatus.completed => AppStatusTone.completed,
      QuestionnaireResponseStatus.cancelled => AppStatusTone.error,
      QuestionnaireResponseStatus.draft => AppStatusTone.warning,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(context, summary.status)
                      .withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  _statusIcon(summary.status),
                  color: _statusColor(context, summary.status),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.questionnaireName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      summary.questionnaireCode,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusChip(
                          label: summary.status.label,
                          tone: statusTone,
                          icon: _statusIcon(summary.status),
                        ),
                        StatusChip(
                          label: dateLabel,
                          tone: AppStatusTone.neutral,
                          icon: Icons.event_outlined,
                        ),
                        StatusChip(
                          label: '${summary.answerCount} resposta(s)',
                          tone: AppStatusTone.info,
                          icon: Icons.format_list_numbered_outlined,
                        ),
                        StatusChip(
                          label: summary.hasResults
                              ? '${summary.resultsCount} resultado(s)'
                              : 'Resultado pendente',
                          tone: summary.hasResults
                              ? AppStatusTone.success
                              : AppStatusTone.warning,
                          icon: summary.hasResults
                              ? Icons.analytics_outlined
                              : Icons.hourglass_empty_outlined,
                        ),
                        if (summary.isReviewed)
                          const StatusChip(
                            label: 'Revisado',
                            tone: AppStatusTone.completed,
                            icon: Icons.verified_outlined,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(BuildContext context, QuestionnaireResponseStatus status) {
    switch (status) {
      case QuestionnaireResponseStatus.completed:
        return Theme.of(context).colorScheme.primary;
      case QuestionnaireResponseStatus.cancelled:
        return Theme.of(context).colorScheme.error;
      case QuestionnaireResponseStatus.draft:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  IconData _statusIcon(QuestionnaireResponseStatus status) {
    switch (status) {
      case QuestionnaireResponseStatus.completed:
        return Icons.check_circle_outline;
      case QuestionnaireResponseStatus.cancelled:
        return Icons.cancel_outlined;
      case QuestionnaireResponseStatus.draft:
        return Icons.edit_note_outlined;
    }
  }
}
