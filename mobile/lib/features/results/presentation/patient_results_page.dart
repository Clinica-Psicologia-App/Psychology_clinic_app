import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../clinical_dashboard/presentation/clinical_dashboard_routes.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_response_summary.dart';
import '../providers/results_providers.dart';
import 'result_routes.dart';
import 'widgets/response_summary_tile.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientResultsPage extends ConsumerWidget {
  const PatientResultsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = PatientResultsContext(role: role, patientId: patientId);
    final listAsync = ref.watch(patientResultsListProvider(ctx));
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    final isPatient = role == ProfileRole.patient;

    return AppScaffold(
      title: isPatient ? 'Meus resultados' : 'Resultados',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(patientResultsListProvider(ctx).notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isPatient)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClayCard(
                child: ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Dashboard clínico'),
                  subtitle: const Text('Gráficos dos principais instrumentos.'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push(ClinicalDashboardRoutes.patientList),
                ),
              ),
            ),
          Expanded(
            child: AsyncStateBody<List<PatientResponseSummary>>(
              asyncValue: listAsync,
              onRetry: () =>
                  ref.read(patientResultsListProvider(ctx).notifier).refresh(),
              emptyMessage: isPatient
                  ? 'Nenhum resultado liberado ainda. Quando seu psicólogo '
                      'concluir a análise, ele aparecerá aqui.'
                  : 'Nenhuma resposta de questionário para este paciente.',
              emptyIcon: Icons.analytics_outlined,
              dataBuilder: (items) {
                final patientName = patientAsync.valueOrNull?.fullName;
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(patientResultsListProvider(ctx).notifier)
                        .refresh();
                  },
                  child: _ResultsList(
                    items: items,
                    patientName: patientName,
                    onOpen: (item) => context.push(
                      ResultRoutes.detail(
                        role: role,
                        patientId: patientId,
                        responseId: item.id,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({
    required this.items,
    required this.onOpen,
    this.patientName,
  });

  final List<PatientResponseSummary> items;
  final String? patientName;
  final ValueChanged<PatientResponseSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    final completed = items.where((item) => item.completedAt != null).length;
    final withResults = items.where((item) => item.hasResults).length;
    final reviewed = items.where((item) => item.isReviewed).length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppPageHeader(
              icon: Icons.analytics_outlined,
              title: 'Resultados dos questionários',
              subtitle: patientName == null
                  ? 'Respostas aplicadas, status de conclusão e resultados calculados.'
                  : 'Respostas aplicadas para $patientName, com status de conclusão e resultados calculados.',
              metadata: [
                StatusChip(
                  label: '${items.length} resposta(s)',
                  tone: AppStatusTone.info,
                  icon: Icons.assignment_turned_in_outlined,
                ),
                StatusChip(
                  label: '$completed concluída(s)',
                  tone: AppStatusTone.completed,
                  icon: Icons.check_circle_outline,
                ),
                StatusChip(
                  label: '$withResults com resultado',
                  tone: AppStatusTone.success,
                  icon: Icons.analytics_outlined,
                ),
                if (reviewed > 0)
                  StatusChip(
                    label: '$reviewed revisada(s)',
                    tone: AppStatusTone.neutral,
                    icon: Icons.verified_outlined,
                  ),
              ],
            ),
          );
        }

        final item = items[index - 1];
        return MotionReveal(
          delay: staggerDelay(index - 1),
          child: ResponseSummaryTile(
            summary: item,
            onTap: () => onOpen(item),
          ),
        );
      },
    );
  }
}
