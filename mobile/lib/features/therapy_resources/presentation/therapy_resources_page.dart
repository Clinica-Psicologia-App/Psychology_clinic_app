import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/therapy_resources_providers.dart';
import 'therapy_resource_routes.dart';
import 'widgets/therapy_resource_widgets.dart';
import '../../../shared/widgets/brand_loading.dart';

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
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'Novo material',
          onPressed: () => context.push(
            TherapyResourceRoutes.newResource(
              role: role,
              patientId: patientId,
            ),
          ),
          icon: const Icon(Icons.add),
        ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffTherapyBundleProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: bundleAsync.when(
        loading: () => const BrandLoader(),
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              children: [
                patientAsync.when(
                  data: (p) => AppPageHeader(
                    title: 'Recursos terapêuticos',
                    subtitle: p != null
                        ? 'Gerencie materiais liberados para ${p.fullName}, sugestões clínicas e biblioteca da clínica.'
                        : 'Gerencie materiais liberados, sugestões clínicas e biblioteca da clínica.',
                    icon: Icons.menu_book_outlined,
                    metadata: [
                      Chip(label: Text('${activeAssigned.length} liberados')),
                      Chip(
                          label:
                              Text('${bundle.library.length} na biblioteca')),
                    ],
                    primaryAction: FilledButton.icon(
                      onPressed: () => context.push(
                        TherapyResourceRoutes.newResource(
                          role: role,
                          patientId: patientId,
                        ),
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('Novo material'),
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => AppPageHeader(
                    title: 'Recursos terapêuticos',
                    subtitle:
                        'Gerencie materiais liberados, sugestões clínicas e biblioteca da clínica.',
                    icon: Icons.menu_book_outlined,
                    metadata: [
                      Chip(label: Text('${activeAssigned.length} liberados')),
                      Chip(
                          label:
                              Text('${bundle.library.length} na biblioteca')),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppSectionHeader(
                  title: 'Sugestões terapêuticas',
                  subtitle:
                      'Recursos sugeridos a partir dos sinais clínicos já registrados.',
                ),
                const SizedBox(height: AppSpacing.sm),
                recommendationsAsync.when(
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: LinearProgressIndicator(),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (recommendations) {
                    if (recommendations.isEmpty) {
                      return const AppInfoCard(
                        title: 'Sem sugestões automáticas',
                        body:
                            'Ainda não há sinais suficientes para sugerir recursos automaticamente.',
                        icon: Icons.auto_awesome_outlined,
                      );
                    }

                    return MotionStaggered(
                      children: [
                        for (final item in recommendations)
                          TherapyRecommendationTile(
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
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                const AppSectionHeader(
                  title: 'Liberados para este paciente',
                  subtitle:
                      'Materiais ativos que o paciente consegue acessar no app.',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (activeAssigned.isEmpty)
                  const AppInfoCard(
                    title: 'Nenhum recurso liberado',
                    body:
                        'Use a biblioteca ou as sugestões para liberar um material.',
                    icon: Icons.lock_open_outlined,
                  )
                else
                  MotionStaggered(
                    children: [
                      for (final access in activeAssigned)
                        PatientAccessTile(
                          access: access,
                          onTap: () => context.push(
                            TherapyResourceRoutes.staffDetail(
                              role: role,
                              patientId: patientId,
                              resourceId: access.resourceId,
                            ),
                          ),
                        ),
                    ],
                  ),
                if (inactiveAssigned.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const AppSectionHeader(
                    title: 'Bloqueados anteriormente',
                    subtitle:
                        'Materiais já associados que podem ser liberados novamente.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...inactiveAssigned.map(
                    (access) => TherapyResourceTile(
                      resource: access.resource,
                      subtitle: 'Bloqueado - toque para liberar novamente',
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
                const SizedBox(height: AppSpacing.xl),
                const AppSectionHeader(
                  title: 'Biblioteca da clínica',
                  subtitle:
                      'Materiais cadastrados para uso nos acompanhamentos.',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (bundle.library.isEmpty)
                  const AppInfoCard(
                    title: 'Biblioteca vazia',
                    body:
                        'Cadastre o primeiro material para começar a liberar.',
                    icon: Icons.library_books_outlined,
                  )
                else
                  MotionStaggered(
                    children: [
                      for (final resource in bundle.library)
                        Builder(
                          builder: (context) {
                            final isAssigned = bundle.assignedResourceIds
                                .contains(resource.id);
                            return TherapyResourceTile(
                              resource: resource,
                              subtitle:
                                  isAssigned ? 'Já liberado' : 'Disponível',
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
                          },
                        ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
