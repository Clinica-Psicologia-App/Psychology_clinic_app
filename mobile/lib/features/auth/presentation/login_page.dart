import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/brand_constellation.dart';
import '../../../shared/widgets/error_banner.dart' show showErrorBanner;
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/app_motion.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  /// Respiração do gradiente da marca (painel wide e hero mobile).
  late final AnimationController _breathe;

  /// Formação das constelações na entrada (0 → 1, uma vez).
  late final AnimationController _formIn;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat(reverse: true);
    _formIn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (AppAnimations.shouldAnimate(context)) {
      _formIn.forward();
    } else {
      _formIn.value = 1;
    }

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
    _emailController.dispose();
    _passwordController.dispose();
    _breathe.dispose();
    _formIn.dispose();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            ? _buildSplitLayout(redirectMsg, isLoading)
            : _buildMobileLayout(redirectMsg, isLoading),
      ),
    );
  }

  Widget _buildSplitLayout(String? redirectMsg, bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: Listenable.merge([_breathe, _formIn]),
            builder: (context, _) {
              return DecoratedBox(
                decoration: BoxDecoration(gradient: _breathingGradient()),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      left: -30,
                      child: BrandConstellation(
                        size: const Size(220, 220),
                        opacity: 0.20,
                        progress: _formIn.value,
                        preset: BrandConstellationPreset.scatter,
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      right: -30,
                      child: BrandConstellation(
                        size: const Size(240, 240),
                        opacity: 0.20,
                        progress: _formIn.value,
                        preset: BrandConstellationPreset.path,
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xxxl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const EsquemaCoreLogo.monochrome(
                              size: 88,
                              showTagline: true,
                              taglineColor: AppColors.textOnBrand,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Text(
                              'Plataforma clínica para Terapia do Esquema',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: AppColors.textOnBrand,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Organize formulação, instrumentos e jornada terapêutica '
                              'em um único fluxo profissional.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.textOnBrand
                                        .withValues(alpha: 0.9),
                                    height: 1.5,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxxl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: MotionReveal(
                  offset: const Offset(0.035, 0),
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
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(String? redirectMsg, bool isLoading) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MobileHero(breathe: _breathe, formIn: _formIn),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: MotionReveal(
                  offset: const Offset(0, 0.04),
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gradiente do painel/hero com respiração sutil: as cores de marca
  /// deslizam entre si em vez de ficarem estáticas.
  LinearGradient _breathingGradient() {
    final t = _breathe.value;
    return LinearGradient(
      begin: Alignment(-1 + t * 0.15, -1),
      end: Alignment(1, 1 - t * 0.15),
      colors: [
        Color.lerp(AppColors.turquoise, AppColors.cyan, t * 0.5)!,
        AppColors.blue,
        Color.lerp(AppColors.purple, AppColors.blue, t * 0.3)!,
      ],
    );
  }
}

/// Hero de marca no topo do layout mobile: gradiente respirando, cantos
/// inferiores arredondados, constelação se formando e halo pulsante atrás
/// do logo monocromático.
class _MobileHero extends StatelessWidget {
  const _MobileHero({required this.breathe, required this.formIn});

  final Animation<double> breathe;
  final Animation<double> formIn;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([breathe, formIn]),
      builder: (context, _) {
        final t = breathe.value;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          child: Container(
            height: 296,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1 + t * 0.15, -1),
                end: Alignment(1, 1 - t * 0.15),
                colors: [
                  Color.lerp(AppColors.turquoise, AppColors.cyan, t * 0.5)!,
                  AppColors.blue,
                  Color.lerp(AppColors.purple, AppColors.blue, t * 0.3)!,
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: -20,
                  left: -20,
                  child: BrandConstellation(
                    size: const Size(160, 160),
                    opacity: 0.18,
                    progress: formIn.value,
                    preset: BrandConstellationPreset.scatter,
                  ),
                ),
                Positioned(
                  bottom: -10,
                  right: -20,
                  child: BrandConstellation(
                    size: const Size(150, 150),
                    opacity: 0.18,
                    progress: formIn.value,
                    preset: BrandConstellationPreset.orbit,
                  ),
                ),
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                        .withValues(alpha: 0.08 * (0.6 + t * 0.4)),
                  ),
                ),
                const EsquemaCoreLogo.monochrome(size: 76, showTagline: true),
              ],
            ),
          ),
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeaderLogo) ...[
            const EsquemaCoreLogo(
              size: 80,
              showTagline: true,
            ),
            const SizedBox(height: AppSpacing.xxl),
          ] else ...[
            Text(
              'Entrar',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Acesse com seu e-mail e senha',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: isLoading ? null : onSubmit,
              child: AnimatedSwitcher(
                duration: AppAnimations.hover,
                child: isLoading
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Entrar', key: ValueKey('idle')),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: AppColors.turquoise,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Novo acesso?',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Profissionais devem solicitar o cadastro ao '
                        'administrador da clínica. Pacientes entram pelo '
                        'convite recebido.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
            const SizedBox(height: AppSpacing.xl),
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
