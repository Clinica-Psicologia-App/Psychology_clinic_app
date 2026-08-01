import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/genogram_data.dart';
import '../../domain/genogram_person.dart';
import '../../domain/genogram_relationship.dart';

class GenogramGraphicNotice extends StatelessWidget {
  const GenogramGraphicNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _Stat(
              icon: Icons.person_outline,
              label: 'Pessoas',
              value: '${data.people.length}',
            ),
            const SizedBox(width: 24),
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
    const accent = AppColors.moduleGenogram;
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withValues(alpha: 0.78)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.30),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: sensitive
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.25)
          : null,
      child: ListTile(
        leading: Icon(
          sensitive ? Icons.lock_outline : Icons.person_outline,
          color:
              sensitive ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        title: Text(person.displayName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (person.relationshipToPatient != null &&
                person.relationshipToPatient!.trim().isNotEmpty)
              Text(person.relationshipToPatient!.trim()),
            if (person.lifeSpanLabel != null) Text(person.lifeSpanLabel!),
            if (person.isDeceased)
              Text(
                'Falecido',
                style: theme.textTheme.labelSmall,
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: sensitive
          ? theme.colorScheme.errorContainer.withValues(alpha: 0.25)
          : null,
      child: ListTile(
        leading: Icon(
          sensitive ? Icons.lock_outline : Icons.link,
          color:
              sensitive ? theme.colorScheme.error : theme.colorScheme.primary,
        ),
        title: Text(relationship.labelBetween(aName, bName)),
        subtitle:
            relationship.notes != null && relationship.notes!.trim().isNotEmpty
                ? Text(
                    relationship.notes!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
        isThreeLine: relationship.notes != null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
