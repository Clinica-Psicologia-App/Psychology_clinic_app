import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/brazil_validators.dart';
import '../../../shared/utils/input_formatters.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_shell.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_form.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../../patients/domain/psychologist_option.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../domain/create_patient_invitation_request.dart';
import '../domain/patient_invitation_draft.dart';
import '../providers/patient_invitations_providers.dart';
import 'patient_invitation_routes.dart';
import '../../../shared/widgets/brand_loading.dart';

class CreatePatientInvitationPage extends ConsumerStatefulWidget {
  const CreatePatientInvitationPage({
    super.key,
    required this.role,
    this.draft,
    this.embedded = false,
  });

  final ProfileRole role;
  final PatientInvitationDraft? draft;

  /// Dentro do painel lateral do desktop (sem barra própria).
  final bool embedded;

  @override
  ConsumerState<CreatePatientInvitationPage> createState() =>
      _CreatePatientInvitationPageState();
}

/// Decoração de um campo: a do celular leva o rótulo dentro; a de desktop, não.
typedef _Deco = InputDecoration Function(String label);

InputDecoration _outline(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    );

const _intro =
    'Envie um convite para o paciente criar a senha e completar os dados no primeiro acesso.';
const _dataHelp =
    'O e-mail é obrigatório. Nome e telefone ajudam na identificação antes do aceite.';
const _responsibleHelp =
    'O convite será vinculado ao psicólogo responsável pelo acompanhamento.';

class _CreatePatientInvitationPageState
    extends ConsumerState<CreatePatientInvitationPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  String? _selectedPsychologistId;
  bool _submitting = false;

  bool get _isAdmin => false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.draft?.fullName);
    _emailController = TextEditingController(text: widget.draft?.email);
    _phoneController = TextEditingController(text: widget.draft?.phone);
    _selectedPsychologistId = widget.draft?.responsiblePsychologistId;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final psychologistsAsync = _isAdmin
        ? ref.watch(psychologistsOptionsProvider)
        : const AsyncValue<List<PsychologistOption>>.data([]);

    if (widget.role == ProfileRole.psychologist) {
      if (widget.embedded) return _panel(context, profile);
      if (inDesktopPsychologistShell(context)) {
        return _desktopPage(context, profile);
      }
    }

    return AppScaffold(
      title: 'Convidar paciente',
      accent: AppColors.blue,
      body: Form(
        key: _formKey,
        child: MotionReveal(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xxl,
            ),
            children: [
              const AppPageHeader(
                icon: Icons.mark_email_unread_outlined,
                title: 'Convidar paciente',
                subtitle: _intro,
                metadata: [
                  StatusChip(
                    label: 'Senha pelo paciente',
                    tone: AppStatusTone.info,
                    icon: Icons.lock_reset_outlined,
                  ),
                  StatusChip(
                    label: 'Cadastro assistido',
                    tone: AppStatusTone.neutral,
                    icon: Icons.assignment_ind_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Dados do convite',
                subtitle: _dataHelp,
              ),
              const SizedBox(height: AppSpacing.sm),
              _nameField(_outline),
              const SizedBox(height: AppSpacing.md),
              _emailField(_outline),
              const SizedBox(height: AppSpacing.md),
              _phoneField(_outline),
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Responsável clínico',
                subtitle: _responsibleHelp,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_isAdmin)
                psychologistsAsync.when(
                  loading: () => const BrandLoader(),
                  error: (_, __) => const Text(
                    'Não foi possível carregar os psicólogos.',
                  ),
                  data: (options) => DropdownButtonFormField<String>(
                    initialValue: _selectedPsychologistId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Psicólogo responsável *',
                      border: OutlineInputBorder(),
                    ),
                    items: options
                        .map(
                          (option) => DropdownMenuItem<String>(
                            value: option.id,
                            child: Text(
                              option.displayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPsychologistId = value),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Selecione o psicólogo responsável'
                        : null,
                  ),
                )
              else
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.psychology_outlined),
                  title: const Text('Psicólogo responsável'),
                  subtitle: Text(profile?.fullName ?? 'Não identificado'),
                ),
              const SizedBox(height: AppSpacing.lg),
              if (ref.watch(createPatientInvitationProvider).hasError)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _errorBanner(context),
                ),
              FilledButton.icon(
                onPressed:
                    _submitting ? null : () => _submit(profileId: profile?.id),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_unread_outlined),
                label: const Text('Gerar convite'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Erro do envio, com a mesma mensagem nas duas telas.
  Widget _errorBanner(BuildContext context) {
    final error = ref.watch(createPatientInvitationProvider).error;
    return buildErrorBanner(
      ScaffoldMessenger.of(context),
      context,
      error is AppException
          ? error
          : AppException(
              code: AppExceptionCodes.unknown,
              message: 'Não foi possível criar o convite.',
            ),
    );
  }

  // ── Desktop (>= 768 px, psicóloga) ────────────────────────────────────────

  /// Etiquetas, dados do convite e responsável (painel e página).
  List<Widget> _desktopSections(BuildContext context, UserProfile? profile,
      {bool autofocus = false}) {
    final t = DesktopAdminTokens.of(context);
    InputDecoration deco(String label) => desktopFieldDecoration(context);
    Widget labeled(String label, Widget field) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DaLabeled(label, child: field),
        );
    List<Widget> heading(String title, String help) => [
          Semantics(
            header: true,
            child: Text(title,
                style: daText(context, t, size: 14.5, weight: FontWeight.w600)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 14),
            child:
                Text(help, style: daText(context, t, size: 12.5, color: t.tx2)),
          ),
        ];

    return [
      Text(_intro, style: daText(context, t, color: t.tx2)),
      const SizedBox(height: 12),
      DesktopFormTags(children: [
        DaTag.az(context, 'Senha pelo paciente',
            icon: Icons.lock_reset_outlined),
        const DaTag('Cadastro assistido', icon: Icons.assignment_ind_outlined),
      ]),
      const SizedBox(height: 22),
      ...heading('Dados do convite', _dataHelp),
      labeled('Nome', _nameField(deco, autofocus: autofocus)),
      labeled('E-mail *', _emailField(deco)),
      labeled('Telefone', _phoneField(deco)),
      const SizedBox(height: 10),
      ...heading('Responsável clínico', _responsibleHelp),
      Row(
        children: [
          const DaIconBox(Icons.psychology_outlined,
              color: DesktopAdminTokens.cyan, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Psicólogo responsável',
                    style: daText(context, t, weight: FontWeight.w600)),
                Text(profile?.fullName ?? 'Não identificado',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t, size: 12.5, color: t.tx2)),
              ],
            ),
          ),
        ],
      ),
      if (ref.watch(createPatientInvitationProvider).hasError) ...[
        const SizedBox(height: 16),
        _errorBanner(context),
      ],
    ];
  }

  Widget _generateButton(UserProfile? profile, {bool expand = false}) =>
      DaButton(
        label: 'Gerar convite',
        icon: Icons.mark_email_unread_outlined,
        kind: DaButtonKind.primary,
        expand: expand,
        onPressed: _submitting ? null : () => _submit(profileId: profile?.id),
      );

  /// Conteúdo do painel lateral: campos rolando e o botão no pé.
  Widget _panel(BuildContext context, UserProfile? profile) {
    final t = DesktopAdminTokens.of(context);
    return PopScope(
      // Gerando o link, o painel não fecha: o link só aparece uma vez.
      canPop: !_submitting,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Theme(
                data: desktopFieldTheme(context),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children:
                        _desktopSections(context, profile, autofocus: true),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
              decoration:
                  BoxDecoration(border: Border(top: BorderSide(color: t.bd))),
              child: Row(
                children: [
                  if (_submitting) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: t.tq),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(child: _generateButton(profile, expand: true)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aberta por endereço próprio ("Convidar" em Pacientes e na ficha).
  Widget _desktopPage(BuildContext context, UserProfile? profile) =>
      DesktopPsychologistFrame(
        title: 'Convidar paciente',
        crumbs: [
          DaCrumb('Convites', PatientInvitationRoutes.list(widget.role)),
        ],
        body: Form(
          key: _formKey,
          child: DesktopFormBody(
            busy: _submitting,
            actions: [_generateButton(profile)],
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Builder(
                    builder: (context) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _desktopSections(context, profile),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  // ── Campos (celular e desktop) ────────────────────────────────────────────

  Widget _nameField(_Deco deco, {bool autofocus = false}) => TextFormField(
        controller: _fullNameController,
        decoration: deco('Nome'),
        textCapitalization: TextCapitalization.words,
        autofocus: autofocus,
      );

  Widget _emailField(_Deco deco) => TextFormField(
        controller: _emailController,
        decoration: deco('E-mail *'),
        keyboardType: TextInputType.emailAddress,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.none,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Informe o e-mail';
          }
          if (!value.contains('@')) return 'E-mail inválido';
          return null;
        },
      );

  Widget _phoneField(_Deco deco) => TextFormField(
        controller: _phoneController,
        decoration: deco('Telefone'),
        keyboardType: TextInputType.phone,
        inputFormatters: [BrazilPhoneInputFormatter()],
        validator: validateOptionalPhone,
      );

  Future<void> _submit({required String? profileId}) async {
    if (!_formKey.currentState!.validate()) return;

    final responsiblePsychologistId =
        _isAdmin ? _selectedPsychologistId : profileId;
    if (responsiblePsychologistId == null ||
        responsiblePsychologistId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o psicólogo responsável.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final result =
          await ref.read(createPatientInvitationProvider.notifier).submit(
                CreatePatientInvitationRequest(
                  email: _emailController.text,
                  fullName: _fullNameController.text,
                  phone: _phoneController.text,
                  responsiblePsychologistId: responsiblePsychologistId,
                ),
              );
      if (!mounted) return;
      if (widget.embedded) {
        // O painel é um diálogo, fora das rotas.
        setState(() => _submitting = false);
        Navigator.of(context).pop(result);
        return;
      }
      context.pop(result);
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
