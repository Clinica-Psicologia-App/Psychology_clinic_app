import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/utils/brazil_validators.dart';
import '../../../shared/utils/input_formatters.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
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

  static const _genderOptions = [
    'Feminino',
    'Masculino',
    'Nao binario',
    'Outro',
    'Prefiro nao informar',
  ];
  static const _relationshipStatusOptions = [
    'Solteiro(a)',
    'Namorando',
    'Casado(a)',
    'Uniao estavel',
    'Separado(a)',
    'Divorciado(a)',
    'Viuvo(a)',
    'Prefiro nao informar',
  ];
  static const _educationLevelOptions = [
    'Ensino fundamental incompleto',
    'Ensino fundamental completo',
    'Ensino medio incompleto',
    'Ensino medio completo',
    'Ensino superior incompleto',
    'Ensino superior completo',
    'Pos-graduacao',
    'Mestrado',
    'Doutorado',
    'Prefiro nao informar',
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

  @override
  Widget build(BuildContext context) {
    final token = widget.token;
    return AppScaffold(
      title: 'Primeiro acesso',
      body: token == null || token.trim().isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Convite invalido ou expirado.'),
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Crie sua senha e complete os dados cadastrais para acessar o app.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (ref.watch(acceptPatientInvitationProvider).hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: buildErrorBanner(
                        context,
                        ref.watch(acceptPatientInvitationProvider).error
                                is AppException
                            ? ref.watch(acceptPatientInvitationProvider).error
                                as AppException
                            : AppException(
                                code: AppExceptionCodes.unknown,
                                message: 'Nao foi possivel concluir o cadastro.',
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
                        ? 'Informe o nome completo'
                        : null,
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
                    controller: _cpfController,
                    decoration: const InputDecoration(
                      labelText: 'CPF',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [CpfInputFormatter()],
                    validator: validateOptionalCpf,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickBirthDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data de nascimento',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        _birthDate == null
                            ? 'Opcional'
                            : _formatDate(_birthDate!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SimpleDropdownField(
                    label: 'Genero',
                    value: _selectedGender,
                    options: _genderOptions,
                    onChanged: (value) => setState(() => _selectedGender = value),
                  ),
                  const SizedBox(height: 16),
                  _SimpleDropdownField(
                    label: 'Estado civil',
                    value: _selectedRelationshipStatus,
                    options: _relationshipStatusOptions,
                    onChanged: (value) =>
                        setState(() => _selectedRelationshipStatus = value),
                  ),
                  const SizedBox(height: 16),
                  _SimpleDropdownField(
                    label: 'Escolaridade',
                    value: _selectedEducationLevel,
                    options: _educationLevelOptions,
                    onChanged: (value) =>
                        setState(() => _selectedEducationLevel = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(
                      labelText: 'Ocupacao',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _birthCountryStateController,
                    decoration: const InputDecoration(
                      labelText: 'Naturalidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _religiousOrientationController,
                    decoration: const InputDecoration(
                      labelText: 'Orientacao religiosa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ethnicGroupController,
                    decoration: const InputDecoration(
                      labelText: 'Grupo etnico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sexualOrientationController,
                    decoration: const InputDecoration(
                      labelText: 'Orientacao sexual',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    value: _hasChildren ?? false,
                    onChanged: (value) => setState(() => _hasChildren = value),
                    title: const Text('Possui filhos?'),
                    contentPadding: EdgeInsets.zero,
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
                      if (value == null || value.isEmpty) {
                        return 'Informe a senha';
                      }
                      if (value.length < 8) {
                        return 'A senha deve ter pelo menos 8 caracteres';
                      }
                      return null;
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
                        return 'As senhas nao conferem';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _submitting ? null : () => _submit(token),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Criar conta'),
                  ),
                ],
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
            ),
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Conta criada'),
          content: const Text(
            'Seu acesso foi criado com sucesso. Agora voce pode entrar com e-mail e senha.',
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
      if (mounted) {
        setState(() => _submitting = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _submitting = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
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
