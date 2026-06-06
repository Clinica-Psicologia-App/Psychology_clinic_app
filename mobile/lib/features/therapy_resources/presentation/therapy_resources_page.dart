import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/therapy_resources_providers.dart';
import 'therapy_resource_routes.dart';
import 'widgets/therapy_resource_widgets.dart';

class TherapyResourcesPage extends ConsumerWidget {
  const TherapyResourcesPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffTherapyContext(role: role, patientId: patientId);
    final bundleAsync = ref.watch(staffTherapyBundleProvider(ctx));
    final recommendationsAsync = ref.watch(
      staffResourceRecommendationsProvider(ctx),
    );
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return AppScaffold(
      title: 'Recursos terapêuticos',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffTherapyBundleProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: bundleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar recursos.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(staffTherapyBundleProvider(ctx)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (bundle) {
          final activeAssigned =
              bundle.assigned.where((a) => a.isActive).toList();
          final inactiveAssigned =
              bundle.assigned.where((a) => !a.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(staffTherapyBundleProvider(ctx));
              await ref.read(staffTherapyBundleProvider(ctx).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                patientAsync.when(
                  data: (p) => p != null
                      ? Text(
                          p.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        )
                      : const SizedBox.shrink(),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sugestões terapêuticas',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                recommendationsAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recommendations) {
                    if (recommendations.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Ainda não há sinais suficientes para sugerir recursos automaticamente.',
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: recommendations
                          .map(
                            (item) => TherapyRecommendationTile(
                              recommendation: item,
                              onTap: () {
                                if (item.isAlreadyAssigned) {
                                  context.push(
                                    TherapyResourceRoutes.staffDetail(
                                      role: role,
                                      patientId: patientId,
                                      resourceId: item.resource.id,
                                    ),
                                  );
                                } else {
                                  context.push(
                                    TherapyResourceRoutes.assign(
                                      role: role,
                                      patientId: patientId,
                                      resourceId: item.resource.id,
                                    ),
                                  );
                                }
                              },
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Liberados para este paciente',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (activeAssigned.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhum recurso liberado ainda.'),
                    ),
                  )
                else
                  ...activeAssigned.map(
                    (access) => PatientAccessTile(
                      access: access,
                      onTap: () => context.push(
                        TherapyResourceRoutes.staffDetail(
                          role: role,
                          patientId: patientId,
                          resourceId: access.resourceId,
                        ),
                      ),
                    ),
                  ),
                if (inactiveAssigned.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Bloqueados anteriormente',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...inactiveAssigned.map(
                    (access) => TherapyResourceTile(
                      resource: access.resource,
                      subtitle: 'Bloqueado — toque para liberar novamente',
                      onTap: () => context.push(
                        TherapyResourceRoutes.assign(
                          role: role,
                          patientId: patientId,
                          resourceId: access.resourceId,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Biblioteca da clínica',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (bundle.library.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhum recurso cadastrado na clínica.'),
                    ),
                  )
                else
                  ...bundle.library.map((resource) {
                    final isAssigned =
                        bundle.assignedResourceIds.contains(resource.id);
                    return TherapyResourceTile(
                      resource: resource,
                      subtitle: isAssigned ? 'Já liberado' : 'Disponível',
                      trailing: isAssigned
                          ? const Icon(Icons.check_circle_outline)
                          : const Icon(Icons.add_circle_outline),
                      onTap: () {
                        if (isAssigned) {
                          context.push(
                            TherapyResourceRoutes.staffDetail(
                              role: role,
                              patientId: patientId,
                              resourceId: resource.id,
                            ),
                          );
                        } else {
                          context.push(
                            TherapyResourceRoutes.assign(
                              role: role,
                              patientId: patientId,
                              resourceId: resource.id,
                            ),
                          );
                        }
                      },
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
