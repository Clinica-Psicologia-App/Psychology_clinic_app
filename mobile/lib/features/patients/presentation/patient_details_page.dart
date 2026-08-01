import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../clinical_reports/presentation/clinical_report_routes.dart';
import '../../patient_invitations/domain/patient_invitation_draft.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/future_modules_section.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientDetailsPage extends ConsumerWidget {
  const PatientDetailsPage({
    super.key,
    required this.patientId,
    required this.role,
  });

  final String patientId;
  final ProfileRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatient = ref.watch(patientDetailProvider(patientId));

    return AppScaffold(
      title: 'Paciente',
      body: asyncPatient.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar o paciente.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(patientDetailProvider(patientId)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Paciente não encontrado.'));
          }
          return _PatientDetailsBody(patient: patient, role: role);
        },
      ),
    );
  }
}

class _PatientDetailsBody extends StatelessWidget {
  const _PatientDetailsBody({
    required this.patient,
    required this.role,
  });

  final Patient patient;
  final ProfileRole role;

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context);

    return MotionReveal(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _PatientHeader(
            patient: patient,
            role: role,
            onEdit: role == ProfileRole.psychologist ||
                    role == ProfileRole.platformAdmin
                ? () => context.push(
                      PatientRoutes.edit(role, patient.id),
                      extra: patient,
                    )
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _DetailsSectionCard(
            title: 'Dados do paciente',
            subtitle:
                'Informações principais para identificação, contato e contexto clínico.',
            children: [
              _InfoRow(label: 'E-mail', value: patient.email),
              _SensitiveInfoRow(
                label: 'Telefone',
                value: patient.phone,
                maskedValue: _maskPhone(patient.phone),
              ),
              _SensitiveInfoRow(
                label: 'CPF',
                value: patient.cpf,
                maskedValue: _maskCpf(patient.cpf),
              ),
              _InfoRow(
                label: 'Data de nascimento',
                value: patient.birthDate != null
                    ? dateFormat.formatFullDate(patient.birthDate!)
                    : null,
              ),
              _InfoRow(label: 'Gênero', value: patient.displayGender),
              _InfoRow(
                label: 'Estado civil',
                value: patient.displayRelationshipStatus,
              ),
              _InfoRow(
                label: 'Escolaridade',
                value: patient.displayEducationLevel,
              ),
              _InfoRow(label: 'Ocupação', value: patient.occupation),
              _InfoRow(label: 'Naturalidade', value: _birthPlace(patient)),
              _InfoRow(
                label: 'Orientação religiosa',
                value: patient.religiousOrientation,
              ),
              _InfoRow(
                  label: 'Grupo étnico', value: patient.displayEthnicGroup),
              _InfoRow(
                label: 'Orientação sexual',
                value: patient.displaySexualOrientation,
              ),
              _InfoRow(
                label: 'Filhos',
                value: _hasChildrenLabel(patient.hasChildren),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (role == ProfileRole.psychologist ||
              role == ProfileRole.platformAdmin) ...[
            _PatientLifecycleCard(patient: patient),
            const SizedBox(height: AppSpacing.md),
          ],
          if (role != ProfileRole.platformAdmin &&
              patient.isActive &&
              patient.accessStatus == PatientAccessStatus.noAppAccess) ...[
            AppInfoCard(
              icon: Icons.mark_email_unread_outlined,
              title: 'Convidar paciente',
              body:
                  'Gere um link para o paciente criar senha e concluir o primeiro acesso.',
              action: IconButton(
                tooltip: 'Convidar paciente',
                onPressed: () => context.push(
                  PatientRoutes.invitationCreate(role),
                  extra: PatientInvitationDraft(
                    fullName: patient.fullName,
                    email: patient.email,
                    phone: patient.phone,
                    responsiblePsychologistId:
                        patient.responsiblePsychologistId,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (role != ProfileRole.platformAdmin) ...[
            AppInfoCard(
              icon: Icons.picture_as_pdf_outlined,
              title: 'Relatório clínico',
              body: 'Gere um PDF supervisionado com as seções clínicas.',
              tone: AppInfoCardTone.info,
              action: IconButton(
                tooltip: 'Gerar relatório',
                onPressed: () => context.push(
                  ClinicalReportRoutes.staffOptions(
                    role: role,
                    patientId: patient.id,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FutureModulesSection(
              role: role,
              patientId: patient.id,
            ),
          ],
          if (role == ProfileRole.platformAdmin) ...[
            const SizedBox(height: AppSpacing.xs),
            _PatientDeleteCard(patient: patient),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  String? _birthPlace(Patient patient) {
    final parts = [
      patient.stateBirth,
      patient.countryBirth,
    ].where((value) => value != null && value.trim().isNotEmpty).cast<String>();

    if (parts.isEmpty) return null;
    return parts.join(' / ');
  }

  String? _hasChildrenLabel(bool? hasChildren) {
    if (hasChildren == null) return null;
    return hasChildren ? 'Sim' : 'Não';
  }

  static String? _maskCpf(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return '***.***.***-**';
    return '***.***.${digits.substring(6, 9)}-**';
  }

  static String? _maskPhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '••••';
    return '•••••••${digits.substring(digits.length - 4)}';
  }
}

class _PatientHeader extends StatelessWidget {
  const _PatientHeader({
    required this.patient,
    required this.role,
    this.onEdit,
  });

  final Patient patient;
  final ProfileRole role;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final statusTone =
        patient.isActive ? AppStatusTone.success : AppStatusTone.error;
    final accessLabel = patient.accessStatus?.label;

    return AppPageHeader(
      icon: Icons.person_outline,
      title: patient.fullName,
      subtitle: _subtitle,
      metadata: [
        StatusChip(
          label: patient.isActive ? 'Cadastro ativo' : 'Cadastro inativo',
          tone: statusTone,
          icon: patient.isActive
              ? Icons.check_circle_outline
              : Icons.person_off_outlined,
        ),
        if (accessLabel != null && accessLabel.trim().isNotEmpty)
          StatusChip(
            label: accessLabel,
            tone: patient.accessStatus == PatientAccessStatus.active
                ? AppStatusTone.success
                : AppStatusTone.neutral,
            icon: Icons.phone_iphone_outlined,
          ),
        if (patient.responsiblePsychologistName != null &&
            patient.responsiblePsychologistName!.trim().isNotEmpty)
          StatusChip(
            label: patient.responsiblePsychologistName!,
            tone: AppStatusTone.info,
            icon: Icons.psychology_alt_outlined,
          ),
      ],
      primaryAction: onEdit != null
          ? FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar paciente'),
            )
          : null,
    );
  }

  String? get _subtitle {
    if (role == ProfileRole.platformAdmin) {
      return 'Visão administrativa do cadastro, status e histórico preservado.';
    }
    return 'Resumo operacional do paciente e acesso aos módulos clínicos.';
  }
}

class _DetailsSectionCard extends StatelessWidget {
  const _DetailsSectionCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionHeader(title: title, subtitle: subtitle),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PatientLifecycleCard extends ConsumerStatefulWidget {
  const _PatientLifecycleCard({required this.patient});

  final Patient patient;

  @override
  ConsumerState<_PatientLifecycleCard> createState() =>
      _PatientLifecycleCardState();
}

class _PatientLifecycleCardState extends ConsumerState<_PatientLifecycleCard> {
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final isActive = patient.isActive;
    final colors = Theme.of(context).colorScheme;

    return ClayCard(
      color: isActive ? null : colors.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isActive
                      ? Icons.verified_user_outlined
                      : Icons.person_off_outlined,
                  color: isActive ? colors.primary : colors.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isActive ? 'Paciente ativo' : 'Paciente inativo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isActive
                  ? 'A inativação bloqueia o acesso do paciente, mas preserva todo o prontuário e histórico clínico.'
                  : 'O prontuário permanece preservado e disponível para consulta. Reative para restaurar o acesso do paciente.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (isActive)
              OutlinedButton.icon(
                onPressed: _updating ? null : _confirmStatusChange,
                icon: _updating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_off_outlined),
                label: const Text('Inativar paciente'),
              )
            else
              FilledButton.icon(
                onPressed: _updating ? null : _confirmStatusChange,
                icon: _updating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Reativar paciente'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStatusChange() async {
    final patient = widget.patient;
    final willActivate = !patient.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          willActivate ? 'Reativar paciente?' : 'Inativar paciente?',
        ),
        content: Text(
          willActivate
              ? 'O acesso de ${patient.fullName} será restaurado.'
              : 'O acesso de ${patient.fullName} será bloqueado. O prontuário e todo o histórico clínico serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(willActivate ? 'Reativar' : 'Inativar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _updating = true);
    try {
      await ref.read(patientsRepositoryProvider).setPatientActiveStatus(
            patientId: patient.id,
            isActive: willActivate,
          );
      ref.invalidate(patientDetailProvider(patient.id));
      await ref.read(patientsListProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            willActivate
                ? 'Paciente reativado com sucesso.'
                : 'Paciente inativado com sucesso.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) showErrorBanner(context, error);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}

class _SensitiveInfoRow extends StatefulWidget {
  const _SensitiveInfoRow({
    required this.label,
    required this.value,
    required this.maskedValue,
  });

  final String label;
  final String? value;
  final String? maskedValue;

  @override
  State<_SensitiveInfoRow> createState() => _SensitiveInfoRowState();
}

class _SensitiveInfoRowState extends State<_SensitiveInfoRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.value == null || widget.value!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              widget.label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(_revealed ? widget.value! : widget.maskedValue!),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: _revealed
                ? 'Ocultar ${widget.label}'
                : 'Mostrar ${widget.label}',
            onPressed: () => setState(() => _revealed = !_revealed),
            icon: Icon(
              _revealed
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exclusão permanente (platform_admin)
// ---------------------------------------------------------------------------
class _PatientDeleteCard extends ConsumerStatefulWidget {
  const _PatientDeleteCard({required this.patient});

  final Patient patient;

  @override
  ConsumerState<_PatientDeleteCard> createState() => _PatientDeleteCardState();
}

class _PatientDeleteCardState extends ConsumerState<_PatientDeleteCard> {
  bool _deleting = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClayCard(
      color: colors.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.delete_forever_outlined, color: colors.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Zona perigosa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'A exclusão é permanente e irreversível. Todo o histórico clínico, questionários, genograma e demais registros serão apagados.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error),
              ),
              onPressed: _deleting ? null : _confirmDelete,
              icon: _deleting
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.error,
                      ),
                    )
                  : const Icon(Icons.delete_forever_outlined),
              label: const Text('Excluir paciente definitivamente'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final patient = widget.patient;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir paciente definitivamente?'),
        content: Text(
          'Esta ação apagará permanentemente o cadastro de ${patient.fullName} '
          'e todos os seus dados clínicos (questionários, genograma, monitores, etc.).\n\n'
          'Esta operação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(patientsRepositoryProvider).deletePatient(patient.id);

      if (!mounted) return;
      ref.invalidate(patientsListProvider);
      context.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${patient.fullName} excluído definitivamente.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : 'Erro ao excluir. Tente novamente.',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
