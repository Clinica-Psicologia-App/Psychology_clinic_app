import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_branding_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/error_banner.dart' show showErrorBanner;
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/app_motion.dart';
import '../data/login_prefs_store.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  static const _prefsStore = LoginPrefsStore();
  late final AnimationController _ambientController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
    _restoreLastEmail();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final msg = ref.read(authRedirectMessageProvider);
      if (msg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        ref.read(authControllerProvider.notifier).clearRedirectMessage();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // O controller ambiente só roda quando o sistema permite animações.
    if (AppAnimations.shouldAnimate(context)) {
      if (!_ambientController.isAnimating) _ambientController.repeat();
    } else {
      _ambientController.stop();
    }
  }

  Future<void> _restoreLastEmail() async {
    final email = await _prefsStore.lastEmail();
    if (email != null && mounted && _emailController.text.isEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final notifier = ref.read(authControllerProvider.notifier);
    await notifier.signIn(
      email,
      _passwordController.text,
    );

    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      showErrorBanner(context, state.error!);
      return;
    }

    // Login ok: informa o autofill do sistema e lembra o e-mail.
    TextInput.finishAutofillContext();
    await _prefsStore.saveLastEmail(email);
  }

  void _fillSeed(String email) {
    _emailController.text = email;
    _passwordController.text = 'TesteMVP2025!';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final redirectMsg = ref.watch(authRedirectMessageProvider);
    final isLoading = authState.isLoading;
    final isWide = AppBreakpoints.fromContext(context) != AppLayoutSize.compact;

    // O feedback de loading fica no próprio botão (spinner + "Entrando...")
    // com os campos desabilitados — sem overlay cobrindo a tela.
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _AnimatedLoginBackdrop(
        controller: _ambientController,
        child: SafeArea(
          child: isWide
              ? _buildSplitLayout(redirectMsg, isLoading)
              : _buildMobileLayout(redirectMsg, isLoading),
        ),
      ),
    );
  }

  Widget _buildSplitLayout(String? redirectMsg, bool isLoading) {
    return SizedBox.expand(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 55,
            child: _LoginStoryPanel(controller: _ambientController),
          ),
          Expanded(
            flex: 45,
            child: _WebLoginPanel(
              formKey: _formKey,
              emailController: _emailController,
              passwordController: _passwordController,
              obscurePassword: _obscurePassword,
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              redirectMsg: redirectMsg,
              isLoading: isLoading,
              onSubmit: _submit,
              onForgotPassword: () => context.push(AppRoutes.forgotPassword),
              onFillSeed: _fillSeed,
              showTestAccounts: EnvConfig.showTestAccounts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(String? redirectMsg, bool isLoading) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            children: [
              MotionReveal(
                child: _MobileBrandHero(controller: _ambientController),
              ),
              const SizedBox(height: AppSpacing.lg),
              MotionReveal(
                delay: const Duration(milliseconds: 90),
                child: _LoginCard(
                  compact: true,
                  child: _LoginForm(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    obscurePassword: _obscurePassword,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    redirectMsg: redirectMsg,
                    isLoading: isLoading,
                    onSubmit: _submit,
                    onForgotPassword: () =>
                        context.push(AppRoutes.forgotPassword),
                    onFillSeed: _fillSeed,
                    showTestAccounts: EnvConfig.showTestAccounts,
                    showHeaderLogo: false,
                    showBrandHeader: false,
                    centerHeader: true,
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

class _MobileBrandHero extends StatelessWidget {
  const _MobileBrandHero({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFF4FBFF),
            Color(0xFFF6F3FF),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.72,
              child: _ClinicalSignalAnimation(controller: controller),
            ),
          ),
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Image.asset(
                  AppBrandingAssets.icon,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                  height: 1,
                                ),
                        children: const [
                          TextSpan(text: 'Esquema'),
                          TextSpan(
                            text: 'Core',
                            style: TextStyle(color: AppColors.cyan),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'seu raciocínio clínico em mapa',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoginBackdrop extends StatelessWidget {
  const _AnimatedLoginBackdrop({
    required this.controller,
    required this.child,
  });

  final Animation<double> controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return DecoratedBox(
        decoration:
            const BoxDecoration(gradient: AppGradients.splashBackground),
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _LoginBackdropPainter(controller.value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFFFFFF),
                  Color.lerp(
                    const Color(0xFFF0F9FF),
                    const Color(0xFFF7F3FF),
                    0.5 + math.sin(controller.value * math.pi * 2) * 0.18,
                  )!,
                  const Color(0xFFEFF6FF),
                ],
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }
}

class _LoginBackdropPainter extends CustomPainter {
  const _LoginBackdropPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.border.withValues(alpha: 0.55);
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = AppColors.cyan.withValues(alpha: 0.18);
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.purple.withValues(alpha: 0.14);

    for (var y = 36.0; y < size.height; y += 64) {
      final path = Path();
      final offset = math.sin(phase * math.pi * 2 + y * 0.018) * 14;
      path.moveTo(-40, y + offset);
      for (var x = -40.0; x <= size.width + 40; x += 80) {
        final controlY =
            y + math.sin(phase * math.pi * 2 + x * 0.012) * 18 + offset;
        path.quadraticBezierTo(x + 40, controlY, x + 80, y - offset * 0.35);
      }
      canvas.drawPath(path, y % 128 == 36 ? wavePaint : paint);
    }

    final clinicalPath = Path()
      ..moveTo(size.width * 0.08, size.height * 0.78)
      ..cubicTo(
        size.width * 0.25,
        size.height * (0.58 + phase * 0.02),
        size.width * 0.48,
        size.height * 0.92,
        size.width * 0.72,
        size.height * (0.68 - phase * 0.02),
      )
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.55,
        size.width * 0.92,
        size.height * 0.64,
        size.width * 1.04,
        size.height * 0.5,
      );
    canvas.drawPath(clinicalPath, accentPaint);
  }

  @override
  bool shouldRepaint(covariant _LoginBackdropPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

// ── Web story panel — redesenho completo ────────────────────────────────────
class _LoginStoryPanel extends StatelessWidget {
  const _LoginStoryPanel({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1A3F),
            Color(0xFF083868),
            Color(0xFF004D4B),
          ],
          stops: [0.0, 0.52, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x44083868),
            blurRadius: 28,
            offset: Offset(10, 0),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fundo: rede de nós
          _WebNodeNetworkAnimation(controller: controller),
          // Conteúdo
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topo: badge da marca
                const _WebMiniBrand(),
                // Centro: emblema com glow pulsante
                Expanded(
                  child: Center(
                    child: _WebGlowingEmblem(controller: controller),
                  ),
                ),
                // Eyebrow
                Text(
                  'FEITO PARA PSICÓLOGOS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.turquoise,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _WebFeatureCarousel(controller: controller),
                const SizedBox(height: AppSpacing.md),
                _WebFeatureDots(controller: controller),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Acesso clínico',
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.textOnBrand,
                    fontWeight: FontWeight.w700,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Entre para continuar seu trabalho com segurança.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.textOnBrand.withValues(alpha: 0.80),
                    height: 1.38,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const _TrustRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Badge compacto da marca (topo do painel esquerdo) ────────────────────────
class _WebMiniBrand extends StatelessWidget {
  const _WebMiniBrand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Image.asset(AppBrandingAssets.icon, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: 10),
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
            children: [
              TextSpan(
                text: 'Esquema',
                style: TextStyle(color: Colors.white),
              ),
              TextSpan(
                text: 'Core',
                style: TextStyle(color: AppColors.turquoise),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Emblema central com anéis pulsantes (efeito sonar) ───────────────────────
class _WebGlowingEmblem extends StatelessWidget {
  const _WebGlowingEmblem({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return _buildEmblem(0.5);
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => _buildEmblem(controller.value),
    );
  }

  // 3 anéis sonar defasados em 120° cada
  Widget _ring(double rawPhase, {required double maxR, required double baseR}) {
    final p = (rawPhase * 3.5) % 1.0; // ~3,5 ciclos por ciclo de 16 s
    final r = baseR + p * (maxR - baseR);
    final alpha = (1.0 - p).clamp(0.0, 1.0) * 0.40;
    return Container(
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.turquoise.withValues(alpha: alpha),
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildEmblem(double phase) {
    final pulse = 0.5 + math.sin(phase * math.pi * 2) * 0.5;
    final glowAlpha = 0.22 + pulse * 0.22;
    const base = 68.0;
    const maxR = 155.0;
    // Animated extrusion depth: card "rises" with the pulse
    final depth = (7 + pulse * 5).round();

    // Teal extrusion slices — dark back face → bright front face
    final extrusion = List.generate(depth, (i) {
      final t = i / depth;
      final c = Color.lerp(
        const Color(0xFF007570),
        const Color(0xFF003A37),
        t,
      )!;
      return BoxShadow(
        color: c,
        blurRadius: 0,
        offset: Offset(0, (i + 1).toDouble()),
      );
    });

    return SizedBox(
      width: 340,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sonar rings
          _ring(phase + 0.00, maxR: maxR, baseR: base),
          _ring(phase + 0.33, maxR: maxR, baseR: base),
          _ring(phase + 0.66, maxR: maxR, baseR: base),

          // Glow difuso atrás do card
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: glowAlpha),
                  blurRadius: 64,
                  spreadRadius: 14,
                ),
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: glowAlpha * 0.45),
                  blurRadius: 110,
                ),
              ],
            ),
          ),

          // Ground reflection — elipse escura embaixo do card
          Transform.translate(
            offset: const Offset(0, 88),
            child: Container(
              width: 140,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: RadialGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Card 3D com extrusão teal + highlight especular
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFDFF3F3)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.95),
                width: 1.5,
              ),
              boxShadow: [
                // Extrusão 3D (fatias sem blur)
                ...extrusion,
                // Drop shadow embaixo da extrusão
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 26,
                  offset: Offset(0, depth + 10.0),
                ),
                // Glow teal ao redor
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: glowAlpha * 1.1),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                children: [
                  // Highlight especular (canto superior esquerdo)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.center,
                          colors: [
                            Colors.white.withValues(alpha: 0.60),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Brain
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      AppBrandingAssets.icon,
                      fit: BoxFit.contain,
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

// ── Web-only: rede de nós genotípica ─────────────────────────────────────────
class _WebNodeNetworkAnimation extends StatelessWidget {
  const _WebNodeNetworkAnimation({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return const CustomPaint(painter: _NodeNetworkPainter(0));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(painter: _NodeNetworkPainter(controller.value)),
    );
  }
}

class _NodeNetworkPainter extends CustomPainter {
  const _NodeNetworkPainter(this.phase);

  final double phase;

  static const _nodes = [
    Offset(0.15, 0.18),
    Offset(0.42, 0.08),
    Offset(0.75, 0.22),
    Offset(0.88, 0.05),
    Offset(0.22, 0.48),
    Offset(0.58, 0.38),
    Offset(0.80, 0.55),
    Offset(0.10, 0.72),
    Offset(0.38, 0.82),
    Offset(0.65, 0.75),
    Offset(0.90, 0.85),
    Offset(0.50, 0.58),
  ];

  static const _edges = [
    [0, 1], [1, 2], [2, 3], [1, 4], [1, 5], [2, 5],
    [4, 7], [5, 6], [5, 11], [4, 11], [6, 10], [7, 8],
    [8, 9], [9, 10], [11, 9], [0, 4], [3, 6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final edge in _edges) {
      final a = _nodePos(edge[0], size);
      final b = _nodePos(edge[1], size);
      final pulseFactor = 0.5 + math.sin(phase * math.pi * 2 + edge[0] * 0.9) * 0.5;
      edgePaint.color = Colors.white.withValues(alpha: 0.05 + pulseFactor * 0.07);
      canvas.drawLine(a, b, edgePaint);
    }

    for (var i = 0; i < _nodes.length; i++) {
      final pos = _nodePos(i, size);
      final pulse = 0.5 + math.sin(phase * math.pi * 2 + i * 1.3) * 0.5;
      final radius = 3.0 + pulse * 2.5;
      // glow
      canvas.drawCircle(
        pos,
        radius + 6,
        Paint()..color = Colors.white.withValues(alpha: 0.03 + pulse * 0.04),
      );
      // core
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10 + pulse * 0.12)
          ..style = PaintingStyle.fill,
      );
    }
  }

  Offset _nodePos(int index, Size size) {
    final n = _nodes[index];
    final wobbleX = math.sin(phase * math.pi * 2 + index * 2.1) * 8;
    final wobbleY = math.cos(phase * math.pi * 2 + index * 1.7) * 6;
    return Offset(n.dx * size.width + wobbleX, n.dy * size.height + wobbleY);
  }

  @override
  bool shouldRepaint(covariant _NodeNetworkPainter old) => old.phase != phase;
}

// ── Web-only: carrossel de features ──────────────────────────────────────────
const _kWebFeatures = [
  (
    icon: Icons.psychology_outlined,
    title: 'Genograma clínico',
    body: 'Mapeie vínculos familiares e padrões transgeracionais com precisão.',
  ),
  (
    icon: Icons.assignment_outlined,
    title: 'Questionários validados',
    body: 'PHQ-9, GAD-7, Young, NEO PI-R e mais — integrados ao prontuário.',
  ),
  (
    icon: Icons.route_outlined,
    title: 'Jornada do paciente',
    body: 'Acompanhe evolução, metas e check-ins em linha do tempo unificada.',
  ),
  (
    icon: Icons.shield_outlined,
    title: 'Segurança clínica',
    body: 'Dados criptografados, acesso por convite e conformidade com CFP.',
  ),
];

class _WebFeatureCarousel extends StatelessWidget {
  const _WebFeatureCarousel({required this.controller});

  final Animation<double> controller;

  int _currentIndex(double v) => (v * _kWebFeatures.length).floor() % _kWebFeatures.length;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final idx = _currentIndex(controller.value);
        final f = _kWebFeatures[idx];
        // local fade progress dentro de cada slot
        final slotWidth = 1.0 / _kWebFeatures.length;
        final slotStart = idx * slotWidth;
        final progress = (controller.value - slotStart) / slotWidth;
        final fade = _feadeCurve(progress);

        return Opacity(
          opacity: fade,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                ),
                child: Icon(f.icon, color: AppColors.turquoise, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      f.body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _feadeCurve(double t) {
    if (t < 0.15) return t / 0.15;
    if (t > 0.82) return (1.0 - t) / 0.18;
    return 1.0;
  }
}

class _WebFeatureDots extends StatelessWidget {
  const _WebFeatureDots({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final active = (controller.value * _kWebFeatures.length).floor() % _kWebFeatures.length;
        return Row(
          children: List.generate(_kWebFeatures.length, (i) {
            final isActive = i == active;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              margin: const EdgeInsets.only(right: 6),
              width: isActive ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.turquoise
                    : Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Original: animação de ondas clínicas (mantida, não mais usada no painel web) ──
class _ClinicalSignalAnimation extends StatelessWidget {
  const _ClinicalSignalAnimation({
    required this.controller,
  });

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return const CustomPaint(painter: _ClinicalSignalPainter(0));
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _ClinicalSignalPainter(controller.value),
        );
      },
    );
  }
}

class _ClinicalSignalPainter extends CustomPainter {
  const _ClinicalSignalPainter(this.phase);

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.2);
    final strongLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.36);
    final nodePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.18);

    final baseY = size.height * 0.56;
    for (var i = 0; i < 5; i++) {
      final y = baseY + (i - 2) * 38;
      final path = Path()..moveTo(size.width * -0.06, y);
      for (var x = size.width * -0.06; x < size.width * 1.08; x += 90) {
        final t = phase * math.pi * 2 + i * 0.7 + x * 0.015;
        path.quadraticBezierTo(
          x + 45,
          y + math.sin(t) * 24,
          x + 90,
          y + math.cos(t * 0.7) * 16,
        );
      }
      canvas.drawPath(path, i == 2 ? strongLinePaint : linePaint);
    }

    final nodes = <Offset>[
      Offset(size.width * 0.68, size.height * 0.26),
      Offset(size.width * 0.82, size.height * 0.42),
      Offset(size.width * 0.72, size.height * 0.68),
      Offset(size.width * 0.9, size.height * 0.74),
    ];
    for (final node in nodes) {
      final pulse = 0.5 + math.sin(phase * math.pi * 2 + node.dx) * 0.5;
      canvas.drawCircle(
        node,
        7 + pulse * 3,
        nodePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClinicalSignalPainter oldDelegate) {
    return oldDelegate.phase != phase;
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _TrustPill(icon: Icons.lock_outline, label: 'Seguro'),
        _TrustPill(icon: Icons.verified_user_outlined, label: 'Profissional'),
        _TrustPill(icon: Icons.favorite_border, label: 'Clínico'),
      ],
    );
  }
}

class _TrustPill extends StatelessWidget {
  const _TrustPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.textOnBrand),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.textOnBrand,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Painel direito web (superfície + logo + form) ─────────────────────────────
class _WebLoginPanel extends StatelessWidget {
  const _WebLoginPanel({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.redirectMsg,
    required this.isLoading,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onFillSeed,
    required this.showTestAccounts,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String? redirectMsg;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final void Function(String) onFillSeed;
  final bool showTestAccounts;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        // Fundo levemente tintado — não é branco puro
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F8FF)],
        ),
        border: Border(
          left: BorderSide(color: Color(0x2200D4C9), width: 2),
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.xxl,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: MotionReveal(
              offset: const Offset(0.03, 0),
              delay: const Duration(milliseconds: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _WebBrandHeader(),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: AppSpacing.xl),
                  _LoginForm(
                    formKey: formKey,
                    emailController: emailController,
                    passwordController: passwordController,
                    obscurePassword: obscurePassword,
                    onTogglePassword: onTogglePassword,
                    redirectMsg: redirectMsg,
                    isLoading: isLoading,
                    onSubmit: onSubmit,
                    onForgotPassword: onForgotPassword,
                    onFillSeed: onFillSeed,
                    showTestAccounts: showTestAccounts,
                    showHeaderLogo: false,
                    showBrandHeader: false,
                    centerHeader: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebBrandHeader extends StatelessWidget {
  const _WebBrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.turquoise.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.10),
                blurRadius: 40,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(AppBrandingAssets.icon, fit: BoxFit.contain),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              text: TextSpan(
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
                children: const [
                  TextSpan(
                    text: 'Esquema',
                    style: TextStyle(color: AppColors.navy),
                  ),
                  TextSpan(
                    text: 'Core',
                    style: TextStyle(color: AppColors.turquoise),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'seu raciocínio clínico em mapa',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.child,
    this.compact = false,
  });

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.lg : AppSpacing.xl),
        child: child,
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.redirectMsg,
    required this.isLoading,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onFillSeed,
    required this.showTestAccounts,
    required this.showHeaderLogo,
    this.showBrandHeader = true,
    this.centerHeader = false,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String? redirectMsg;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final void Function(String email) onFillSeed;
  final bool showTestAccounts;
  final bool showHeaderLogo;
  final bool showBrandHeader;
  final bool centerHeader;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: AutofillGroup(
        child: MotionStaggered(
          interval: const Duration(milliseconds: 45),
          children: [
            if (showHeaderLogo) ...[
              const Center(
                child: EsquemaCoreLogo.horizontal(
                  size: 48,
                  showTagline: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Entrar com segurança',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Use seu e-mail cadastrado para continuar.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ] else if (showBrandHeader) ...[
              const EsquemaCoreLogo.horizontal(
                size: 40,
                showTagline: true,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Entrar com segurança',
                textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Use seu e-mail cadastrado para continuar.',
                textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ] else ...[
              Text(
                'Bem-vindo de volta',
                textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      height: 1.05,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Entre com seu e-mail e senha para acessar sua área.',
                textAlign: centerHeader ? TextAlign.center : TextAlign.start,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (redirectMsg != null) ...[
              MaterialBanner(
                backgroundColor: AppColors.infoContainer,
                content: Text(redirectMsg!),
                actions: const [SizedBox.shrink()],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: emailController,
              enabled: !isLoading,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: passwordController,
              enabled: !isLoading,
              obscureText: obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(
                labelText: 'Senha',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  tooltip: obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: onTogglePassword,
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a senha';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : onForgotPassword,
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _AnimatedSubmitButton(
              isLoading: isLoading,
              onPressed: onSubmit,
            ),
            const SizedBox(height: AppSpacing.md),
            _AccessNotice(),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: () => context.push(AppRoutes.terms),
                  child: const Text('Termos'),
                ),
                TextButton(
                  onPressed: () => context.push(AppRoutes.privacy),
                  child: const Text('Privacidade'),
                ),
              ],
            ),
            if (showTestAccounts) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Contas de teste (ambiente local)',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ActionChip(
                    label: const Text('Admin'),
                    onPressed: () =>
                        onFillSeed('admin@clinicateste-mvp.example'),
                  ),
                  ActionChip(
                    label: const Text('Psicólogo'),
                    onPressed: () =>
                        onFillSeed('psicologo@clinicateste-mvp.example'),
                  ),
                  ActionChip(
                    label: const Text('Paciente'),
                    onPressed: () =>
                        onFillSeed('paciente.login@clinicateste-mvp.example'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedSubmitButton extends StatelessWidget {
  const _AnimatedSubmitButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.resolve(context, AppAnimations.fast),
      curve: AppAnimations.standardCurve,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        boxShadow: isLoading
            ? const []
            : [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
      ),
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: AnimatedSwitcher(
          duration: AppAnimations.resolve(context, AppAnimations.fast),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(
                  Icons.arrow_forward_rounded,
                  key: ValueKey('arrow'),
                ),
        ),
        label: Text(isLoading ? 'Entrando...' : 'Entrar'),
      ),
    );
  }
}

class _AccessNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: AppColors.turquoise,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Novo acesso?',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Profissionais entram após cadastro administrativo. Pacientes entram pelo convite recebido.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.35,
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
