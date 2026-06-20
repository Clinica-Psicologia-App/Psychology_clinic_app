import 'package:flutter/material.dart';

import '../../domain/questionnaire.dart';
import '../../domain/reference_period.dart';

class QuestionnaireListTile extends StatelessWidget {
  const QuestionnaireListTile({
    super.key,
    required this.questionnaire,
    required this.onTap,
    this.enabled = true,
    this.showStaffDetails = false,
  });

  final Questionnaire questionnaire;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showStaffDetails;

  @override
  Widget build(BuildContext context) {
    final meta = <Widget>[
      Text('Código: ${questionnaire.code}'),
      if (questionnaire.authorName != null &&
          questionnaire.authorName!.trim().isNotEmpty)
        Text('Autor: ${questionnaire.authorName}'),
      if (questionnaire.instrumentVersion != null &&
          questionnaire.instrumentVersion!.trim().isNotEmpty)
        Text('Versao: ${questionnaire.instrumentVersion}'),
      if (questionnaire.referencePeriod != ReferencePeriod.unspecified)
        _MetaChip(
          icon: Icons.schedule_outlined,
          label: _referencePeriodLabel(questionnaire.referencePeriod),
        ),
      if (questionnaire.isParentalStyles)
        const _MetaChip(
          icon: Icons.family_restroom_outlined,
          label: 'Mãe e pai',
        ),
      _MetaChip(
        icon: questionnaire.isClinicallyApproved
            ? Icons.verified_outlined
            : Icons.science_outlined,
        label: questionnaire.clinicalStatus.label,
      ),
    ];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        enabled: enabled,
        leading: CircleAvatar(
          child: Icon(
            Icons.assignment_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(questionnaire.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: meta,
            ),
            if (questionnaire.description != null &&
                questionnaire.description!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  questionnaire.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (showStaffDetails &&
                questionnaire.licenseNotes != null &&
                questionnaire.licenseNotes!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  questionnaire.licenseNotes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: questionnaire.hasLicensePendingValidation
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
        trailing: enabled
            ? const Icon(Icons.chevron_right)
            : const Icon(Icons.lock_outline),
        isThreeLine: questionnaire.description != null || showStaffDetails,
        onTap: onTap,
      ),
    );
  }
}

String _referencePeriodLabel(ReferencePeriod period) {
  return switch (period) {
    ReferencePeriod.lastMonth => 'Último mês',
    ReferencePeriod.lastYear => 'Últimos 12 meses',
    ReferencePeriod.lifetime => 'História de vida',
    ReferencePeriod.unspecified => 'Sem período',
  };
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
