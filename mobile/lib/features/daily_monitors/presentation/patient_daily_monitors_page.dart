import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../domain/daily_monitor.dart';
import '../providers/daily_monitors_providers.dart';
import 'daily_monitor_routes.dart';
import 'widgets/daily_monitor_widgets.dart';

class PatientDailyMonitorsPage extends ConsumerWidget {
  const PatientDailyMonitorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myDailyMonitorsProvider);

    return AppScaffold(
      title: 'Monitor diário',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(DailyMonitorRoutes.patientCreate),
        icon: const Icon(Icons.add),
        label: const Text('Novo registro'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(myDailyMonitorsProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<DailyMonitor>>(
        asyncValue: listAsync,
        onRetry: () => ref.read(myDailyMonitorsProvider.notifier).refresh(),
        emptyMessage: 'Você ainda não registrou nenhum acompanhamento.',
        emptyIcon: Icons.monitor_heart_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myDailyMonitorsProvider.notifier).refresh();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              Text(
                'Registre como está se sentindo entre as sessões.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (m) => DailyMonitorListTile(
                  monitor: m,
                  onTap: () => context.push(DailyMonitorRoutes.patientDetail(m.id)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
