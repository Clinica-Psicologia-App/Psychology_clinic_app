import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../providers/onboarding_providers.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.satellites,
    required this.accent,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final List<IconData> satellites;
  final Color accent;
  final String title;
  final String description;
}

const _slides = <_OnboardingSlide>[
  _OnboardingSlide(
    icon: Icons.spa_outlined,
    satellites: [Icons.favorite_border, Icons.psychology_alt_outlined],
    accent: AppColors.turquoise,
    title: 'Bem-vindo ao EsquemaCore',
    description:
        'Um espaço cuidadoso para acompanhar seu processo terapêutico, '
        'com clareza e no seu ritmo.',
  ),
  _OnboardingSlide(
    icon: Icons.route_outlined,
    satellites: [Icons.flag_outlined, Icons.check_circle_outline],
    accent: AppColors.purple,
    title: 'Sua jornada, passo a passo',
    description:
        'Uma trilha terapêutica organizada reúne questionários, monitor '
        'diário e recursos no lugar certo.',
  ),
  _OnboardingSlide(
    icon: Icons.fact_check_outlined,
    satellites: [Icons.tune, Icons.lightbulb_outline],
    accent: AppColors.blue,
    title: 'Questionários que fazem sentido',
    description:
        'Instrumentos clínicos apresentados de forma simples e acolhedora, '
        'uma pergunta de cada vez.',
  ),
  _OnboardingSlide(
    icon: Icons.insights_outlined,
    satellites: [Icons.timeline_outlined, Icons.auto_graph_outlined],
    accent: AppColors.cyan,
    title: 'Acompanhe sua evolução',
    description:
        'Visualize resultados e mudanças ao longo do tempo, sempre como '
        'apoio ao trabalho com seu psicólogo.',
  ),
];

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _controller = PageController();
  double _page = 0;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final p = _controller.page ?? 0;
      setState(() {
        _page = p;
        _index = p.round();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLast => _index >= _slides.length - 1;

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_isLast) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppAnimations.standard,
      curve: AppAnimations.standardCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration:
            const BoxDecoration(gradient: AppGradients.splashBackground),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      0, AppSpacing.sm, AppSpacing.sm, 0),
                  child: AnimatedOpacity(
                    duration: AppAnimations.standard,
                    opacity: _isLast ? 0 : 1,
                    child: TextButton(
                      onPressed: _isLast ? null : _finish,
                      child: const Text('Pular'),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  itemBuilder: (context, i) {
                    final delta = _page - i;
                    return _OnboardingSlideView(
                      slide: _slides[i],
                      parallax: delta,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    _DotsIndicator(count: _slides.length, page: _page),
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        child: AnimatedSwitcher(
                          duration: AppAnimations.fast,
                          child: Text(
                            _isLast ? 'Começar' : 'Continuar',
                            key: ValueKey(_isLast),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Opacity(
                      opacity: 0.7,
                      child: EsquemaCoreLogo.horizontal(
                        size: 22,
                        showName: true,
                        nameColor: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlideView extends StatelessWidget {
  const _OnboardingSlideView({
    required this.slide,
    required this.parallax,
  });

  final _OnboardingSlide slide;

  /// Distância da página atual (-1..1). 0 = centralizada.
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final animate = AppAnimations.shouldAnimate(context);
    final shift = animate ? parallax : 0.0;
    final clamped = shift.clamp(-1.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(-clamped * 48, 0),
            child: Opacity(
              opacity: (1 - clamped.abs() * 0.6).clamp(0.0, 1.0),
              child: _SlideArtwork(slide: slide),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Transform.translate(
            offset: Offset(-clamped * 24, 0),
            child: Column(
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  slide.description,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideArtwork extends StatelessWidget {
  const _SlideArtwork({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final accent = slide.accent;

    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo externo
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.06),
            ),
          ),
          Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
          // Núcleo com gradiente de marca
          Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent, accent.withValues(alpha: 0.78)],
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(slide.icon, size: 52, color: Colors.white),
          ),
          // Ícones satélites
          for (var i = 0; i < slide.satellites.length; i++)
            _Satellite(
              icon: slide.satellites[i],
              accent: accent,
              angle: i == 0 ? -0.7 : 2.3,
              radius: 96,
            ),
        ],
      ),
    );
  }
}

class _Satellite extends StatelessWidget {
  const _Satellite({
    required this.icon,
    required this.accent,
    required this.angle,
    required this.radius,
  });

  final IconData icon;
  final Color accent;
  final double angle;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dx = math.cos(angle) * radius;
    final dy = math.sin(angle) * radius;
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: accent),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.page});

  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          _Dot(proximity: (1 - (page - i).abs()).clamp(0.0, 1.0)),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.proximity});

  /// 1 = página atual, 0 = distante.
  final double proximity;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8 + proximity * 18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Color.lerp(
          AppColors.border,
          AppColors.turquoise,
          proximity,
        ),
      ),
    );
  }
}
