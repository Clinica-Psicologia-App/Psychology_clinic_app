import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/legal/legal_documents.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/brazil_validators.dart';
import '../../../shared/utils/input_formatters.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/form_section.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/accept_patient_invitation_request.dart';
import '../providers/patient_invitations_providers.dart';

class AcceptPatientInvitationPage extends ConsumerStatefulWidget {
  const AcceptPatientInvitationPage({
    super.key,
    required this.token,
  });

  final String? token;

  @override
  ConsumerState<AcceptPatientInvitationPage> createState() =>
      _AcceptPatientInvitationPageState();
}

class _AcceptPatientInvitationPageState
    extends ConsumerState<AcceptPatientInvitationPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _occupationController = TextEditingController();
  final _birthCountryStateController = TextEditingController();
  final _religiousOrientationController = TextEditingController();
  final _ethnicGroupController = TextEditingController();
  final _sexualOrientationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedGender;
  String? _selectedRelationshipStatus;
  String? _selectedEducationLevel;
  bool? _hasChildren;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedLegal = false;

  static const _genderOptions = [
    'Feminino',
    'Masculino',
    'Não binário',
    'Outro',
    'Prefiro não informar',
  ];
  static const _relationshipStatusOptions = [
    'Solteiro(a)',
    'Namorando',
    'Casado(a)',
    'União estável',
    'Separado(a)',
    'Divorciado(a)',
    'Viúvo(a)',
    'Prefiro não informar',
  ];
  static const _educationLevelOptions = [
    'Ensino fundamental incompleto',
    'Ensino fundamental completo',
    'Ensino médio incompleto',
    'Ensino médio completo',
    'Ensino superior incompleto',
    'Ensino superior completo',
    'Pós-graduação',
    'Mestrado',
    'Doutorado',
    'Prefiro não informar',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _occupationController.dispose();
    _birthCountryStateController.dispose();
    _religiousOrientationController.dispose();
    _ethnicGroupController.dispose();
    _sexualOrientationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.35),
    );
  }

  @override
  Widget build(BuildContext context) {
    final token = widget.token?.trim();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        child: token == null || token.isEmpty
            ? const _InvalidInvitationBody(
                icon: Icons.link_off_outlined,
                title: 'Convite inválido',
                message:
                    'O link de convite não foi reconhecido. Solicite um novo '
                    'convite à clínica.',
              )
            : SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ResponsiveContent(
                  maxWidth: 560,
                  child: MotionReveal(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AppPageHeader(
                          title: 'Primeiro acesso',
                          subtitle:
                              'Você foi convidado(a) a acessar a plataforma clínica. Complete seus dados e crie uma senha para entrar.',
                          icon: Icons.mark_email_read_outlined,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const AppInfoCard(
                          title: 'Privacidade',
                          icon: Icons.lock_outline,
                          body:
                              'Seus dados serão usados apenas para cadastro e '
                              'acompanhamento clínico na clínica que enviou o convite.',
                          tone: AppInfoCardTone.info,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (ref.watch(acceptPatientInvitationProvider).hasError)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _InvitationErrorPanel(
                              error: ref
                                  .watch(acceptPatientInvitationProvider)
                                  .error!,
                            ),
                          ),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              FormSection(
                                title: 'Dados pessoais',
                                subtitle:
                                    'Essas informações ajudam a clínica a identificar seu cadastro.',
                                icon: Icons.person_outline,
                                children: [
                                  TextFormField(
                                    controller: _fullNameController,
                                    decoration: _decoration('Nome completo *'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? 'Informe o nome completo'
                                            : null,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  InkWell(
                                    onTap: _pickBirthDate,
                                    child: InputDecorator(
                                      decoration: _decoration(
                                        'Data de nascimento',
                                        hint: 'Opcional',
                                      ),
                                      child: Text(
                                        _birthDate == null
                                            ? 'Opcional'
                                            : _formatDate(_birthDate!),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _SimpleDropdownField(
                                    label: 'Gênero',
                                    value: _selectedGender,
                                    options: _genderOptions,
                                    onChanged: (value) =>
                                        setState(() => _selectedGender = value),
                                  ),
                                ],
                              ),
                              FormSection(
                                title: 'Contato',
                                subtitle:
                                    'Telefone e CPF são opcionais e podem ser atualizados depois.',
                                icon: Icons.phone_outlined,
                                children: [
                                  TextFormField(
                                    controller: _phoneController,
                                    decoration: _decoration('Telefone'),
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      BrazilPhoneInputFormatter()
                                    ],
                                    validator: validateOptionalPhone,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _cpfController,
                                    decoration: _decoration('CPF'),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [CpfInputFormatter()],
                                    validator: validateOptionalCpf,
                                  ),
                                ],
                              ),
                              FormSection(
                                title: 'Informações sociodemográficas',
                                subtitle:
                                    'Preencha apenas o que fizer sentido para você neste momento.',
                                icon: Icons.groups_outlined,
                                children: [
                                  FormFieldGrid(
                                    children: [
                                      _SimpleDropdownField(
                                        label: 'Estado civil',
                                        value: _selectedRelationshipStatus,
                                        options: _relationshipStatusOptions,
                                        onChanged: (value) => setState(
                                          () => _selectedRelationshipStatus =
                                              value,
                                        ),
                                      ),
                                      _SimpleDropdownField(
                                        label: 'Escolaridade',
                                        value: _selectedEducationLevel,
                                        options: _educationLevelOptions,
                                        onChanged: (value) => setState(
                                          () => _selectedEducationLevel = value,
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _occupationController,
                                        decoration: _decoration('Ocupação'),
                                      ),
                                      TextFormField(
                                        controller:
                                            _birthCountryStateController,
                                        decoration: _decoration('Naturalidade'),
                                      ),
                                      TextFormField(
                                        controller:
                                            _religiousOrientationController,
                                        decoration:
                                            _decoration('Orientação religiosa'),
                                      ),
                                      TextFormField(
                                        controller: _ethnicGroupController,
                                        decoration: _decoration('Grupo étnico'),
                                      ),
                                      TextFormField(
                                        controller:
                                            _sexualOrientationController,
                                        decoration:
                                            _decoration('Orientação sexual'),
                                      ),
                                    ],
                                  ),
                                  SwitchListTile(
                                    value: _hasChildren ?? false,
                                    onChanged: (value) =>
                                        setState(() => _hasChildren = value),
                                    title: const Text('Possui filhos?'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              FormSection(
                                title: 'Acesso',
                                subtitle: 'Crie a senha que usará para entrar',
                                icon: Icons.lock_outline,
                                children: [
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: _decoration('Senha *').copyWith(
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Informe a senha';
                                      }
                                      if (value.length < 8) {
                                        return 'A senha deve ter pelo menos 8 caracteres';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    decoration: _decoration('Confirmar senha *')
                                        .copyWith(
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
                                ],
                              ),
                              CheckboxListTile(
                                value: _acceptedLegal,
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (value) => setState(
                                  () => _acceptedLegal = value ?? false,
                                ),
                                title: const Text(
                                  'Li e aceito os Termos de Uso e a Política de '
                                  'Privacidade.',
                                ),
                                subtitle: Wrap(
                                  spacing: AppSpacing.xs,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.terms),
                                      child: const Text('Ler termos'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          context.push(AppRoutes.privacy),
                                      child: const Text('Ler privacidade'),
                                    ),
                                  ],
                                ),
                              ),
                              if (!_acceptedLegal)
                                Text(
                                  'O aceite é obrigatório para criar a conta.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              const SizedBox(height: AppSpacing.md),
                              FilledButton.icon(
                                onPressed: _submitting || !_acceptedLegal
                                    ? null
                                    : () => _submit(token),
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.check_circle_outline),
                                label: Text(
                                  _submitting
                                      ? 'Criando conta...'
                                      : 'Criar conta',
                                ),
                              ),
                              TextButton(
                                onPressed: _submitting
                                    ? null
                                    : () => context.go(AppRoutes.login),
                                child: const Text('Já tenho conta'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _submit(String token) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await ref.read(acceptPatientInvitationProvider.notifier).submit(
            AcceptPatientInvitationRequest(
              token: token,
              password: _passwordController.text,
              profile: AcceptPatientInvitationProfile(
                fullName: _fullNameController.text,
                phone: _phoneController.text,
                cpf: _cpfController.text,
                birthDate: _birthDate,
                gender: _selectedGender,
                relationshipStatus: _selectedRelationshipStatus,
                educationLevel: _selectedEducationLevel,
                occupation: _occupationController.text,
                birthCountryState: _birthCountryStateController.text,
                religiousOrientation: _religiousOrientationController.text,
                ethnicGroup: _ethnicGroupController.text,
                sexualOrientation: _sexualOrientationController.text,
                hasChildren: _hasChildren,
              ),
              termsVersion: LegalDocuments.termsVersion,
              privacyVersion: LegalDocuments.privacyVersion,
            ),
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conta criada'),
          content: const Text(
            'Seu acesso foi criado com sucesso. Agora você pode entrar com '
            'e-mail e senha.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ir para login'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
      return;
    }

    if (mounted) setState(() => _submitting = false);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _InvalidInvitationBody extends StatelessWidget {
  const _InvalidInvitationBody({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ResponsiveContent(
          maxWidth: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const EsquemaCoreLogo(size: 72, showTagline: true),
              const SizedBox(height: AppSpacing.xl),
              Icon(icon, size: 48, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: const Text('Ir para login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvitationErrorPanel extends StatelessWidget {
  const _InvitationErrorPanel({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is AppException
        ? userMessageFor(error as AppException)
        : 'Não foi possível concluir o cadastro.';

    final (icon, title) = _resolvePresentation(message);

    return Card(
      color:
          Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, String) _resolvePresentation(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('expirado')) {
      return (Icons.schedule_outlined, 'Convite expirado');
    }
    if (lower.contains('inválido') || lower.contains('invalido')) {
      return (Icons.link_off_outlined, 'Convite inválido');
    }
    if (lower.contains('já') ||
        lower.contains('ja ') ||
        lower.contains('uso')) {
      return (Icons.check_circle_outline, 'Convite já utilizado');
    }
    if (lower.contains('revogado')) {
      return (Icons.block_outlined, 'Convite revogado');
    }
    return (Icons.error_outline, 'Não foi possível concluir');
  }
}

class _SimpleDropdownField extends StatelessWidget {
  const _SimpleDropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
