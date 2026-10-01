import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../domain/exercise_definitions_data.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';
import '../../../shared/widgets/brand_loading.dart';
import 'psychoeducation_exercise_page.dart';

// Duração padrão das transições de página.
const _kPageDuration = Duration(milliseconds: 320);
const _kPageCurve = Curves.easeInOutCubic;

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
  bool _preloaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Precarrega todas as imagens do módulo em background assim que o widget
  // recebe os dados — reduz o tempo de espera ao navegar pelos cards.
  void _preloadImages(PsychoeducationModule module) {
    if (_preloaded) return;
    _preloaded = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final urls = <String>[
        if (module.coverUrl != null) module.coverUrl!,
        for (final c in module.cards)
          if (c.imageUrl != null) c.imageUrl!,
      ];
      for (final url in urls) {
        precacheImage(CachedNetworkImageProvider(url), context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(psychoeducationJourneyProvider);
    final module = async.valueOrNull
        ?.where((m) => m.id == widget.moduleId)
        .cast<PsychoeducationModule?>()
        .firstOrNull;

    if (async.isLoading) {
      return const Scaffold(body: BrandLoader());
    }
    if (module == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Módulo não encontrado.')),
      );
    }

    _preloadImages(module);

    final color = module.color;
    final theme = Theme.of(context);

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        title: Text(module.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: Column(
        children: [
          _ProgressBar(value: (_page + 1) / total, color: color),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: total,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    double offset = 0;
                    if (_controller.position.haveDimensions) {
                      offset = (_controller.page! - index).abs().clamp(0.0, 1.0);
                    }
                    final scale = 1.0 - offset * 0.06;
                    final opacity = 1.0 - offset * 0.35;
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(opacity: opacity, child: child),
                    );
                  },
                  child: pages[index],
                );
              },
            ),
          ),
          _BottomBar(
            page: _page,
            total: total,
            color: color,
            hasExercise: kExerciseDefinitions.containsKey(module.number),
            onBack: _page == 0
                ? null
                : () => _controller.previousPage(
                      duration: _kPageDuration,
                      curve: _kPageCurve,
                    ),
            onNext: _page == total - 1
                ? () => Navigator.of(context).maybePop()
                : () => _controller.nextPage(
                      duration: _kPageDuration,
                      curve: _kPageCurve,
                    ),
            onExercise: _page == total - 1
                ? () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) =>
                          PsychoeducationExercisePage(module: module),
                    ))
                : null,
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
    final coverUrl = module.coverUrl;
    if (coverUrl != null) {
      return _ImageCard(
        imageUrl: coverUrl,
        label: module.stage,
        title: module.title,
        color: module.color,
      );
    }
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
                  fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          if (module.presentation != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(module.presentation!,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
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
    if (card.imageUrl != null) {
      return _ImageCard(
        imageUrl: card.imageUrl!,
        label: 'Card ${index + 1} de $total',
        title: card.title,
        color: color,
      );
    }
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
                  fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface)),
          if (card.patientText != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(card.patientText!,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
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

class _ImageCard extends StatelessWidget {
  const _ImageCard({
    required this.imageUrl,
    this.label,
    this.title,
    this.color,
  });
  final String imageUrl;
  final String? label;
  final String? title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.purple;

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo embaçado — mesma imagem com blur para preencher as barras
          // laterais/superiores sem cortar o conteúdo.
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => Container(color: accent.withValues(alpha: 0.08)),
            errorWidget: (_, __, ___) => const SizedBox.shrink(),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          // Imagem principal em contain — nunca corta o conteúdo
          CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            placeholder: (_, __) => _ImagePlaceholder(color: accent),
            errorWidget: (_, __, ___) => _ImageError(color: accent),
          ),
          // Dica de zoom
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.zoom_in, size: 12, color: Colors.white),
                  SizedBox(width: 3),
                  Text(
                    'Pinça para ampliar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.08),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Carregando imagem…',
              style: TextStyle(
                color: color.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color.withValues(alpha: 0.06),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 40, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'Imagem indisponível',
              style: TextStyle(
                color: color.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
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
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
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
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// Indicador de progresso adaptativo:
// • até 10 páginas → bolinhas clássicas
// • mais de 10     → "3 / 13" em texto compacto
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({
    required this.page,
    required this.total,
    required this.color,
  });
  final int page;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (total <= 10) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: i == page ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i == page ? color : color.withValues(alpha: 0.25),
              ),
            ),
        ],
      );
    }
    // Fallback texto para módulos longos
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${page + 1} / $total',
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
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
    required this.hasExercise,
    this.onExercise,
  });
  final int page;
  final int total;
  final Color color;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final bool isLast;
  final bool hasExercise;
  final VoidCallback? onExercise;

  @override
  Widget build(BuildContext context) {
    final showExerciseButton = isLast && hasExercise;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showExerciseButton) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onExercise,
                  icon: const Icon(Icons.edit_note),
                  label: const Text('Fazer exercício'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Row(
              children: [
                TextButton(
                  onPressed: onBack,
                  child: const Text('Voltar'),
                ),
                const Spacer(),
                _PageIndicator(page: page, total: total, color: color),
                const Spacer(),
                if (!showExerciseButton)
                  FilledButton(
                    onPressed: onNext,
                    style: FilledButton.styleFrom(backgroundColor: color),
                    child: Text(isLast ? 'Concluir' : 'Avançar'),
                  )
                else
                  TextButton(
                    onPressed: onNext,
                    child: const Text('Concluir'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
