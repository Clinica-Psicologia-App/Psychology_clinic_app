import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Materiais compartilhados pelo seu psicólogo.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              ...items.map(
                (access) => PatientAccessTile(
                  access: access,
                  onTap: () => context.push(
                    TherapyResourceRoutes.patientDetail(access.id),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
