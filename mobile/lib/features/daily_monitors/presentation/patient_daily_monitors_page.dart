import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/daily_monitor.dart';
import '../providers/daily_monitors_providers.dart';
import 'daily_monitor_routes.dart';
import 'widgets/daily_monitor_widgets.dart';

class PatientDailyMonitorsPage extends ConsumerWidget {
  const PatientDailyMonitorsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myDailyMonitorsProvider);
    final patientIdAsync = ref.watch(myPatientIdProvider);

    final body = AsyncStateBody<List<DailyMonitor>>(
      asyncValue: listAsync,
      onRetry: () => ref.read(myDailyMonitorsProvider.notifier).refresh(),
      emptyMessage: 'Você ainda não registrou nenhum acompanhamento.',
      emptyIcon: Icons.monitor_heart_outlined,
      dataBuilder: (items) => RefreshIndicator(
        onRefresh: () async {
          await ref.read(myDailyMonitorsProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            88,
          ),
          children: [
            AppPageHeader(
              title: 'Monitor diário',
              subtitle:
                  'Registre sinais, emoções e comportamentos entre as sessões para acompanhar padrões ao longo do tempo.',
              icon: Icons.monitor_heart_outlined,
              metadata: [
                Chip(label: Text('${items.length} registros')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: 'Seus registros',
              subtitle: 'Abra um dia para consultar ou editar se for hoje.',
            ),
            const SizedBox(height: AppSpacing.sm),
            MotionStaggered(
              children: [
                for (final m in items)
                  DailyMonitorListTile(
                    monitor: m,
                    onTap: () =>
                        context.push(DailyMonitorRoutes.patientDetail(m.id)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return patientIdAsync.when(
      loading: () => const AppCanopyScaffold(
        body: Center(child: BrandLoader()),
      ),
      error: (_, __) => AppScaffold(
        title: 'Monitor Diário',
        accent: AppColors.cyan,
        body: const Center(child: Text('Erro ao identificar paciente.')),
      ),
      data: (patientId) => AppCanopyScaffold(
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push(DailyMonitorRoutes.patientCreate),
          icon: const Icon(Icons.add),
          label: const Text('Novo registro'),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PatientContextHeader(
                patientId: patientId,
                pageTitle: 'MONITOR DIÁRIO',
                role: ProfileRole.patient,
                accentColor: AppColors.cyan,
              ),
            ),
            SliverFillRemaining(hasScrollBody: true, child: body),
          ],
        ),
      ),
    );
  }
}
