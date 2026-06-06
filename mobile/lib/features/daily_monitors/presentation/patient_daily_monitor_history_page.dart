import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/daily_monitor.dart';
import '../providers/daily_monitors_providers.dart';
import 'daily_monitor_routes.dart';
import 'widgets/daily_monitor_widgets.dart';

class PatientDailyMonitorHistoryPage extends ConsumerWidget {
  const PatientDailyMonitorHistoryPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffMonitorHistoryContext(role: role, patientId: patientId);
    final listAsync = ref.watch(staffPatientMonitorsProvider(ctx));
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return AppScaffold(
      title: 'Monitor diário',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffPatientMonitorsProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          patientAsync.when(
            data: (p) => p != null
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      p.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
            error: (_, __) => const SizedBox.shrink(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Histórico de registros (somente leitura).',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: AsyncStateBody<List<DailyMonitor>>(
              asyncValue: listAsync,
              onRetry: () => ref.invalidate(staffPatientMonitorsProvider(ctx)),
              emptyMessage: 'Este paciente ainda não registrou acompanhamentos.',
              emptyIcon: Icons.monitor_heart_outlined,
              dataBuilder: (items) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(staffPatientMonitorsProvider(ctx));
                  await ref.read(staffPatientMonitorsProvider(ctx).future);
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: items
                      .map(
                        (m) => DailyMonitorListTile(
                          monitor: m,
                          onTap: () => context.push(
                            DailyMonitorRoutes.staffDetail(
                              role: role,
                              patientId: patientId,
                              monitorId: m.id,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
