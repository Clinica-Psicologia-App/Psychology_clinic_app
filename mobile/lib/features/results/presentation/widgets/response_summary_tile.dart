import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/patient_response_summary.dart';
import '../../domain/questionnaire_response_status.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

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
        : null;
    final accent = _statusColor(summary.status);

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
                  color: accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.45),
                      blurRadius: 4,
                      offset: const Offset(-2, -2),
                    ),
                    BoxShadow(
                      color: accent.withValues(alpha: 0.38),
                      blurRadius: 10,
                      offset: const Offset(3, 5),
                    ),
                  ],
                ),
                child: Icon(
                  _statusIcon(summary.status),
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
                      summary.questionnaireName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        summary.questionnaireCode,
                        if (dateLabel != null) dateLabel,
                        '${summary.answerCount} respostas',
                      ].join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Pill(
                          icon: _statusIcon(summary.status),
                          label: summary.status.label,
                          color: accent,
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

  Color _statusColor(QuestionnaireResponseStatus status) {
    switch (status) {
      case QuestionnaireResponseStatus.completed:
        return AppColors.turquoise;
      case QuestionnaireResponseStatus.cancelled:
        return AppColors.error;
      case QuestionnaireResponseStatus.draft:
        return AppColors.cyan;
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

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
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
