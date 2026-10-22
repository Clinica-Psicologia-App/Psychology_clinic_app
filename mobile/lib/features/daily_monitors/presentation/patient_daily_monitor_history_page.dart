import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
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

    return AppCanopyScaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PatientContextHeader(
              patientId: patientId,
              pageTitle: 'MONITOR DIÁRIO',
              role: role,
              accentColor: AppColors.cyan,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
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
