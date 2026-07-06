import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/genogram_data.dart';
import '../../domain/genogram_person.dart';
import '../../domain/genogram_relationship.dart';
import '../../domain/genogram_relationship_type.dart';

class GenogramGraphicNotice extends StatelessWidget {
  const GenogramGraphicNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Visualização em árvore gráfica será adicionada em versão futura. '
                'Por enquanto, use as listas de pessoas e relações abaixo.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GenogramSummaryCard extends StatelessWidget {
  const GenogramSummaryCard({super.key, required this.data});

  final GenogramData data;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            _Stat(
              icon: Icons.person_outline,
              label: 'Pessoas',
              value: '${data.people.length}',
            ),
            const SizedBox(width: AppSpacing.xl),
            _Stat(
              icon: Icons.link,
              label: 'Relações',
              value: '${data.relationships.length}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              Text(value, style: theme.textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }
}

class GenogramPersonTile extends StatelessWidget {
  const GenogramPersonTile({
    super.key,
    required this.person,
    required this.onTap,
  });

  final GenogramPerson person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensitive = person.isSensitive;
    // Confidencialidade discreta (cadeado + roxo), não alarme.
    final accent = sensitive ? AppColors.purple : AppColors.moduleGenogram;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: sensitive
          ? AppColors.purple.withValues(alpha: 0.05)
          : AppColors.surface,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  sensitive ? Icons.lock_outline : Icons.person_outline,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensitive ? 'Conteúdo sensível' : person.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (sensitive)
                      Text(
                        'Toque para abrir com aviso.',
                        style: theme.textTheme.bodySmall,
                      )
                    else ...[
                      if (person.relationshipToPatient != null &&
                          person.relationshipToPatient!.trim().isNotEmpty)
                        Text(
                          person.relationshipToPatient!.trim(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (person.lifeSpanLabel != null)
                            StatusChip(
                              label: person.lifeSpanLabel!,
                              tone: AppStatusTone.neutral,
                              icon: Icons.calendar_today_outlined,
                            ),
                          if (person.isDeceased)
                            const StatusChip(
                              label: 'Falecido',
                              tone: AppStatusTone.neutral,
                              icon: Icons.history_outlined,
                            ),
                        ],
                      ),
                    ],
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
}

class GenogramRelationshipTile extends StatelessWidget {
  const GenogramRelationshipTile({
    super.key,
    required this.relationship,
    required this.data,
    required this.onTap,
  });

  final GenogramRelationship relationship;
  final GenogramData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensitive = relationship.isSensitive;
    final aName = data.personNameById(relationship.personAId);
    final bName = data.personNameById(relationship.personBId);
    // Confidencialidade discreta (cadeado + roxo), não alarme.
    final accent = sensitive ? AppColors.purple : AppColors.moduleTimeline;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      color: sensitive
          ? AppColors.purple.withValues(alpha: 0.05)
          : AppColors.surface,
      child: InkWell(
        borderRadius: AppRadius.lgAll,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  sensitive ? Icons.lock_outline : Icons.link,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sensitive
                          ? 'Relação com conteúdo sensível'
                          : relationship.labelBetween(aName, bName),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (sensitive)
                      Text(
                        'Toque para abrir com aviso.',
                        style: theme.textTheme.bodySmall,
                      )
                    else ...[
                      StatusChip(
                        label: relationship.relationshipType.label,
                        tone: AppStatusTone.info,
                        icon: Icons.sync_alt_outlined,
                      ),
                      if (relationship.notes != null &&
                          relationship.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          relationship.notes!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
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
}
