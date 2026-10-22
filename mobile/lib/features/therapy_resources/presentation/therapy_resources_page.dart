import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/therapy_resources_providers.dart';
import 'therapy_resource_routes.dart';
import 'widgets/therapy_resource_widgets.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';

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

    return AppCanopyScaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: PatientContextHeader(
              patientId: patientId,
              pageTitle: 'RECURSOS TERAPÊUTICOS',
              role: role,
              accentColor: AppColors.purple,
              actions: [
                PatientHeaderActionBtn(
                  icon: Icons.add,
                  label: 'Novo material',
                  onTap: () => context.push(
                    TherapyResourceRoutes.newResource(
                      role: role,
                      patientId: patientId,
                    ),
                  ),
                ),
                PatientHeaderActionBtn(
                  icon: Icons.refresh,
                  label: 'Atualizar',
                  onTap: () => ref.invalidate(staffTherapyBundleProvider(ctx)),
                ),
              ],
            ),
          ),
          if (bundleAsync.isLoading)
            const SliverFillRemaining(child: BrandLoader())
          else if (bundleAsync.hasError)
            SliverFillRemaining(
              child: Center(
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
            )
          else
            _buildContent(context, ref, ctx),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    StaffTherapyContext ctx,
  ) {
    final bundleAsync = ref.watch(staffTherapyBundleProvider(ctx));
    final recommendationsAsync = ref.watch(
      staffResourceRecommendationsProvider(ctx),
    );
    final bundle = bundleAsync.valueOrNull;
    if (bundle == null) return const SliverToBoxAdapter(child: SizedBox());

    final activeAssigned = bundle.assigned.where((a) => a.isActive).toList();
    final inactiveAssigned =
        bundle.assigned.where((a) => !a.isActive).toList();

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
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
        ]),
      ),
    );
  }
}
