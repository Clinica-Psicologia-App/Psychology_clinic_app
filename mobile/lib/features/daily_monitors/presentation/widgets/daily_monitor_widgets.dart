import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_page_header.dart';
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        AppPageHeader(
          title: 'Registro diário',
          subtitle:
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          icon: Icons.monitor_heart_outlined,
          metadata: [
            if (payload.intensity != null)
              Chip(label: Text('Intensidade ${payload.intensity}/10')),
            if (readOnly) const Chip(label: Text('Somente leitura')),
          ],
        ),
        if (!readOnly && !monitor.isEditableToday)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: AppInfoCard(
              title: 'Edição indisponível',
              body: 'Registro de dias anteriores não pode ser editado.',
              icon: Icons.lock_clock_outlined,
              tone: AppInfoCardTone.warning,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Conteúdo do registro',
          subtitle: 'Informações preenchidas no monitor diário.',
        ),
        const SizedBox(height: AppSpacing.sm),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppInfoCard(
        title: title,
        body: body!,
      ),
    );
  }
}
