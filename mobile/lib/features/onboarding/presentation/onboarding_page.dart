import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/brand_constellation.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../providers/onboarding_providers.dart';

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.icon,
    required this.stepIcons,
    required this.accent,
    required this.title,
    required this.description,
  });

  final IconData icon;

  /// Ícones de apoio da composição — significado varia por slide/variante.
  final List<IconData> stepIcons;
  final Color accent;
  final String title;
  final String description;
}

const _slides = <_OnboardingSlide>[
  _OnboardingSlide(
    icon: Icons.spa_outlined,
    stepIcons: [],
    accent: AppColors.turquoise,
    title: 'Bem-vindo ao EsquemaCore',
    description:
        'Um espaço cuidadoso para acompanhar seu processo terapêutico, '
        'com clareza e no seu ritmo.',
  ),
  _OnboardingSlide(
    icon: Icons.route_outlined,
    stepIcons: [Icons.flag_outlined, Icons.check_circle_outline],
    accent: AppColors.purple,
    title: 'Sua jornada, passo a passo',
    description:
        'Uma trilha terapêutica organizada reúne questionários, monitor '
        'diário e recursos no lugar certo.',
  ),
  _OnboardingSlide(
    icon: Icons.fact_check_outlined,
    stepIcons: [Icons.tune, Icons.lightbulb_outline],
    accent: AppColors.blue,
    title: 'Questionários que fazem sentido',
    description:
        'Instrumentos clínicos apresentados de forma simples e acolhedora, '
        'uma pergunta de cada vez.',
  ),
  _OnboardingSlide(
    icon: Icons.insights_outlined,
    stepIcons: [Icons.timeline_outlined, Icons.auto_graph_outlined],
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

class _OnboardingPageState extends ConsumerState<OnboardingPage>
    with SingleTickerProviderStateMixin {
  final _controller = PageController();
  double _page = 0;
  int _index = 0;

  /// Flutuação ambiente compartilhada por todos os artworks (±6px, 3.8s).
  late final AnimationController _float;

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
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _float.dispose();
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
                      variant: i,
                      parallax: delta,
                      float: _float,
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
    required this.variant,
    required this.parallax,
    required this.float,
  });

  final _OnboardingSlide slide;

  /// Índice do slide (0..3) — escolhe qual composição visual é usada.
  final int variant;

  /// Distância da página atual (-1..1). 0 = centralizada.
  final double parallax;

  /// Controller de flutuação ambiente compartilhado (±6px, 3.8s).
  final AnimationController float;

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
              child: animate
                  ? AnimatedBuilder(
                      animation: float,
                      builder: (context, child) {
                        final dy = (float.value - 0.5) * 12; // ±6px
                        return Transform.translate(
                          offset: Offset(0, dy),
                          child: child,
                        );
                      },
                      child: _SlideArtwork(slide: slide, variant: variant),
                    )
                  : _SlideArtwork(slide: slide, variant: variant),
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

/// Composição visual de cada slide. As 4 são deliberadamente distintas —
/// nenhuma reaproveita o "círculo + ícone + satélites" das demais.
class _SlideArtwork extends StatelessWidget {
  const _SlideArtwork({required this.slide, required this.variant});

  final _OnboardingSlide slide;
  final int variant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 232,
      height: 232,
      child: switch (variant) {
        0 => _CoreOrbitArtwork(slide: slide),
        1 => _StepPathArtwork(slide: slide),
        2 => _CardsToInsightArtwork(slide: slide),
        _ => _AscendingArrivalArtwork(slide: slide),
      },
    );
  }
}

/// Slide 1 — "marca + órbita": núcleo com gradiente e uma constelação
/// orbitando ao redor, ecoando a splash.
class _CoreOrbitArtwork extends StatelessWidget {
  const _CoreOrbitArtwork({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final accent = slide.accent;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.06),
          ),
        ),
        BrandConstellation(
          size: const Size(200, 200),
          color: accent,
          opacity: 0.24,
          preset: BrandConstellationPreset.orbit,
        ),
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
      ],
    );
  }
}

/// Slide 2 — "caminho de etapas": constelação em caminho ascendente com
/// marcos (flag → check) ao longo da trilha.
class _StepPathArtwork extends StatelessWidget {
  const _StepPathArtwork({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final accent = slide.accent;
    return Stack(
      children: [
        Positioned.fill(
          child: BrandConstellation(
            size: const Size(232, 232),
            color: accent,
            opacity: 0.20,
            preset: BrandConstellationPreset.path,
          ),
        ),
        Positioned(
          left: 4,
          bottom: 22,
          child: _Milestone(icon: Icons.route_outlined, accent: accent),
        ),
        if (slide.stepIcons.isNotEmpty)
          Positioned(
            left: 96,
            bottom: 92,
            child: _Milestone(icon: slide.stepIcons[0], accent: accent),
          ),
        Positioned(
          right: 4,
          top: 10,
          child: _Milestone(
            icon: slide.stepIcons.length > 1
                ? slide.stepIcons[1]
                : Icons.check_circle_outline,
            accent: accent,
            filled: true,
          ),
        ),
      ],
    );
  }
}

/// Slide 3 — "cartões → núcleo de insight": três cartões convergindo para
/// um núcleo central, representando instrumentos formando uma leitura clínica.
class _CardsToInsightArtwork extends StatelessWidget {
  const _CardsToInsightArtwork({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final accent = slide.accent;
    return Stack(
      alignment: Alignment.center,
      children: [
        _InsightCard(
          icon: slide.icon,
          accent: accent,
          offset: const Offset(-72, -58),
          angle: -0.16,
        ),
        if (slide.stepIcons.isNotEmpty)
          _InsightCard(
            icon: slide.stepIcons[0],
            accent: accent,
            offset: const Offset(74, -50),
            angle: 0.14,
          ),
        if (slide.stepIcons.length > 1)
          _InsightCard(
            icon: slide.stepIcons[1],
            accent: accent,
            offset: const Offset(0, 66),
            angle: -0.05,
          ),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.75)],
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.center_focus_strong_outlined,
            size: 34,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.icon,
    required this.accent,
    required this.offset,
    required this.angle,
  });

  final IconData icon;
  final Color accent;
  final Offset offset;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: 24, color: accent),
        ),
      ),
    );
  }
}

/// Slide 4 — "linha ascendente com halo de chegada": trajetória de
/// evolução subindo até um halo pulsante que marca o ponto de chegada.
class _AscendingArrivalArtwork extends StatelessWidget {
  const _AscendingArrivalArtwork({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final accent = slide.accent;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(220, 200),
          painter: _AscendingLinePainter(color: accent),
        ),
        Positioned(
          left: 8,
          bottom: 30,
          child: Icon(
            slide.stepIcons.isNotEmpty
                ? slide.stepIcons[0]
                : Icons.timeline_outlined,
            size: 22,
            color: accent.withValues(alpha: 0.55),
          ),
        ),
        Positioned(
          right: 14,
          top: 14,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.8)],
                  ),
                ),
                child: Icon(slide.icon, size: 20, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AscendingLinePainter extends CustomPainter {
  const _AscendingLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.06, size.height * 0.82)
      ..cubicTo(
        size.width * 0.32,
        size.height * 0.86,
        size.width * 0.40,
        size.height * 0.52,
        size.width * 0.62,
        size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.42,
        size.width * 0.78,
        size.height * 0.20,
        size.width * 0.92,
        size.height * 0.10,
      );

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    for (final t in [0.0, 0.35, 0.65, 1.0]) {
      final metric = path.computeMetrics().first;
      final pos = metric.getTangentForOffset(metric.length * t)?.position;
      if (pos != null) canvas.drawCircle(pos, 2.6, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_AscendingLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Milestone extends StatelessWidget {
  const _Milestone({
    required this.icon,
    required this.accent,
    this.filled = false,
  });

  final IconData icon;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? accent : AppColors.surface,
        border:
            filled ? null : Border.all(color: accent.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: (filled ? accent : AppColors.navy)
                .withValues(alpha: filled ? 0.32 : 0.06),
            blurRadius: filled ? 20 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: 22, color: filled ? Colors.white : accent),
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
