import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../data/admin_psychoeducation_repository.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';
import 'psychoeducation_routes.dart';

/// Curadoria dos módulos de psicoeducação (admin): lista, publica e edita.
class AdminPsychoeducationCatalogPage extends ConsumerWidget {
  const AdminPsychoeducationCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminPsychoListProvider);

    return AppScaffold(
      title: 'Psicoeducação',
      subtitle: 'Módulos da Biblioteca · liberação aos psicólogos e pacientes',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(adminPsychoListProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(PsychoeducationRoutes.adminNew),
        icon: const Icon(Icons.add),
        label: const Text('Novo módulo'),
      ),
      body: ResponsiveContent(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _Error(
            message: _message(e),
            onRetry: () => ref.invalidate(adminPsychoListProvider),
          ),
          data: (modules) => RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(adminPsychoListProvider.future),
            child: modules.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Nenhum módulo cadastrado.')),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 96),
                    itemCount: modules.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) => _ModuleCard(module: modules[i]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends ConsumerWidget {
  const _ModuleCard({required this.module});
  final AdminPsychoModule module;

  Color get _stageColor => switch (module.stage) {
        'Conhecer' => const Color(0xFF14B8A6),
        'Transformar' => const Color(0xFF059669),
        _ => const Color(0xFF6366F1),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _stageColor;
    return ClayCard(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (module.isPublished ? AppColors.success : AppColors.textMuted)
              .withValues(alpha: 0.16),
        ),
      ),
      child: InkWell(
        onTap: () =>
            context.push(PsychoeducationRoutes.adminModule(module.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${module.number}',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${module.stage} · ${module.cardCount} cards',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PublishSwitch(module: module),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishSwitch extends ConsumerWidget {
  const _PublishSwitch({required this.module});
  final AdminPsychoModule module;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: module.isPublished,
          onChanged: (v) async {
            try {
              await ref
                  .read(psychoMutationProvider.notifier)
                  .setPublished(module.id, v);
              ref.invalidate(adminPsychoListProvider);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_message(e))),
                );
              }
            }
          },
        ),
        Text(
          module.isPublished ? 'Publicado' : 'Oculto',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: module.isPublished
                    ? AppColors.success
                    : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
                onPressed: onRetry, child: const Text('Tentar novamente')),
          ]),
        ),
      );
}

String _message(Object error) =>
    error.toString().replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');
