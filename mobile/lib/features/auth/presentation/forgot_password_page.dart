import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: DecoratedBox(
        decoration:
            const BoxDecoration(gradient: AppGradients.splashBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ResponsiveContent(
              maxWidth: 480,
              child: MotionReveal(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: AppPageHeader(
                          key: ValueKey(_sent),
                          title: _sent
                              ? 'Verifique seu e-mail'
                              : 'Recuperar senha',
                          subtitle: _sent
                              ? 'Se o endereço estiver cadastrado, enviaremos um link para criar uma nova senha.'
                              : 'Informe seu e-mail para receber o link de recuperação.',
                          icon: _sent
                              ? Icons.mark_email_read_outlined
                              : Icons.lock_reset,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (!_sent) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Informe o e-mail';
                            if (!email.contains('@')) return 'E-mail inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.mark_email_read_outlined),
                          label: Text(
                            _submitting ? 'Enviando...' : 'Enviar recuperação',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const AppInfoCard(
                          title: 'Segurança',
                          body:
                              'Por segurança, avisaremos da mesma forma mesmo que o e-mail não esteja cadastrado.',
                          icon: Icons.shield_outlined,
                          tone: AppInfoCardTone.info,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Voltar para o login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(
            _emailController.text,
          );
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) showErrorBanner(context, mapToAppException(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
