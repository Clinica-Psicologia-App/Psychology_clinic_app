import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_shell.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_form.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../domain/psychologist_option.dart';
import '../domain/update_patient_credentials_request.dart';
import '../domain/update_patient_request.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';

class EditPatientPage extends ConsumerStatefulWidget {
  const EditPatientPage({
    super.key,
    required this.patient,
    required this.role,
  });

  final Patient patient;
  final ProfileRole role;

  @override
  ConsumerState<EditPatientPage> createState() => _EditPatientPageState();
}

/// Decoração de um campo: a do celular leva o rótulo dentro; a de desktop, não.
typedef _Deco = InputDecoration Function(String label,
    {String? helper, Widget? suffix});

/// Decoração dos campos no celular.
InputDecoration _outline(String label, {String? helper, Widget? suffix}) =>
    InputDecoration(
      labelText: label,
      helperText: helper,
      border: const OutlineInputBorder(),
      suffixIcon: suffix,
    );

class _EditPatientPageState extends ConsumerState<EditPatientPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _occupation;
  late final TextEditingController _stateBirth;
  late final TextEditingController _countryBirth;
  late final TextEditingController _religiousOrientation;
  late final TextEditingController _ethnicGroup;

  DateTime? _birthDate;
  String? _gender;
  String? _relationshipStatus;
  String? _educationLevel;
  String? _sexualOrientation;
  bool? _hasChildren;
  String? _responsiblePsychologistId;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _fullName = TextEditingController(text: p.fullName);
    _phone = TextEditingController(text: p.phone ?? '');
    _occupation = TextEditingController(text: p.occupation ?? '');
    _stateBirth = TextEditingController(text: p.stateBirth ?? '');
    _countryBirth = TextEditingController(text: p.countryBirth ?? '');
    _religiousOrientation =
        TextEditingController(text: p.religiousOrientation ?? '');
    _ethnicGroup = TextEditingController(text: p.ethnicGroup ?? '');
    _birthDate = p.birthDate;
    _gender = p.gender;
    _relationshipStatus = p.relationshipStatus;
    _educationLevel = p.educationLevel;
    _sexualOrientation = p.sexualOrientation;
    _hasChildren = p.hasChildren;
    _responsiblePsychologistId = p.responsiblePsychologistId;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _occupation.dispose();
    _stateBirth.dispose();
    _countryBirth.dispose();
    _religiousOrientation.dispose();
    _ethnicGroup.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = UpdatePatientRequest(
      patientId: widget.patient.id,
      fullName: _fullName.text.trim(),
      phone: _phone.text,
      birthDate: _birthDate,
      gender: _gender,
      relationshipStatus: _relationshipStatus,
      educationLevel: _educationLevel,
      occupation: _occupation.text,
      stateBirth: _stateBirth.text,
      countryBirth: _countryBirth.text,
      religiousOrientation: _religiousOrientation.text,
      ethnicGroup: _ethnicGroup.text,
      sexualOrientation: _sexualOrientation,
      hasChildren: _hasChildren,
      responsiblePsychologistId: _responsiblePsychologistId,
    );

    try {
      await ref.read(updatePatientProvider.notifier).submit(request);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {}
  }

  static String _saveError(Object? error) => error is AppException
      ? error.message
      : 'Erro ao salvar. Tente novamente.';

  // ── Desktop (>= 768 px, psicóloga) ────────────────────────────────────────

  static const _sections = [
    'Dados pessoais',
    'Origem',
    'Diversidade',
    'Responsabilidade',
    'Acesso do paciente',
  ];

  final _sectionKeys = List.generate(_sections.length, (_) => GlobalKey());
  int _section = 0;

  void _goToSection(int i) {
    setState(() => _section = i);
    final target = _sectionKeys[i].currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _desktop(
    BuildContext context,
    AsyncValue<void> updateState,
    AsyncValue<List<PsychologistOption>> psychologistsAsync,
    ThemeData theme,
    MaterialLocalizations loc,
  ) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final patient = widget.patient;
    InputDecoration deco(String label, {String? helper, Widget? suffix}) =>
        desktopFieldDecoration(context, helper: helper, suffix: suffix);
    InputDecoration select() => desktopFieldDecoration(context);
    Widget labeled(String label, Widget field) =>
        DaLabeled(label, child: field);
    Widget section(int i, Widget child) => Padding(
          key: _sectionKeys[i],
          padding: const EdgeInsets.only(bottom: 24),
          child: DesktopFormSection(title: _sections[i], child: child),
        );

    return DesktopPsychologistFrame(
      title: 'Editar paciente',
      subtitle:
          'Atualize dados pessoais, contexto de origem, diversidade e responsabilidade clínica.',
      crumbs: [
        DaCrumb('Pacientes', PatientRoutes.list(widget.role)),
        DaCrumb(patient.fullName,
            PatientRoutes.detail(widget.role, patient.id)),
      ],
      body: Form(
        key: _formKey,
        child: DesktopFormBody(
          busy: updateState.isLoading,
          // Índice das seções (some no tablet).
          leading: m.tablet
              ? null
              : Container(
                  width: m.size == DesktopAdminSize.desktop ? 260 : 220,
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: t.bd))),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < _sections.length; i++)
                          DaIndexItem(
                            label: _sections[i],
                            active: i == _section,
                            onTap: () => _goToSection(i),
                          ),
                      ],
                    ),
                  ),
                ),
          actions: [
            DaButton(
              label: 'Salvar alterações',
              kind: DaButtonKind.primary,
              onPressed: updateState.isLoading ? null : _submit,
            ),
          ],
          children: [
            DesktopFormTags(children: [
              DaTag.az(context, patient.fullName),
              if (patient.isActive)
                DaTag.ok(context, 'Ativo')
              else
                const DaTag('Inativo'),
            ]),
            const SizedBox(height: 20),
            if (updateState.hasError)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                decoration: BoxDecoration(
                  border: Border.all(color: t.err),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_saveError(updateState.error),
                          style: daText(context, t, color: t.err)),
                    ),
                    DaButton(
                      label: 'OK',
                      kind: DaButtonKind.ghost,
                      onPressed: () => ref.invalidate(updatePatientProvider),
                    ),
                  ],
                ),
              ),
            section(
              0,
              DesktopFormGrid(children: [
                labeled('Nome completo *', _nameField(deco)),
                labeled('Telefone', _phoneField(deco)),
                labeled('Data de nascimento',
                    _birthDateField(deco, theme, loc)),
                labeled('Gênero', _genderField(decoration: select())),
                labeled(
                    'Estado civil', _relationshipField(decoration: select())),
                labeled('Escolaridade', _educationField(decoration: select())),
                labeled('Ocupação', _occupationField(deco)),
              ]),
            ),
            section(
              1,
              DesktopFormGrid(children: [
                labeled('Estado de nascimento', _stateBirthField(deco)),
                labeled('País de nascimento', _countryBirthField(deco)),
              ]),
            ),
            section(
              2,
              DesktopFormGrid(children: [
                labeled('Orientação religiosa', _religionField(deco)),
                labeled('Grupo étnico', _ethnicField(deco)),
                labeled('Orientação sexual',
                    _sexualField(decoration: select())),
                labeled('Filhos', _childrenField(decoration: select())),
              ]),
            ),
            section(
              3,
              DesktopFormGrid(children: [
                labeled(
                  'Psicólogo responsável',
                  _responsibleField(psychologistsAsync, decoration: select()),
                ),
              ]),
            ),
            KeyedSubtree(
              key: _sectionKeys[4],
              child: PatientAccessSection(patient: patient, desktop: true),
            ),
          ],
        ),
      ),
    );
  }

  // ── Campos (celular e desktop) ────────────────────────────────────────────

  Widget _nameField(_Deco deco) => TextFormField(
    controller: _fullName,
    decoration: deco('Nome completo *'),
    textCapitalization: TextCapitalization.words,
    validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
  );

  Widget _phoneField(_Deco deco) => TextFormField(
    controller: _phone,
    decoration: deco('Telefone'),
    keyboardType: TextInputType.phone,
  );

  Widget _occupationField(_Deco deco) => TextFormField(
    controller: _occupation,
    decoration: deco('Ocupação'),
    textCapitalization: TextCapitalization.sentences,
  );

  Widget _stateBirthField(_Deco deco) => TextFormField(
    controller: _stateBirth,
    decoration: deco('Estado de nascimento'),
  );

  Widget _countryBirthField(_Deco deco) => TextFormField(
    controller: _countryBirth,
    decoration: deco('País de nascimento'),
  );

  Widget _religionField(_Deco deco) => TextFormField(
    controller: _religiousOrientation,
    decoration: deco('Orientação religiosa'),
    textCapitalization: TextCapitalization.sentences,
  );

  Widget _ethnicField(_Deco deco) => TextFormField(
    controller: _ethnicGroup,
    decoration: deco('Grupo étnico'),
    textCapitalization: TextCapitalization.sentences,
  );

  Widget _birthDateField(
      _Deco deco, ThemeData theme, MaterialLocalizations loc) => InkWell(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _birthDate ?? DateTime(1990),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) setState(() => _birthDate = picked);
    },
    child: InputDecorator(
      decoration: deco('Data de nascimento', suffix: const Icon(Icons.calendar_today_outlined)),
      child: Text(
        _birthDate != null
            ? loc.formatFullDate(_birthDate!)
            : 'Selecionar data',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: _birthDate == null
              ? theme.colorScheme.onSurfaceVariant
              : null,
        ),
      ),
    ),
  );

  Widget _genderField({InputDecoration? decoration}) => _DropdownField<String>(
    label: 'Gênero',
    value: _gender,
    items: const [
      DropdownMenuItem(value: 'female', child: Text('Feminino')),
      DropdownMenuItem(value: 'male', child: Text('Masculino')),
      DropdownMenuItem(
          value: 'non_binary', child: Text('Não binário')),
      DropdownMenuItem(value: 'other', child: Text('Outro')),
      DropdownMenuItem(
          value: 'nao_informado', child: Text('Não informado')),
    ],
    decoration: decoration,
    onChanged: (v) => setState(() => _gender = v),
  );

  Widget _relationshipField({InputDecoration? decoration}) => _DropdownField<String>(
    label: 'Estado civil',
    value: _relationshipStatus,
    items: const [
      DropdownMenuItem(value: 'single', child: Text('Solteiro(a)')),
      DropdownMenuItem(value: 'married', child: Text('Casado(a)')),
      DropdownMenuItem(
          value: 'divorced', child: Text('Divorciado(a)')),
      DropdownMenuItem(value: 'widowed', child: Text('Viúvo(a)')),
      DropdownMenuItem(
          value: 'stable_union', child: Text('União estável')),
      DropdownMenuItem(
          value: 'nao_informado', child: Text('Não informado')),
    ],
    decoration: decoration,
    onChanged: (v) => setState(() => _relationshipStatus = v),
  );

  Widget _educationField({InputDecoration? decoration}) => _DropdownField<String>(
    label: 'Escolaridade',
    value: _educationLevel,
    items: const [
      DropdownMenuItem(
          value: 'elementary', child: Text('Ensino fundamental')),
      DropdownMenuItem(
          value: 'high_school', child: Text('Ensino médio')),
      DropdownMenuItem(
          value: 'undergraduate', child: Text('Ensino superior')),
      DropdownMenuItem(
          value: 'graduate', child: Text('Pós-graduação')),
      DropdownMenuItem(
          value: 'nao_informado', child: Text('Não informado')),
    ],
    decoration: decoration,
    onChanged: (v) => setState(() => _educationLevel = v),
  );

  Widget _sexualField({InputDecoration? decoration}) => _DropdownField<String>(
    label: 'Orientação sexual',
    value: _sexualOrientation,
    items: const [
      DropdownMenuItem(
          value: 'heterosexual', child: Text('Heterossexual')),
      DropdownMenuItem(
          value: 'homosexual', child: Text('Homossexual')),
      DropdownMenuItem(value: 'bisexual', child: Text('Bissexual')),
      DropdownMenuItem(value: 'asexual', child: Text('Assexual')),
      DropdownMenuItem(
          value: 'pansexual', child: Text('Pansexual')),
      DropdownMenuItem(
          value: 'nao_informado', child: Text('Não informado')),
    ],
    decoration: decoration,
    onChanged: (v) => setState(() => _sexualOrientation = v),
  );

  Widget _childrenField({InputDecoration? decoration}) => _DropdownField<bool>(
    label: 'Filhos',
    value: _hasChildren,
    items: const [
      DropdownMenuItem(value: true, child: Text('Sim')),
      DropdownMenuItem(value: false, child: Text('Não')),
    ],
    decoration: decoration,
    onChanged: (v) => setState(() => _hasChildren = v),
  );

  Widget _responsibleField(
      AsyncValue<List<PsychologistOption>> psychologistsAsync,
      {InputDecoration? decoration}) => psychologistsAsync.when(
    loading: () => const LinearProgressIndicator(),
    error: (_, __) => const Text(
      'Não foi possível carregar os psicólogos.',
    ),
    data: (psychologists) => _PsychologistDropdown(
      psychologists: psychologists,
      selectedId: _responsiblePsychologistId,
      decoration: decoration,
        onChanged: (id) =>
          setState(() => _responsiblePsychologistId = id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updatePatientProvider);
    final psychologistsAsync = ref.watch(psychologistsOptionsProvider);
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);

    if (widget.role == ProfileRole.psychologist &&
        inDesktopPsychologistShell(context)) {
      return _desktop(context, updateState, psychologistsAsync, theme, loc);
    }

    return AppScaffold(
      title: widget.patient.fullName,
      accent: AppColors.blue,
      body: MotionReveal(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              AppPageHeader(
                icon: Icons.person_outline,
                title: 'Editar paciente',
                subtitle:
                    'Atualize dados pessoais, contexto de origem, diversidade e responsabilidade clínica.',
                metadata: [
                  StatusChip(
                    label: widget.patient.fullName,
                    tone: AppStatusTone.info,
                    icon: Icons.badge_outlined,
                  ),
                  if (widget.patient.isActive)
                    const StatusChip(
                      label: 'Ativo',
                      tone: AppStatusTone.completed,
                      icon: Icons.check_circle_outline,
                    )
                  else
                    const StatusChip(
                      label: 'Inativo',
                      tone: AppStatusTone.warning,
                      icon: Icons.pause_circle_outline,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (updateState.hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: MaterialBanner(
                    content: Text(_saveError(updateState.error)),
                    actions: [
                      TextButton(
                        onPressed: () => ref.invalidate(updatePatientProvider),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),

              const _SectionHeader('Dados pessoais'),
              const SizedBox(height: 12),

              _nameField(_outline),
              const SizedBox(height: 16),

              _phoneField(_outline),
              const SizedBox(height: 16),

              // Birth date picker
              _birthDateField(_outline, theme, loc),
              const SizedBox(height: 16),

              _genderField(),
              const SizedBox(height: 16),

              _relationshipField(),
              const SizedBox(height: 16),

              _educationField(),
              const SizedBox(height: 16),

              _occupationField(_outline),
              const SizedBox(height: 24),

              const _SectionHeader('Origem'),
              const SizedBox(height: 12),

              _stateBirthField(_outline),
              const SizedBox(height: 16),

              _countryBirthField(_outline),
              const SizedBox(height: 24),

              const _SectionHeader('Diversidade'),
              const SizedBox(height: 12),

              _religionField(_outline),
              const SizedBox(height: 16),

              _ethnicField(_outline),
              const SizedBox(height: 16),

              _sexualField(),
              const SizedBox(height: 16),

              _childrenField(),
              const SizedBox(height: 24),

              if (widget.role == ProfileRole.platformAdmin ||
                  widget.role == ProfileRole.psychologist) ...[
                const _SectionHeader('Responsabilidade'),
                const SizedBox(height: 12),
                _responsibleField(psychologistsAsync),
                const SizedBox(height: 24),
              ],

              if (widget.role == ProfileRole.platformAdmin ||
                  widget.role == ProfileRole.psychologist) ...[
                PatientAccessSection(patient: widget.patient),
                const SizedBox(height: 24),
              ],

              FilledButton(
                onPressed: updateState.isLoading ? null : _submit,
                child: updateState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar alterações'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.decoration,
  });

  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  /// Substitui a decoração do celular (desktop: rótulo acima).
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    // Pacientes antigos podem ter o valor gravado em português ou num formato
    // que não existe mais entre as opções. O DropdownButtonFormField lança
    // assertion quando o valor selecionado não está na lista, então o valor
    // salvo é acrescentado como opção — assim ele continua visível e o
    // psicólogo pode trocá-lo por um dos valores atuais.
    final effectiveItems = [...items];
    final hasValue =
        value != null && effectiveItems.any((item) => item.value == value);
    if (value != null && !hasValue) {
      effectiveItems.add(
        DropdownMenuItem<T>(value: value, child: Text('$value')),
      );
    }

    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: decoration ??
          InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
      items: effectiveItems,
      onChanged: onChanged,
    );
  }
}

class _PsychologistDropdown extends StatelessWidget {
  const _PsychologistDropdown({
    required this.psychologists,
    required this.selectedId,
    required this.onChanged,
    this.decoration,
  });

  final InputDecoration? decoration;

  final List<PsychologistOption> psychologists;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedId,
      decoration: decoration ??
          const InputDecoration(
            labelText: 'Psicólogo responsável',
            border: OutlineInputBorder(),
          ),
      items: psychologists
          .map(
            (p) => DropdownMenuItem(
              value: p.id,
              child: Text(p.fullName),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

/// Seção "Acesso do paciente": troca o e-mail de login e/ou define nova senha.
/// Só aparece para a equipe (a página decide). Tem formulário e botão próprios,
/// separados do "Salvar alterações" dos dados pessoais.
class PatientAccessSection extends ConsumerStatefulWidget {
  const PatientAccessSection({
    super.key,
    required this.patient,
    this.desktop = false,
  });

  final Patient patient;

  /// Campos com rótulo acima, em 2 colunas.
  final bool desktop;

  @override
  ConsumerState<PatientAccessSection> createState() =>
      _PatientAccessSectionState();
}

class _PatientAccessSectionState extends ConsumerState<PatientAccessSection> {
  static final _emailRe = RegExp(r'^[^\s@*,]+@[^\s@*,]+\.[^\s@*,]+$');

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// E-mail de login atual, atualizado após cada troca com sucesso (o
  /// `widget.patient` não muda sozinho, então duas trocas seguidas, A→B e B→A,
  /// precisam comparar com este valor).
  late String _currentEmail;

  bool _saving = false;
  String? _error;
  String? _done;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.patient.email ?? '');
    _currentEmail = _normalized(widget.patient.email);
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _normalized(String? v) => (v ?? '').trim().toLowerCase();

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _done = null;
    });
    if (!_formKey.currentState!.validate()) return;

    final newEmail = _normalized(_email.text);
    final emailChanged = newEmail.isNotEmpty && newEmail != _currentEmail;
    final password = _password.text;
    if (!emailChanged && password.isEmpty) {
      setState(() => _error = 'Informe um novo e-mail ou uma nova senha.');
      return;
    }

    // Capturados antes do await: a tela pode ser fechada durante o envio e o
    // servidor já pode ter alterado o acesso, então o cache precisa ser
    // invalidado mesmo assim.
    final repo = ref.read(patientsRepositoryProvider);
    final container = ProviderScope.containerOf(context, listen: false);
    final patientId = widget.patient.id;

    setState(() => _saving = true);
    try {
      await repo.updatePatientCredentials(
        UpdatePatientCredentialsRequest(
          patientId: patientId,
          email: emailChanged ? newEmail : null,
          password: password.isEmpty ? null : password,
        ),
      );
      if (emailChanged) _currentEmail = newEmail;
      container.invalidate(patientDetailProvider(patientId));
      container.invalidate(patientsListProvider);
      if (!mounted) return;
      _password.clear();
      _confirm.clear();
      setState(() {
        _saving = false;
        _done = 'Acesso do paciente atualizado.';
      });
    } catch (e) {
      // Estado parcial (login trocado, ficha não): o cache também muda.
      container.invalidate(patientDetailProvider(patientId));
      container.invalidate(patientsListProvider);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error =
            e is AppException ? e.message : 'Erro ao salvar. Tente novamente.';
      });
    }
  }

  static const _noAccount = 'Este paciente ainda não aceitou o convite. '
      'Reenvie o convite com o e-mail correto.';

  static const _emailWarning =
      'O paciente passará a entrar com o novo e-mail. '
      'O e-mail da ficha também será trocado. '
      'Quem já estiver conectado continua até sair do app.';

  Widget _desktop(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    InputDecoration deco(String label, {String? helper, Widget? suffix}) =>
        desktopFieldDecoration(context, helper: helper, suffix: suffix);
    Widget labeled(String label, Widget field) =>
        DaLabeled(label, child: field);
    Widget box(String text, Color color) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text, style: daText(context, t)),
        );

    if (widget.patient.profileId == null) {
      return DesktopFormSection(
        title: 'Acesso do paciente',
        child: box(_noAccount, t.hov),
      );
    }
    return Form(
      key: _formKey,
      child: DesktopFormSection(
        title: 'Acesso do paciente',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            box(_emailWarning, t.sel),
            const SizedBox(height: 14),
            DesktopFormGrid(children: [
              labeled('E-mail de acesso', _emailField(deco)),
            ]),
            const SizedBox(height: 14),
            DesktopFormGrid(children: [
              labeled('Nova senha', _passwordField(deco)),
              labeled('Confirmar nova senha', _confirmField(deco)),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: daText(context, t, color: t.err)),
            ],
            if (_done != null) ...[
              const SizedBox(height: 12),
              Text(_done!, style: daText(context, t)),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: DaButton(
                label: 'Atualizar acesso',
                onPressed: _saving ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emailField(_Deco deco) => TextFormField(
    controller: _email,
    decoration: deco('E-mail de acesso'),
    keyboardType: TextInputType.emailAddress,
    autocorrect: false,
    validator: (v) {
      final t = (v ?? '').trim();
      if (t.isEmpty) return null;
      return _emailRe.hasMatch(t) ? null : 'E-mail inválido';
    },
  );

  Widget _passwordField(_Deco deco) => TextFormField(
    controller: _password,
    decoration: deco('Nova senha', helper: 'De 8 a 72 caracteres.'),
    obscureText: true,
    enableSuggestions: false,
    autocorrect: false,
    validator: (v) {
      final t = v ?? '';
      if (t.isEmpty) return null;
      if (t.length < 8 || t.length > 72) {
        return 'A senha deve ter de 8 a 72 caracteres';
      }
      return null;
    },
  );

  Widget _confirmField(_Deco deco) => TextFormField(
    controller: _confirm,
    decoration: deco('Confirmar nova senha'),
    obscureText: true,
    enableSuggestions: false,
    autocorrect: false,
    validator: (v) =>
        (v ?? '') == _password.text ? null : 'As senhas não são iguais',
  );

  @override
  Widget build(BuildContext context) {
    if (widget.desktop) return _desktop(context);
    final theme = Theme.of(context);
    final header = const _SectionHeader('Acesso do paciente');

    if (widget.patient.profileId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Text(
            _noAccount,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(_emailWarning),
          ),
          const SizedBox(height: 16),
          _emailField(_outline),
          const SizedBox(height: 16),
          _passwordField(_outline),
          const SizedBox(height: 16),
          _confirmField(_outline),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
          if (_done != null) ...[
            const SizedBox(height: 12),
            Text(_done!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Atualizar acesso'),
          ),
        ],
      ),
    );
  }
}
