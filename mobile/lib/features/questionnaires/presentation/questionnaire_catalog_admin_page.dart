import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/questionnaire_catalog_admin.dart';
import '../providers/questionnaire_catalog_admin_providers.dart';
import 'questionnaire_routes.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class QuestionnaireCatalogAdminPage extends ConsumerWidget {
  const QuestionnaireCatalogAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(questionnaireCatalogAdminListProvider);
    return AppScaffold(
      title: 'Catálogo de questionários',
      accent: AppColors.blue,
      subtitle: 'Instrumentos, versões e governança clínica',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(questionnaireCatalogAdminListProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(QuestionnaireRoutes.adminCatalogNew),
        icon: const Icon(Icons.add),
        label: const Text('Novo questionário'),
      ),
      body: ResponsiveContent(
        child: catalog.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CatalogError(
            message: _message(error),
            onRetry: () =>
                ref.invalidate(questionnaireCatalogAdminListProvider),
          ),
          data: (items) => RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(questionnaireCatalogAdminListProvider.future),
            child: items.isEmpty
                ? ListView(children: const [
                    SizedBox(height: 160),
                    Center(child: Text('Nenhum questionário cadastrado.')),
                  ])
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 96),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) =>
                        _QuestionnaireCard(item: items[index]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _QuestionnaireCard extends StatelessWidget {
  const _QuestionnaireCard({required this.item});
  final QuestionnaireCatalogAdminItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.clinicalStatus) {
      'approved' => AppColors.success,
      'suspended' => AppColors.warning,
      _ => AppColors.blue,
    };
    final status = switch (item.clinicalStatus) {
      'approved' => 'Publicado',
      'suspended' => 'Arquivado',
      'validation' => 'Em validação',
      _ => 'Rascunho',
    };
    return ClayCard(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.16)),
      ),
      child: InkWell(
        onTap: () =>
            context.push(QuestionnaireRoutes.adminCatalogDetail(item.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.72)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.26),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.assignment_outlined, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                )),
                    const SizedBox(height: AppSpacing.xxs),
                    Text('${item.code} • versão ${item.version ?? '-'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _Tag(label: status, color: color),
                      _Tag(label: '${item.questionCount} perguntas'),
                      _Tag(label: '${item.responseCount} respostas'),
                    ]),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color = AppColors.textSecondary});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700)),
      );
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.message, required this.onRetry});
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

String _message(Object error) {
  final text = error.toString();
  return text.replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');
}
