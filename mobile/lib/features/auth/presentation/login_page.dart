import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import '../../../shared/widgets/loading_overlay.dart';
import '../../../shared/widgets/app_motion.dart';
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
  late final AnimationController _ambientController;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
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
  void dispose() {
    _ambientController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    await notifier.signIn(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    if (state.hasError) {
      showErrorBanner(context, state.error!);
    }
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

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.background,
          body: _AnimatedLoginBackdrop(
            controller: _ambientController,
            child: SafeArea(
              child: isWide
                  ? _buildSplitLayout(redirectMsg, isLoading)
                  : _buildMobileLayout(redirectMsg, isLoading),
            ),
          ),
        ),
        if (isLoading) const LoadingOverlay(message: 'Entrando...'),
      ],
    );
  }

  Widget _buildSplitLayout(String? redirectMsg, bool isLoading) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: MotionReveal(
                  offset: const Offset(-0.025, 0),
                  child: _LoginStoryPanel(controller: _ambientController),
                ),
              ),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(
                flex: 5,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: MotionReveal(
                        offset: const Offset(0.035, 0),
                        delay: const Duration(milliseconds: 120),
                        child: _LoginCard(
                          child: _LoginForm(
                            formKey: _formKey,
                            emailController: _emailController,
                            passwordController: _passwordController,
                            obscurePassword: _obscurePassword,
                            onTogglePassword: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            redirectMsg: redirectMsg,
                            isLoading: isLoading,
                            onSubmit: _submit,
                            onForgotPassword: () =>
                                context.push(AppRoutes.forgotPassword),
                            onFillSeed: _fillSeed,
                            showTestAccounts: EnvConfig.showTestAccounts,
                            showHeaderLogo: false,
                            showBrandHeader: true,
                            centerHeader: false,
                          ),
                        ),
                      ),
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
                                  fontWeight: FontWeight.w900,
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

class _LoginStoryPanel extends StatelessWidget {
  const _LoginStoryPanel({required this.controller});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 620),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        gradient: AppGradients.brand,
        boxShadow: [
          BoxShadow(
            color: AppColors.blue.withValues(alpha: 0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ClinicalSignalAnimation(controller: controller),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xxxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EsquemaCoreLogo.monochrome(
                  size: 86,
                  showTagline: true,
                  taglineColor: AppColors.textOnBrand,
                ),
                const Spacer(),
                Text(
                  'Acesso clínico',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.textOnBrand,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Entre para continuar seu trabalho com segurança.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textOnBrand.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                const _TrustRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
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
                    fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w800,
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
                    fontWeight: FontWeight.w900,
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
            obscureText: obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              labelText: 'Senha',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
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
                  onPressed: () => onFillSeed('admin@clinicateste-mvp.example'),
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
                        fontWeight: FontWeight.w800,
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
