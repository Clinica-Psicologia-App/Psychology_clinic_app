import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.emphasis,
    );
    _fade =
        CurvedAnimation(parent: _controller, curve: AppAnimations.enterCurve);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _controller, curve: AppAnimations.enterCurve));
    _controller.forward();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    await ref.read(authControllerProvider.notifier).restoreSession();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: authState.when(
                loading: () => _SplashContent(
                  fade: animate ? _fade : const AlwaysStoppedAnimation(1),
                  slide: animate
                      ? _slide
                      : const AlwaysStoppedAnimation(Offset.zero),
                  footer: const _LoadingFooter(),
                ),
                error: (e, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EsquemaCoreLogo(
                      size: 100,
                      showTagline: true,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      e is AppException
                          ? userMessageFor(e)
                          : 'Não foi possível restaurar a sessão.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _bootstrap,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
                data: (_) => _SplashContent(
                  fade: animate ? _fade : const AlwaysStoppedAnimation(1),
                  slide: animate
                      ? _slide
                      : const AlwaysStoppedAnimation(Offset.zero),
                  footer: const _LoadingFooter(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.fade,
    required this.slide,
    required this.footer,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EsquemaCoreLogo(
              size: 108,
              showTagline: true,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            footer,
          ],
        ),
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
        SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.turquoise,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Verificando sessão...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
