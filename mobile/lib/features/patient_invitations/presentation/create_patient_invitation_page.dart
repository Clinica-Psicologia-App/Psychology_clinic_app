import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/utils/brazil_validators.dart';
import '../../../shared/utils/input_formatters.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../../patients/domain/psychologist_option.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/create_patient_invitation_request.dart';
import '../domain/patient_invitation_draft.dart';
import '../providers/patient_invitations_providers.dart';

class CreatePatientInvitationPage extends ConsumerStatefulWidget {
  const CreatePatientInvitationPage({
    super.key,
    required this.role,
    this.draft,
  });

  final ProfileRole role;
  final PatientInvitationDraft? draft;

  @override
  ConsumerState<CreatePatientInvitationPage> createState() =>
      _CreatePatientInvitationPageState();
}

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

    return AppScaffold(
      title: 'Convidar paciente',
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
                subtitle:
                    'Envie um convite para o paciente criar a senha e completar os dados no primeiro acesso.',
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
                subtitle:
                    'O e-mail é obrigatório. Nome e telefone ajudam na identificação antes do aceite.',
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.md),
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
              const SizedBox(height: AppSpacing.lg),
              const AppSectionHeader(
                title: 'Responsável clínico',
                subtitle:
                    'O convite será vinculado ao psicólogo responsável pelo acompanhamento.',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (_isAdmin)
                psychologistsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
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
                  child: buildErrorBanner(
                    ScaffoldMessenger.of(context),
                    context,
                    ref.watch(createPatientInvitationProvider).error
                            is AppException
                        ? ref.watch(createPatientInvitationProvider).error
                            as AppException
                        : AppException(
                            code: AppExceptionCodes.unknown,
                            message: 'Não foi possível criar o convite.',
                          ),
                  ),
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
