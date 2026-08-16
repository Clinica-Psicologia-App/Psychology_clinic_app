import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';

/// Leitor de um módulo de psicoeducação: apresentação → cards → fechamento,
/// numa jornada paginada.
class PsychoeducationModulePage extends ConsumerStatefulWidget {
  const PsychoeducationModulePage({super.key, required this.moduleId});

  final String moduleId;

  @override
  ConsumerState<PsychoeducationModulePage> createState() =>
      _PsychoeducationModulePageState();
}

class _PsychoeducationModulePageState
    extends ConsumerState<PsychoeducationModulePage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(psychoeducationJourneyProvider);
    final module = async.valueOrNull
        ?.where((m) => m.id == widget.moduleId)
        .cast<PsychoeducationModule?>()
        .firstOrNull;

    if (async.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (module == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Módulo não encontrado.')),
      );
    }

    final color = module.color;
    // Páginas: apresentação + cards + (fechamento, se houver).
    final pages = <Widget>[
      _IntroPage(module: module),
      for (var i = 0; i < module.cards.length; i++)
        _CardPage(
          card: module.cards[i],
          index: i,
          total: module.cards.length,
          color: color,
        ),
      if (module.closing != null)
        _ClosingPage(text: module.closing!, color: color),
    ];
    final total = pages.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.navy,
        elevation: 0,
        title: Text(module.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: Column(
        children: [
          _ProgressBar(value: (_page + 1) / total, color: color),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: pages,
            ),
          ),
          _BottomBar(
            page: _page,
            total: total,
            color: color,
            onBack: _page == 0
                ? null
                : () => _controller.previousPage(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                    ),
            onNext: _page == total - 1
                ? () => Navigator.of(context).maybePop()
                : () => _controller.nextPage(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                    ),
            isLast: _page == total - 1,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 4,
        backgroundColor: color.withValues(alpha: 0.12),
        valueColor: AlwaysStoppedAnimation(color),
      );
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.module});
  final PsychoeducationModule module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = module.color;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text('${module.number}',
                style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(module.stage.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: color, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(module.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.navy)),
          if (module.presentation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(module.presentation!,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _CardPage extends StatelessWidget {
  const _CardPage({
    required this.card,
    required this.index,
    required this.total,
    required this.color,
  });
  final PsychoeducationCard card;
  final int index;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          Text('Card ${index + 1} de $total',
              style: theme.textTheme.labelSmall?.copyWith(
                  color: color, fontWeight: FontWeight.w800, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(card.title,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: AppColors.navy)),
          if (card.patientText != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(card.patientText!,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5)),
          ],
          if (card.reflection != null)
            _Box(
              icon: Icons.self_improvement,
              label: 'Reflexão',
              text: card.reflection!,
              color: color,
            ),
          if (card.exercise != null)
            _Box(
              icon: Icons.edit_note,
              label: 'Exercício',
              text: card.exercise!,
              color: AppColors.turquoise,
            ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({
    required this.icon,
    required this.label,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: color, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 6),
          Text(text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.45)),
        ],
      ),
    );
  }
}

class _ClosingPage extends StatelessWidget {
  const _ClosingPage({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite, color: color, size: 40),
            const SizedBox(height: AppSpacing.lg),
            Text(text,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.page,
    required this.total,
    required this.color,
    required this.onBack,
    required this.onNext,
    required this.isLast,
  });
  final int page;
  final int total;
  final Color color;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
        child: Row(
          children: [
            TextButton(
              onPressed: onBack,
              child: const Text('Voltar'),
            ),
            const Spacer(),
            Row(
              children: [
                for (var i = 0; i < total; i++)
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == page ? color : color.withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(isLast ? 'Concluir' : 'Avançar'),
            ),
          ],
        ),
      ),
    );
  }
}
