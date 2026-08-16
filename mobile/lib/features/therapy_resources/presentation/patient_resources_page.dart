import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../domain/patient_resource_access.dart';
import '../providers/therapy_resources_providers.dart';
import 'therapy_resource_routes.dart';
import 'widgets/therapy_resource_widgets.dart';

class PatientResourcesPage extends ConsumerWidget {
  const PatientResourcesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myReleasedResourcesProvider);

    return AppScaffold(
      title: 'Meus recursos',
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(myReleasedResourcesProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientResourceAccess>>(
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
      ),
    );
  }
}
