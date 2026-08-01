import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
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
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: patientAsync.when(
              data: (p) => AppPageHeader(
                title: 'Monitor diário',
                subtitle: p != null
                    ? 'Histórico de registros de ${p.fullName} para leitura clínica entre sessões.'
                    : 'Histórico de registros do paciente para leitura clínica entre sessões.',
                icon: Icons.monitor_heart_outlined,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const AppPageHeader(
                title: 'Monitor diário',
                subtitle:
                    'Histórico de registros do paciente para leitura clínica entre sessões.',
                icon: Icons.monitor_heart_outlined,
              ),
            ),
          ),
          Expanded(
            child: AsyncStateBody<List<DailyMonitor>>(
              asyncValue: listAsync,
              onRetry: () => ref.invalidate(staffPatientMonitorsProvider(ctx)),
              emptyMessage:
                  'Este paciente ainda não registrou acompanhamentos.',
              emptyIcon: Icons.monitor_heart_outlined,
              dataBuilder: (items) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(staffPatientMonitorsProvider(ctx));
                  await ref.read(staffPatientMonitorsProvider(ctx).future);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xxxl,
                  ),
                  itemCount: items.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppSectionHeader(
                          title: 'Registros do paciente',
                          subtitle: 'Visualização somente leitura.',
                        ),
                      );
                    }
                    final m = items[index - 1];
                    return MotionReveal(
                      delay: staggerDelay(index),
                      child: DailyMonitorListTile(
                        monitor: m,
                        onTap: () => context.push(
                          DailyMonitorRoutes.staffDetail(
                            role: role,
                            patientId: patientId,
                            monitorId: m.id,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
