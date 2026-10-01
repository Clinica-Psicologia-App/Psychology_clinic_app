import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

class PsychoeducationJourneyPage extends ConsumerWidget {
  const PsychoeducationJourneyPage({
    super.key,
    required this.moduleRouteBuilder,
    this.staffView = false,
  });

  final String Function(String moduleId) moduleRouteBuilder;
  final bool staffView;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(psychoeducationJourneyProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          _CanopyHeader(staffView: staffView),
          Expanded(
            child: async.when(
              loading: () => const BrandLoader(),
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
          ),
        ],
      ),
    );
  }
}

// ── Canopy header full-bleed ──────────────────────────────────────────────────

class _CanopyHeader extends StatelessWidget {
  const _CanopyHeader({required this.staffView});
  final bool staffView;

  static const _top = Color(0xFF4C1D95);
  static const _mid = Color(0xFF7C3AED);
  static const _bot = Color(0xFF1E3A5F);

  static const _spines = [
    (w: 12.0, h: 26.0, c: Color(0xFF14B8A6)),
    (w: 9.0, h: 21.0, c: Color(0xFF0891B2)),
    (w: 14.0, h: 30.0, c: Color(0xFF6366F1)),
    (w: 10.0, h: 20.0, c: Color(0xFF7C3AED)),
    (w: 12.0, h: 24.0, c: Color(0xFF059669)),
    (w: 8.0, h: 18.0, c: Color(0xFFD97706)),
    (w: 13.0, h: 28.0, c: Color(0xFF14B8A6)),
    (w: 10.0, h: 22.0, c: Color(0xFF6366F1)),
    (w: 11.0, h: 20.0, c: Color(0xFF7C3AED)),
    (w: 14.0, h: 30.0, c: Color(0xFF059669)),
    (w: 9.0, h: 22.0, c: Color(0xFF0891B2)),
    (w: 12.0, h: 25.0, c: Color(0xFFD97706)),
    (w: 10.0, h: 26.0, c: Color(0xFF14B8A6)),
    (w: 13.0, h: 20.0, c: Color(0xFF6366F1)),
    (w: 11.0, h: 24.0, c: Color(0xFF7C3AED)),
    (w: 8.0, h: 18.0, c: Color(0xFF059669)),
    (w: 14.0, h: 28.0, c: Color(0xFF0891B2)),
    (w: 10.0, h: 22.0, c: Color(0xFFD97706)),
    (w: 12.0, h: 25.0, c: Color(0xFF14B8A6)),
    (w: 9.0, h: 21.0, c: Color(0xFF6366F1)),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_top, _mid, _bot],
          stops: [0.0, 0.45, 1.0],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x47283593),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        child: Stack(
          children: [
            // Watermark
            Positioned(
              right: -8,
              top: topInset,
              bottom: 0,
              child: Icon(
                Icons.local_library,
                size: 116,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
            // Prateleira de lombadas decorativa
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 34,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: _spines
                      .map((s) => Container(
                            width: s.w,
                            height: s.h,
                            margin: const EdgeInsets.only(right: 2),
                            decoration: BoxDecoration(
                              color: s.c.withValues(alpha: 0.18),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(2),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            // Conteúdo
            Padding(
              padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_back,
                              size: 16, color: Colors.white),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'BIBLIOTECA',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    staffView
                        ? 'Biblioteca de\nPsicoeducação'
                        : 'Sua Jornada de\nAutoconhecimento',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    staffView
                        ? 'Módulos publicados para os pacientes'
                        : '19 módulos organizados para guiar sua transformação',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _StatBadge(
                        icon: Icons.menu_book_outlined,
                        label: '19 módulos',
                        color: Colors.white,
                        bgColor: Colors.white.withValues(alpha: 0.18),
                      ),
                      const SizedBox(width: 8),
                      _StatBadge(
                        icon: Icons.layers_outlined,
                        label: '4 etapas',
                        color: Colors.white,
                        bgColor: Colors.white.withValues(alpha: 0.18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Jornada ──────────────────────────────────────────────────────────────────

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
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: [
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

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.label,
    required this.color,
    this.bgColor,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color? bgColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Seção por etapa ───────────────────────────────────────────────────────────

class _StageSection extends StatelessWidget {
  const _StageSection({
    required this.stage,
    required this.modules,
    required this.moduleRouteBuilder,
  });
  final PsychoeducationStage stage;
  final List<PsychoeducationModule> modules;
  final String Function(String moduleId) moduleRouteBuilder;

  static const _stageIcons = {
    'Conhecer': Icons.search_outlined,
    'Compreender': Icons.psychology_outlined,
    'Transformar': Icons.auto_fix_high,
    'Praticar': Icons.emoji_events_outlined,
  };

  static const _stageColors = {
    'Conhecer': Color(0xFF14B8A6),
    'Compreender': Color(0xFF6366F1),
    'Transformar': Color(0xFF059669),
    'Praticar': Color(0xFFD97706),
  };

  @override
  Widget build(BuildContext context) {
    if (modules.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final color = _stageColors[stage.label] ?? AppColors.purple;
    final icon = _stageIcons[stage.label] ?? Icons.book_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho da seção — estilo prateleira de biblioteca
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    stage.subtitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${modules.length}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Linha decorativa de prateleira
        Container(
          height: 2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.5), color.withValues(alpha: 0.0)],
            ),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Grade de livros
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.70,
          children: modules
              .map((m) => _BookCard(
                    module: m,
                    moduleRouteBuilder: moduleRouteBuilder,
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ── Card no formato capa de livro ─────────────────────────────────────────────

class _BookCard extends StatelessWidget {
  const _BookCard({required this.module, required this.moduleRouteBuilder});
  final PsychoeducationModule module;
  final String Function(String moduleId) moduleRouteBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = module.color;
    final light = color.withValues(alpha: 0.75);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(moduleRouteBuilder(module.id)),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Capa colorida (parte superior) ──────────────────────────
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, light],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Padrão decorativo (linhas de livro)
                      Positioned(
                        right: -10,
                        top: -10,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${module.number}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      // Ícone central
                      Center(
                        child: Icon(
                          Icons.menu_book_outlined,
                          size: 36,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Informações (parte inferior) ─────────────────────────────
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      if (module.cards.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.layers_outlined,
                                size: 10, color: color),
                            const SizedBox(width: 3),
                            Text(
                              '${module.cards.length} cards',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                    ],
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

// ── Estados vazios / erro ─────────────────────────────────────────────────────

class _Empty extends StatelessWidget {
  const _Empty({required this.staffView});
  final bool staffView;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.local_library_outlined,
              size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
              staffView
                  ? 'Nenhum módulo publicado ainda'
                  : 'Sua Biblioteca está a caminho',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            staffView
                ? 'Os módulos aparecem aqui assim que o admin publicá-los.'
                : 'Os módulos de psicoeducação aparecem aqui assim que forem liberados.',
            textAlign: TextAlign.center,
          ),
        ]),
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

String _message(Object error) =>
    error.toString().replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');
