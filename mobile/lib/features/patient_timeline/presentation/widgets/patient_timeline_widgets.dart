import 'package:flutter/material.dart';

import '../../domain/patient_timeline_event.dart';

class PatientTimelineEventTile extends StatelessWidget {
  const PatientTimelineEventTile({
    super.key,
    required this.event,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final PatientTimelineEvent event;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensitive = event.isSensitive;
    final lineColor = theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sensitive
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 0 : 4,
                bottom: isLast ? 0 : 12,
              ),
              child: Card(
                color: sensitive
                    ? theme.colorScheme.errorContainer.withValues(alpha: 0.25)
                    : null,
                child: ListTile(
                  leading: sensitive
                      ? Icon(
                          Icons.lock_outline,
                          color: theme.colorScheme.error,
                        )
                      : Icon(
                          Icons.event_note_outlined,
                          color: theme.colorScheme.primary,
                        ),
                  title: Text(event.title),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.dateLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      if (event.subtitleLine != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(event.subtitleLine!),
                        ),
                      if (event.description != null &&
                          event.description!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            event.description!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (sensitive)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Conteúdo sensível',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onTap,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimelineEventDetailBody extends StatelessWidget {
  const TimelineEventDetailBody({super.key, required this.event});

  final PatientTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (event.isSensitive)
          Card(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
            child: const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Evento marcado como sensível'),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  event.dateLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (event.category != null && event.category!.trim().isNotEmpty)
                  _DetailRow(label: 'Categoria', value: event.category!.trim()),
                if (event.periodLabel != null &&
                    event.periodLabel!.trim().isNotEmpty)
                  _DetailRow(
                    label: 'Período',
                    value: event.periodLabel!.trim(),
                  ),
                if (event.emotionalImpact != null)
                  _DetailRow(
                    label: 'Impacto emocional',
                    value: '${event.emotionalImpact}/10',
                  ),
                if (event.description != null &&
                    event.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Descrição', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(event.description!.trim()),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
