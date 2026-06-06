import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../auth/providers/auth_providers.dart';
import '../../../shared/utils/brazil_validators.dart';
import '../../../shared/utils/input_formatters.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/create_professional_account_request.dart';
import '../providers/professional_onboarding_providers.dart';

class ProfessionalSignUpPage extends ConsumerStatefulWidget {
  const ProfessionalSignUpPage({super.key});

  @override
  ConsumerState<ProfessionalSignUpPage> createState() =>
      _ProfessionalSignUpPageState();
}

class _ProfessionalSignUpPageState
    extends ConsumerState<ProfessionalSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _crpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _clinicEmailController = TextEditingController();
  final _clinicPhoneController = TextEditingController();

  ProfessionalAccountMode _mode = ProfessionalAccountMode.solo;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _crpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _clinicNameController.dispose();
    _clinicEmailController.dispose();
    _clinicPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createProfessionalAccountProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Criar conta profissional')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cadastre-se para atender como profissional autônomo ou criar sua própria clínica/equipe.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: buildErrorBanner(
                          context,
                          state.error is AppException
                              ? state.error as AppException
                              : AppException(
                                  code: AppExceptionCodes.unknown,
                                  message: 'Não foi possível criar a conta.',
                                ),
                        ),
                      ),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo *',
                        border: OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Informe seu nome completo'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-mail *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Informe o e-mail';
                        }
                        if (!value.contains('@')) return 'E-mail inválido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Telefone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [BrazilPhoneInputFormatter()],
                      validator: validateOptionalPhone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _crpController,
                      decoration: const InputDecoration(
                        labelText: 'CRP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Senha *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        return validateProfessionalPassword(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirmar senha *',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirme a senha';
                        }
                        if (value != _passwordController.text) {
                          return 'As senhas não conferem';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tipo de atendimento',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ProfessionalAccountMode>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: ProfessionalAccountMode.solo,
                          label: Text('Autônomo'),
                          icon: Icon(Icons.person_outline),
                        ),
                        ButtonSegment(
                          value: ProfessionalAccountMode.clinic,
                          label: Text('Clínica/equipe'),
                          icon: Icon(Icons.groups_outlined),
                        ),
                      ],
                      selected: {_mode},
                      onSelectionChanged: (selection) {
                        setState(() => _mode = selection.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _mode == ProfessionalAccountMode.solo
                          ? 'O sistema cria sua clínica pessoal automaticamente.'
                          : 'Informe os dados básicos da clínica para começar.',
                    ),
                    if (_mode == ProfessionalAccountMode.clinic) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clinicNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome da clínica *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            validateClinicNameForMode(_mode, value),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clinicEmailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail da clínica',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          if (!value.contains('@')) {
                            return 'E-mail da clínica inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _clinicPhoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone da clínica',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [BrazilPhoneInputFormatter()],
                        validator: validateOptionalPhone,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Criar conta'),
                      ),
                    ),
                  ],
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
      await ref.read(createProfessionalAccountProvider.notifier).submit(
            CreateProfessionalAccountRequest(
              email: _emailController.text,
              password: _passwordController.text,
              fullName: _fullNameController.text,
              phone: _phoneController.text,
              crp: _crpController.text,
              mode: _mode,
              clinic: _mode == ProfessionalAccountMode.clinic
                  ? ProfessionalClinicRegistration(
                      name: _clinicNameController.text,
                      email: _clinicEmailController.text,
                      phone: _clinicPhoneController.text,
                    )
                  : null,
            ),
          );
      if (!mounted) return;
      ref.read(authRedirectMessageProvider.notifier).state =
          'Conta criada com sucesso';
      context.go(AppRoutes.login);
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _submitting = false);
    }
  }
}
