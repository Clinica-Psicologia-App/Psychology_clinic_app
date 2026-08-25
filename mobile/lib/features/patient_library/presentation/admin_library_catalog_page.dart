import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../data/admin_library_repository.dart';
import '../providers/admin_library_providers.dart';
import 'admin_library_routes.dart';
import 'widgets/library_cover.dart';
import '../../../shared/widgets/brand_loading.dart';

/// Curadoria do catálogo da Biblioteca (admin): lista todas as obras, controla
/// a publicação (liberação para os psicólogos) e leva ao editor.
class AdminLibraryCatalogPage extends ConsumerStatefulWidget {
  const AdminLibraryCatalogPage({super.key});

  @override
  ConsumerState<AdminLibraryCatalogPage> createState() =>
      _AdminLibraryCatalogPageState();
}

class _AdminLibraryCatalogPageState
    extends ConsumerState<AdminLibraryCatalogPage> {
  String _query = '';

  String? get _queryArg => _query.trim().isEmpty ? null : _query.trim();

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(adminLibraryListProvider(_queryArg));

    return AppScaffold(
      title: 'Catálogo da Biblioteca',
      accent: AppColors.cyan,
      subtitle: 'Curadoria de filmes e séries · liberação para os psicólogos',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(adminLibraryListProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AdminLibraryRoutes.newWork),
        icon: const Icon(Icons.add),
        label: const Text('Nova obra'),
      ),
      body: ResponsiveContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.sm),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por título…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.surfaceTint,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: listAsync.when(
                loading: () => const BrandLoader(),
                error: (error, _) => _Error(
                  message: _message(error),
                  onRetry: () => ref.invalidate(adminLibraryListProvider),
                ),
                data: (items) => RefreshIndicator(
                  onRefresh: () async =>
                      ref.refresh(adminLibraryListProvider(_queryArg).future),
                  child: items.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 160),
                          Center(child: Text('Nenhuma obra encontrada.')),
                        ])
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl, 0, AppSpacing.xl, 96),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) => _WorkCard(work: items[i]),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _kSeriesCoverFallback = [Color(0xFF2E7D6B), Color(0xFF11808F)];
const _kMovieCoverFallback = [Color(0xFF3B2F8F), Color(0xFF7C6A9C)];

class _WorkCard extends ConsumerWidget {
  const _WorkCard({required this.work});
  final AdminLibraryWork work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = work.isPublished ? AppColors.success : AppColors.textMuted;
    final meta = <String>[
      work.workType,
      if (work.year != null) '${work.year}',
      if (work.intensity != null) 'Intensidade ${work.intensity}',
    ].join(' · ');

    return ClayCard(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.16)),
      ),
      child: InkWell(
        onTap: () => context.push(AdminLibraryRoutes.work(work.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 64,
                  child: LibraryCover(
                    gradient: work.workType == 'Série' ||
                            work.workType == 'Minissérie'
                        ? _kSeriesCoverFallback
                        : _kMovieCoverFallback,
                    url: work.coverUrl,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(work.displayTitle,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(meta,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _StatusPill(published: work.isPublished),
                        if (work.primarySchema != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              work.primarySchema!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Liberação para os psicólogos.
              _PublishSwitch(work: work),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublishSwitch extends ConsumerWidget {
  const _PublishSwitch({required this.work});
  final AdminLibraryWork work;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(
          value: work.isPublished,
          onChanged: (v) async {
            try {
              await ref
                  .read(libraryCatalogMutationProvider.notifier)
                  .setPublished(work.id, v);
              ref.invalidate(adminLibraryListProvider);
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
          work.isPublished ? 'Publicada' : 'Oculta',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color:
                    work.isPublished ? AppColors.success : AppColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.published});
  final bool published;

  @override
  Widget build(BuildContext context) {
    final color = published ? AppColors.success : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(published ? Icons.visibility : Icons.visibility_off,
              size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            published ? 'Liberada' : 'Não liberada',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
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

String _message(Object error) {
  return error
      .toString()
      .replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');
}
