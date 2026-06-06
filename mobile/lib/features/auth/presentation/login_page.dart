import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../shared/widgets/error_banner.dart' show showErrorBanner;
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
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

    return Stack(
      children: [
        Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Terapia do Esquema',
                          style: Theme.of(context).textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acesse com seu e-mail e senha',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (redirectMsg != null) ...[
                          const SizedBox(height: 16),
                          MaterialBanner(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondaryContainer,
                            content: Text(redirectMsg),
                            actions: [
                              TextButton(
                                onPressed: () => ref
                                    .read(authControllerProvider.notifier)
                                    .clearRedirectMessage(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Informe o e-mail';
                            }
                            if (!v.contains('@')) {
                              return 'E-mail inválido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a senha';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: isLoading ? null : _submit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Entrar'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.push(AppRoutes.professionalSignUp),
                          child: const Text('Sou profissional, criar conta'),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Contas de teste (seed local)',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SeedChip(
                              label: 'Admin',
                              onTap: () =>
                                  _fillSeed('admin@clinicateste-mvp.example'),
                            ),
                            _SeedChip(
                              label: 'Psicólogo',
                              onTap: () => _fillSeed(
                                'psicologo@clinicateste-mvp.example',
                              ),
                            ),
                            _SeedChip(
                              label: 'Paciente',
                              onTap: () => _fillSeed(
                                'paciente.login@clinicateste-mvp.example',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isLoading) const LoadingOverlay(message: 'Entrando…'),
      ],
    );
  }
}

class _SeedChip extends StatelessWidget {
  const _SeedChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(label), onPressed: onTap);
  }
}
