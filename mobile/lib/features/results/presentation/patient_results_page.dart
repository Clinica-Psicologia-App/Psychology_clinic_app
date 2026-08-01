import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
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
          if (!isPatient) _StaffPatientHeader(patientId: patientId),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              isPatient
                  ? 'Resultados liberados pelo seu psicólogo.'
                  : 'Respostas e resultados dos questionários aplicados.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
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
              dataBuilder: (items) => RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(patientResultsListProvider(ctx).notifier)
                      .refresh();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return MotionReveal(
                      delay: staggerDelay(index),
                      child: ResponseSummaryTile(
                        summary: item,
                        onTap: () => context.push(
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
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffPatientHeader extends ConsumerWidget {
  const _StaffPatientHeader({required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    return patientAsync.when(
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
    );
  }
}
