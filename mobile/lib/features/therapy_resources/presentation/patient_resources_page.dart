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
import '../../daily_monitors/providers/daily_monitors_providers.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_resource_access.dart';
import '../providers/therapy_resources_providers.dart';
import 'therapy_resource_routes.dart';
import 'widgets/therapy_resource_widgets.dart';

class PatientResourcesPage extends ConsumerWidget {
  const PatientResourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myReleasedResourcesProvider);
    final patientIdAsync = ref.watch(myPatientIdProvider);

    final body = AsyncStateBody<List<PatientResourceAccess>>(
      asyncValue: listAsync,
      onRetry: () => ref.read(myReleasedResourcesProvider.notifier).refresh(),
      emptyMessage: 'Nenhum recurso liberado para você ainda.',
      emptyIcon: Icons.menu_book_outlined,
      dataBuilder: (items) => RefreshIndicator(
        onRefresh: () async {
          await ref.read(myReleasedResourcesProvider.notifier).refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          children: [
            AppPageHeader(
              title: 'Meus recursos',
              subtitle:
                  'Materiais compartilhados pelo seu psicólogo para apoiar sua prática entre as sessões.',
              icon: Icons.menu_book_outlined,
              metadata: [
                Chip(label: Text('${items.length} liberados')),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: 'Disponíveis para você',
              subtitle: 'Abra um recurso para consultar orientação e link.',
            ),
            const SizedBox(height: AppSpacing.sm),
            MotionStaggered(
              children: [
                for (final access in items)
                  PatientAccessTile(
                    access: access,
                    onTap: () => context.push(
                      TherapyResourceRoutes.patientDetail(access.id),
                    ),
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
        title: 'Recursos',
        accent: AppColors.purple,
        body: const Center(child: Text('Erro ao identificar paciente.')),
      ),
      data: (patientId) => AppCanopyScaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PatientContextHeader(
                patientId: patientId,
                pageTitle: 'RECURSOS',
                role: ProfileRole.patient,
                accentColor: AppColors.purple,
              ),
            ),
            SliverFillRemaining(hasScrollBody: true, child: body),
          ],
        ),
      ),
    );
  }
}
