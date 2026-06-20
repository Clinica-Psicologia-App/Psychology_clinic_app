import 'package:flutter/material.dart';

import '../../domain/daily_monitor.dart';

class DailyMonitorListTile extends StatelessWidget {
  const DailyMonitorListTile({
    super.key,
    required this.monitor,
    required this.onTap,
  });

  final DailyMonitor monitor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = monitor.createdAt.toLocal();
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final intensity = monitor.emotionPayload.intensity;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            intensity?.toString() ?? '·',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        title: Text(monitor.summaryLine),
        subtitle: Text(dateLabel),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class DailyMonitorDetailBody extends StatelessWidget {
  const DailyMonitorDetailBody({
    super.key,
    required this.monitor,
    this.readOnly = true,
  });

  final DailyMonitor monitor;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final payload = monitor.emotionPayload;
    final date = monitor.createdAt.toLocal();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
          'às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (!readOnly && !monitor.isEditableToday)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Registro de dias anteriores não pode ser editado.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        const SizedBox(height: 16),
        _Section(
          title: 'Humor / estado emocional',
          body: monitor.moodState,
        ),
        _Section(
          title: 'Intensidade',
          body: payload.intensity != null ? '${payload.intensity}/10' : null,
        ),
        _Section(title: 'Gatilhos', body: payload.triggers),
        _Section(title: 'Comportamentos', body: monitor.behaviors),
        _Section(title: 'Observações', body: monitor.observations),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    if (body == null || body!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(body!),
        ],
      ),
    );
  }
}
