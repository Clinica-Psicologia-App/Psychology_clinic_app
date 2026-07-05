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

class UpdatePasswordPage extends ConsumerStatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  ConsumerState<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends ConsumerState<UpdatePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar nova senha')),
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
                      const AppPageHeader(
                        title: 'Criar nova senha',
                        subtitle:
                            'Use pelo menos 8 caracteres, com letras maiúsculas, minúsculas e números.',
                        icon: Icons.password_outlined,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Nova senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: _confirmController,
                        obscureText: _obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar nova senha',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'As senhas não conferem';
                          }
                          return _validatePassword(value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
                            : const Icon(Icons.lock_reset_outlined),
                        label: Text(
                          _submitting ? 'Salvando...' : 'Salvar senha',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const AppInfoCard(
                        title: 'Após salvar',
                        body:
                            'Depois de salvar, você será direcionado para entrar novamente.',
                        icon: Icons.login_outlined,
                        tone: AppInfoCardTone.info,
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

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8 ||
        !RegExp('[a-z]').hasMatch(password) ||
        !RegExp('[A-Z]').hasMatch(password) ||
        !RegExp('[0-9]').hasMatch(password)) {
      return 'Use 8+ caracteres, maiúscula, minúscula e número';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(
            _passwordController.text,
          );
      await ref.read(authRepositoryProvider).signOut();
      if (!mounted) return;
      ref.read(authRedirectMessageProvider.notifier).state =
          'Senha alterada com sucesso.';
      context.go(AppRoutes.login);
    } catch (error) {
      if (mounted) showErrorBanner(context, mapToAppException(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
