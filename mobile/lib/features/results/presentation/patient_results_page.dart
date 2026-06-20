import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_response_summary.dart';
import '../providers/results_providers.dart';
import 'result_routes.dart';
import 'widgets/response_summary_tile.dart';

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

    return AppScaffold(
      title: 'Resultados',
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
              'Respostas e resultados dos questionários aplicados.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: AsyncStateBody<List<PatientResponseSummary>>(
              asyncValue: listAsync,
              onRetry: () =>
                  ref.read(patientResultsListProvider(ctx).notifier).refresh(),
              emptyMessage:
                  'Nenhuma resposta de questionário para este paciente.',
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
                    return ResponseSummaryTile(
                      summary: item,
                      onTap: () => context.push(
                        ResultRoutes.detail(
                          role: role,
                          patientId: patientId,
                          responseId: item.id,
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
