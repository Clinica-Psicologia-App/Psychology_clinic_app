import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/brazil_validators.dart';
import '../../../shared/utils/input_formatters.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/create_patient_request.dart';
import '../domain/psychologist_option.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import '../../../shared/widgets/form_section.dart' show FormPageBody;

class CreatePatientPage extends ConsumerStatefulWidget {
  const CreatePatientPage({super.key, required this.role});

  final ProfileRole role;

  @override
  ConsumerState<CreatePatientPage> createState() => _CreatePatientPageState();
}

class _CreatePatientPageState extends ConsumerState<CreatePatientPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _occupationController = TextEditingController();
  final _stateBirthController = TextEditingController();
  final _countryBirthController = TextEditingController();
  final _religiousOrientationController = TextEditingController();
  final _ethnicGroupController = TextEditingController();
  final _sexualOrientationController = TextEditingController();

  DateTime? _birthDate;
  String? _selectedPsychologistId;
  String? _selectedGender;
  String? _selectedRelationshipStatus;
  String? _selectedEducationLevel;
  bool? _hasChildren;
  bool _submitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showOptionalFields = false;

  static const _fieldSpacing = 16.0;
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
    _emailController.dispose();
    _phoneController.dispose();
    _cpfController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _occupationController.dispose();
    _stateBirthController.dispose();
    _countryBirthController.dispose();
    _religiousOrientationController.dispose();
    _ethnicGroupController.dispose();
    _sexualOrientationController.dispose();
    super.dispose();
  }

  bool get _isAdmin => false;

  // Campos dentro dos cards — underline limpo, sem fill
  InputDecoration _cardDecoration(String label, {String? hint, String? helper}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      border: const UnderlineInputBorder(),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: AppColors.blue, width: 1.5),
      ),
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.only(bottom: 8, top: 12),
    );
  }


  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final psychologistsAsync = _isAdmin
        ? ref.watch(psychologistsOptionsProvider)
        : const AsyncValue<List<PsychologistOption>>.data([]);

    final psychologistId = _isAdmin ? _selectedPsychologistId : profile?.id;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AppScaffold(
      title: 'Novo paciente',
      accent: AppColors.blue,
      body: FormPageBody(
        maxWidth: 640,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              MotionStaggered(
                children: [
                  // ── Card 1: Essencial (obrigatório) ──────────────────────
                  _SectionCard(
                    title: 'Essencial',
                    badge: 'obrigatório',
                    badgeColor: const Color(0xFF3B6D11),
                    badgeBg: const Color(0xFFEAF3DE),
                    dotColor: AppColors.blue,
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: _cardDecoration('Nome completo *'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Informe o nome'
                            : null,
                      ),
                      const SizedBox(height: _fieldSpacing),
                      TextFormField(
                        controller: _emailController,
                        decoration: _cardDecoration(
                          'E-mail de login *',
                          hint: 'paciente@exemplo.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o e-mail';
                          }
                          if (!v.contains('@')) return 'E-mail inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldSpacing),
                      TextFormField(
                        controller: _passwordController,
                        decoration: _cardDecoration(
                          'Senha inicial *',
                          helper: 'Mínimo 8 caracteres',
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.length < 8) {
                            return 'Senha com pelo menos 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldSpacing),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: _cardDecoration('Confirmar senha *').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (!_submitting &&
                              profile != null &&
                              psychologistId != null) {
                            _submit(profile, psychologistId);
                          }
                        },
                        validator: (v) {
                          if (v != _passwordController.text) {
                            return 'As senhas não coincidem';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Card 2: Perfil clínico (opcional, recolhível) ─────────
                  _SectionCard(
                    title: 'Perfil clínico',
                    badge: 'opcional',
                    badgeColor: const Color(0xFF6B7A99),
                    badgeBg: const Color(0xFFF0F4FB),
                    dotColor: const Color(0xFF8892A4),
                    trailing: TextButton(
                      onPressed: () => setState(
                          () => _showOptionalFields = !_showOptionalFields),
                      child: Text(
                        _showOptionalFields ? 'Recolher ↑' : 'Expandir ↓',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    children: _showOptionalFields
                        ? [
                            _SimpleDropdownField(
                              label: 'Gênero',
                              value: _selectedGender,
                              hint: 'Selecione',
                              options: _genderOptions,
                              onChanged: (value) =>
                                  setState(() => _selectedGender = value),
                              cardStyle: true,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            InkWell(
                              onTap: _pickBirthDate,
                              borderRadius: BorderRadius.circular(4),
                              child: InputDecorator(
                                decoration: _cardDecoration(
                                  'Data de nascimento',
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: const Icon(
                                        Icons.calendar_today_outlined),
                                    onPressed: _pickBirthDate,
                                  ),
                                ),
                                child: Text(
                                  _birthDate == null
                                      ? ''
                                      : _formatDate(_birthDate!),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: _birthDate == null
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant
                                            : null,
                                      ),
                                ),
                              ),
                            ),
                            if (_birthDate != null) ...[
                              const SizedBox(height: 4),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _birthDate = null),
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: const Text('Limpar data'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _phoneController,
                              decoration: _cardDecoration('Telefone',
                                  hint: '(51) 99999-9999'),
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [BrazilPhoneInputFormatter()],
                              validator: validateOptionalPhone,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _cpfController,
                              decoration: _cardDecoration('CPF',
                                  hint: '000.000.000-00'),
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [CpfInputFormatter()],
                              validator: validateOptionalCpf,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _SimpleDropdownField(
                              label: 'Estado civil',
                              value: _selectedRelationshipStatus,
                              hint: 'Selecione',
                              options: _relationshipStatusOptions,
                              onChanged: (value) => setState(
                                  () => _selectedRelationshipStatus = value),
                              cardStyle: true,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _SimpleDropdownField(
                              label: 'Escolaridade',
                              value: _selectedEducationLevel,
                              hint: 'Selecione',
                              options: _educationLevelOptions,
                              onChanged: (value) => setState(
                                  () => _selectedEducationLevel = value),
                              cardStyle: true,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _occupationController,
                              decoration: _cardDecoration('Ocupação',
                                  hint: 'Ex.: Jornalista'),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _stateBirthController,
                              decoration: _cardDecoration(
                                  'Estado de nascimento',
                                  hint: 'Ex.: Rio Grande do Sul'),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _countryBirthController,
                              decoration: _cardDecoration('País de nascimento',
                                  hint: 'Ex.: Brasil'),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _religiousOrientationController,
                              decoration:
                                  _cardDecoration('Orientação religiosa'),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _ethnicGroupController,
                              decoration: _cardDecoration('Grupo étnico'),
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            TextFormField(
                              controller: _sexualOrientationController,
                              decoration: _cardDecoration('Orientação sexual'),
                              textCapitalization: TextCapitalization.sentences,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: _fieldSpacing),
                            _SimpleDropdownField(
                              label: 'Possui filhos?',
                              value: switch (_hasChildren) {
                                true => 'Sim',
                                false => 'Não',
                                null => null,
                              },
                              hint: 'Selecione',
                              options: const ['Sim', 'Não'],
                              onChanged: (value) => setState(
                                () => _hasChildren = switch (value) {
                                  'Sim' => true,
                                  'Não' => false,
                                  _ => null,
                                },
                              ),
                              cardStyle: true,
                            ),
                          ]
                        : const [],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Psicólogo responsável ─────────────────────────────────
                  if (_isAdmin)
                    psychologistsAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (_, __) => const Text(
                        'Não foi possível carregar psicólogos.',
                      ),
                      data: (options) => _PsychologistDropdown(
                        options: options,
                        value: _selectedPsychologistId,
                        onChanged: (v) =>
                            setState(() => _selectedPsychologistId = v),
                      ),
                    )
                  else if (profile != null)
                    _SectionCard(
                      title: 'Responsável',
                      badge: null,
                      badgeColor: Colors.transparent,
                      badgeBg: Colors.transparent,
                      dotColor: AppColors.blue,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  AppColors.blue.withValues(alpha: 0.12),
                              child: Icon(Icons.psychology_outlined,
                                  color: AppColors.blue, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Psicólogo responsável',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                              color: AppColors.textSecondary)),
                                  Text(profile.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              FilledButton.icon(
                onPressed:
                    _submitting || profile == null || psychologistId == null
                        ? null
                        : () => _submit(profile, psychologistId),
                icon: _submitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.person_add_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cadastrar paciente'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1920),
      lastDate: now,
      locale: const Locale('pt', 'BR'),
      helpText: 'Data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _submit(UserProfile profile, String psychologistId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    final phoneDigits = digitsOnly(_phoneController.text);
    final cpfDigits = digitsOnly(_cpfController.text);

    try {
      final patient = await ref.read(createPatientProvider.notifier).submit(
            CreatePatientRequest(
              email: _emailController.text,
              password: _passwordController.text,
              fullName: _fullNameController.text,
              responsiblePsychologistId: psychologistId,
              phone: phoneDigits.isEmpty ? null : phoneDigits,
              cpf: cpfDigits.isEmpty ? null : cpfDigits,
              birthDate: _birthDate,
              gender: _selectedGender,
              relationshipStatus: _selectedRelationshipStatus,
              educationLevel: _selectedEducationLevel,
              occupation: _occupationController.text,
              stateBirth: _stateBirthController.text,
              countryBirth: _countryBirthController.text,
              religiousOrientation: _religiousOrientationController.text,
              ethnicGroup: _ethnicGroupController.text,
              sexualOrientation: _sexualOrientationController.text,
              hasChildren: _hasChildren,
            ),
          );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Paciente cadastrado'),
          content: Text(
            '${patient.fullName} foi criado com sucesso.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      context.go(PatientRoutes.detail(widget.role, patient.id));
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

class _SimpleDropdownField extends StatelessWidget {
  const _SimpleDropdownField({
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.cardStyle = false,
  });

  final String label;
  final String? value;
  final String hint;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final bool cardStyle;

  @override
  Widget build(BuildContext context) {
    final InputDecoration deco = cardStyle
        ? InputDecoration(
            labelText: label,
            border: const UnderlineInputBorder(),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide:
                  BorderSide(color: AppColors.blue, width: 1.5),
            ),
            filled: false,
            isDense: true,
            contentPadding:
                const EdgeInsets.only(bottom: 8, top: 12),
          )
        : InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            filled: true,
            fillColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
          );
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: deco,
      hint: Text(hint),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.badge,
    required this.badgeColor,
    required this.badgeBg,
    required this.dotColor,
    required this.children,
    this.trailing,
  });

  final String title;
  final String? badge;
  final Color badgeColor;
  final Color badgeBg;
  final Color dotColor;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}

class _PsychologistDropdown extends StatelessWidget {
  const _PsychologistDropdown({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<PsychologistOption> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return const Text('Nenhum psicólogo ativo na clínica.');
    }

    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Psicólogo responsável *',
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
      ),
      hint: const Text('Selecione'),
      items: options
          .map(
            (p) => DropdownMenuItem(
              value: p.id,
              child: _PsychologistMenuItem(option: p),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => options
          .map(
            (p) => Align(
              alignment: Alignment.centerLeft,
              child: Text(
                p.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Selecione o psicólogo' : null,
    );
  }
}

class _PsychologistMenuItem extends StatelessWidget {
  const _PsychologistMenuItem({required this.option});

  final PsychologistOption option;

  @override
  Widget build(BuildContext context) {
    final email = option.email;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          option.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (email != null && email.isNotEmpty)
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        Text(
          option.accessSummary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: option.canAssignNewPatient
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
