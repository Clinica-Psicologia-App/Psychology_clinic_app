import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/brand_constellation.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _breathe;

  /// Deriva rotacional quase imperceptível da constelação orbital do mark —
  /// uma volta completa a cada 48s, sem reverter.
  late final AnimationController _drift;

  late final Animation<double> _markScale;
  late final Animation<double> _markFade;
  late final Animation<double> _glow;
  late final Animation<double> _taglineFade;
  late final Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 48000),
    )..repeat();

    _markScale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _markFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _glow = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.08, 0.62, curve: Curves.easeOutCubic),
    );
    _taglineFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.46, 0.82, curve: Curves.easeOut),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _intro,
        curve: const Interval(0.46, 0.82, curve: Curves.easeOutCubic),
      ),
    );

    _intro.forward();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
  }

  @override
  void dispose() {
    _intro.dispose();
    _breathe.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final animate = AppAnimations.shouldAnimate(context);

    return Scaffold(
      body: DecoratedBox(
        decoration:
            const BoxDecoration(gradient: AppGradients.splashBackground),
        child: SafeArea(
          child: Stack(
            children: [
              if (animate) ..._buildAmbientConstellations(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  child: authState.when(
                    loading: () => _SplashContent(
                      intro: _intro,
                      breathe: _breathe,
                      drift: _drift,
                      markScale: _markScale,
                      markFade: _markFade,
                      glow: _glow,
                      taglineFade: _taglineFade,
                      taglineSlide: _taglineSlide,
                      animate: animate,
                    ),
                    data: (_) => _SplashContent(
                      intro: _intro,
                      breathe: _breathe,
                      drift: _drift,
                      markScale: _markScale,
                      markFade: _markFade,
                      glow: _glow,
                      taglineFade: _taglineFade,
                      taglineSlide: _taglineSlide,
                      animate: animate,
                    ),
                    error: (e, _) => _ErrorContent(
                      message: e is AppException
                          ? userMessageFor(e)
                          : 'Não foi possível restaurar a sessão.',
                      onRetry: _bootstrap,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Constelações discretas nos cantos, reveladas junto da entrada — presença
  /// ambiental que ecoa a marca sem competir com o conteúdo central.
  List<Widget> _buildAmbientConstellations() {
    return [
      Positioned(
        top: -30,
        left: -20,
        child: FadeTransition(
          opacity: _taglineFade,
          child: BrandConstellation(
            size: const Size(160, 160),
            color: AppColors.cyan,
            opacity: 0.10,
            preset: BrandConstellationPreset.scatter,
          ),
        ),
      ),
      Positioned(
        bottom: -40,
        right: -24,
        child: FadeTransition(
          opacity: _taglineFade,
          child: BrandConstellation(
            size: const Size(180, 180),
            color: AppColors.purple,
            opacity: 0.10,
            preset: BrandConstellationPreset.path,
          ),
        ),
      ),
    ];
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.intro,
    required this.breathe,
    required this.drift,
    required this.markScale,
    required this.markFade,
    required this.glow,
    required this.taglineFade,
    required this.taglineSlide,
    required this.animate,
  });

  final Animation<double> intro;
  final Animation<double> breathe;
  final Animation<double> drift;
  final Animation<double> markScale;
  final Animation<double> markFade;
  final Animation<double> glow;
  final Animation<double> taglineFade;
  final Animation<Offset> taglineSlide;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!animate) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _BrandMark(glow: 1, breathe: 0),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'EsquemaCore',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Seu raciocínio clínico em mapa',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          const _LoadingFooter(),
        ],
      );
    }

    return AnimatedBuilder(
      animation: Listenable.merge([intro, breathe, drift]),
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: markScale.value,
              child: Opacity(
                opacity: markFade.value.clamp(0.0, 1.0),
                child: _BrandMark(
                  glow: glow.value,
                  breathe: breathe.value,
                  drift: drift.value,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeTransition(
              opacity: taglineFade,
              child: SlideTransition(
                position: taglineSlide,
                child: Column(
                  children: [
                    Text(
                      'EsquemaCore',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Seu raciocínio clínico em mapa',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            FadeTransition(
              opacity: taglineFade,
              child: const _LoadingFooter(),
            ),
          ],
        );
      },
    );
  }
}

/// Marca com halos concêntricos animados (glow de entrada + respiração).
class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.glow,
    required this.breathe,
    this.drift = 0,
  });

  /// 0..1 — intensidade do halo de entrada.
  final double glow;

  /// 0..1 — ciclo de respiração contínua.
  final double breathe;

  /// 0..1 — ciclo de deriva rotacional (0 = estático).
  final double drift;

  @override
  Widget build(BuildContext context) {
    final pulse = 1 + breathe * 0.04;

    return SizedBox(
      width: 168,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _Halo(size: 168, opacity: glow * 0.10 * (0.7 + breathe * 0.3)),
          _Halo(size: 132, opacity: glow * 0.16),
          Transform.rotate(
            angle: drift * 2 * 3.14159265,
            child: BrandConstellation(
              size: const Size(150, 150),
              color: AppColors.turquoise,
              opacity: 0.16,
              progress: glow,
              preset: BrandConstellationPreset.orbit,
            ),
          ),
          Transform.scale(
            scale: pulse,
            child: const EsquemaCoreLogo(size: 96),
          ),
        ],
      ),
    );
  }
}

class _Halo extends StatelessWidget {
  const _Halo({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.turquoise.withValues(alpha: opacity.clamp(0.0, 1.0)),
      ),
    );
  }
}

class _LoadingFooter extends StatelessWidget {
  const _LoadingFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _PulsingDots(),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Preparando seu espaço...',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }
}

/// Três pontos pulsando em sequência (substitui o spinner por algo mais suave).
class _PulsingDots extends StatefulWidget {
  const _PulsingDots();

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.turquoise,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value - i * 0.18) % 1.0;
            final t = (1 - (phase * 2 - 1).abs()).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color.lerp(
                  AppColors.border,
                  AppColors.turquoise,
                  t,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const EsquemaCoreLogo(size: 96, showTagline: true),
        const SizedBox(height: AppSpacing.xxl),
        Icon(
          Icons.error_outline,
          size: 48,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: AppSpacing.xl),
        FilledButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}
