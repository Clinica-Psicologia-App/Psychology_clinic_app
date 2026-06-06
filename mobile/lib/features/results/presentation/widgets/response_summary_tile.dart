import 'package:flutter/material.dart';

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
    final completed = summary.completedAt;
    final dateLabel = completed != null
        ? MaterialLocalizations.of(context).formatFullDate(completed)
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(context, summary.status),
          child: Icon(
            _statusIcon(summary.status),
            color: Theme.of(context).colorScheme.onPrimary,
            size: 20,
          ),
        ),
        title: Text(summary.questionnaireName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${summary.questionnaireCode}'),
            Text('Status: ${summary.status.label}'),
            Text('Conclusão: $dateLabel'),
            Text('Respostas: ${summary.answerCount}'),
            Text(
              summary.hasResults
                  ? 'Resultado: disponível (${summary.resultsCount})'
                  : 'Resultado: pendente',
            ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
