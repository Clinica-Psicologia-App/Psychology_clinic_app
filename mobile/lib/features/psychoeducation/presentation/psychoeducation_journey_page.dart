import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';

/// Jornada de psicoeducação: módulos organizados por etapa
/// (Conhecer · Compreender · Transformar).
///
/// Usada pelo paciente e, em modo leitura, pelo psicólogo — a diferença é só a
/// rota do módulo (`moduleRouteBuilder`) e o texto do cabeçalho (`staffView`).
class PsychoeducationJourneyPage extends ConsumerWidget {
  const PsychoeducationJourneyPage({
    super.key,
    required this.moduleRouteBuilder,
    this.staffView = false,
  });

  /// Constrói a rota do leitor de um módulo a partir do id.
  final String Function(String moduleId) moduleRouteBuilder;

  /// Cabeçalho na visão do psicólogo (referência) x paciente (jornada).
  final bool staffView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(psychoeducationJourneyProvider);

    return AppScaffold(
      title: 'Biblioteca de Psicoeducação',
      accent: AppColors.purple,
      subtitle: staffView
          ? 'Os módulos que os pacientes veem'
          : 'Uma jornada para entender e transformar seus padrões',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(
          message: _message(e),
          onRetry: () => ref.invalidate(psychoeducationJourneyProvider),
        ),
        data: (modules) => modules.isEmpty
            ? _Empty(staffView: staffView)
            : _Journey(
                modules: modules,
                moduleRouteBuilder: moduleRouteBuilder,
                staffView: staffView,
              ),
      ),
    );
  }
}

class _Journey extends StatelessWidget {
  const _Journey({
    required this.modules,
    required this.moduleRouteBuilder,
    required this.staffView,
  });
  final List<PsychoeducationModule> modules;
  final String Function(String moduleId) moduleRouteBuilder;
  final bool staffView;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
        children: [
          AppPageHeader(
            icon: Icons.auto_stories_outlined,
            title: staffView ? 'Biblioteca de Psicoeducação' : 'Sua jornada',
            subtitle: staffView
                ? 'Referência dos módulos liberados aos pacientes. Toque para '
                    'revisar o conteúdo.'
                : 'Percorra os módulos no seu ritmo. Cada um traz cards para ler, '
                    'refletir e praticar.',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final stage in PsychoeducationStage.values)
            _StageSection(
              stage: stage,
              moduleRouteBuilder: moduleRouteBuilder,
              modules: modules.where((m) => m.stage == stage.label).toList()
                ..sort((a, b) => a.number.compareTo(b.number)),
            ),
        ],
      ),
    );
  }
}

class _StageSection extends StatelessWidget {
  const _StageSection({
    required this.stage,
    required this.modules,
    required this.moduleRouteBuilder,
  });
  final PsychoeducationStage stage;
  final List<PsychoeducationModule> modules;
  final String Function(String moduleId) moduleRouteBuilder;

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 2),
          child: Text(stage.label,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.navy)),
        ),
        Text(stage.subtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.sm),
        for (final m in modules) ...[
          _ModuleCard(module: m, moduleRouteBuilder: moduleRouteBuilder),
          const SizedBox(height: AppSpacing.sm),
        ],
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.moduleRouteBuilder});
  final PsychoeducationModule module;
  final String Function(String moduleId) moduleRouteBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = module.color;
    return ClayCard(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(moduleRouteBuilder(module.id)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.72)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('${module.number}',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.title,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (module.presentation != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        module.presentation!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                    if (module.cards.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                          '${module.cards.length} '
                          '${module.cards.length == 1 ? 'card' : 'cards'}',
                          style: theme.textTheme.labelSmall?.copyWith(
                              color: color, fontWeight: FontWeight.w700)),
                    ],
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

class _Empty extends StatelessWidget {
  const _Empty({required this.staffView});
  final bool staffView;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.auto_stories_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
                staffView
                    ? 'Nenhum módulo publicado ainda'
                    : 'Sua Biblioteca está a caminho',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              staffView
                  ? 'Os módulos aparecem aqui assim que o admin publicá-los.'
                  : 'Os módulos de psicoeducação aparecem aqui assim que forem '
                      'liberados.',
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
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
