import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../clinical_reports/presentation/clinical_report_routes.dart';
import '../../patient_invitations/domain/patient_invitation_draft.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/future_modules_section.dart';
import 'widgets/patient_avatar.dart';
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
      actions: [
        if (role == ProfileRole.psychologist ||
            role == ProfileRole.platformAdmin)
          asyncPatient.whenOrNull(
                data: (patient) => patient != null
                    ? IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar paciente',
                        onPressed: () => context.push(
                          PatientRoutes.edit(role, patientId),
                          extra: patient,
                        ),
                      )
                    : null,
              ) ??
              const SizedBox.shrink(),
      ],
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

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

class _PatientDetailsBody extends StatelessWidget {
  const _PatientDetailsBody({required this.patient, required this.role});

  final Patient patient;
  final ProfileRole role;

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context);

    final contactRows = <Widget>[
      if (patient.email?.isNotEmpty ?? false)
        _FieldRow(
          icon: Icons.alternate_email_rounded,
          label: 'E-mail',
          value: patient.email!,
        ),
      if (patient.phone?.isNotEmpty ?? false)
        _SensitiveFieldRow(
          icon: Icons.phone_outlined,
          label: 'Telefone',
          value: patient.phone!,
          maskedValue: _maskPhone(patient.phone)!,
        ),
      if (patient.cpf?.isNotEmpty ?? false)
        _SensitiveFieldRow(
          icon: Icons.fingerprint,
          label: 'CPF',
          value: patient.cpf!,
          maskedValue: _maskCpf(patient.cpf)!,
        ),
    ];

    final personalRows = <Widget>[
      if (patient.birthDate != null)
        _FieldRow(
          icon: Icons.cake_outlined,
          label: 'Data de nascimento',
          value: dateFormat.formatFullDate(patient.birthDate!),
        ),
      if (patient.displayRelationshipStatus != null)
        _FieldRow(
          label: 'Estado civil',
          value: patient.displayRelationshipStatus!,
        ),
      if (patient.displayEducationLevel != null)
        _FieldRow(
          label: 'Escolaridade',
          value: patient.displayEducationLevel!,
        ),
      if (patient.occupation?.isNotEmpty ?? false)
        _FieldRow(label: 'Ocupação', value: patient.occupation!),
      if (_birthPlace(patient) != null)
        _FieldRow(label: 'Naturalidade', value: _birthPlace(patient)!),
      if (patient.religiousOrientation?.isNotEmpty ?? false)
        _FieldRow(
          label: 'Orientação religiosa',
          value: patient.religiousOrientation!,
        ),
      if (patient.displayEthnicGroup != null)
        _FieldRow(label: 'Grupo étnico', value: patient.displayEthnicGroup!),
      if (patient.displaySexualOrientation != null)
        _FieldRow(
          label: 'Orientação sexual',
          value: patient.displaySexualOrientation!,
        ),
      if (patient.hasChildren != null)
        _FieldRow(
          label: 'Filhos',
          value: patient.hasChildren! ? 'Sim' : 'Não',
        ),
    ];

    return MotionReveal(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PatientProfileCard(patient: patient),
          if (contactRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoGroupCard(
              title: 'Contato',
              icon: Icons.contact_page_outlined,
              rows: contactRows,
            ),
          ],
          if (personalRows.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoGroupCard(
              title: 'Dados pessoais',
              icon: Icons.person_outline,
              rows: personalRows,
            ),
          ],
          const SizedBox(height: 16),
          if (role == ProfileRole.psychologist ||
              role == ProfileRole.platformAdmin) ...[
            _PatientLifecycleCard(patient: patient),
            const SizedBox(height: 16),
          ],
          if (role != ProfileRole.platformAdmin &&
              patient.isActive &&
              patient.accessStatus == PatientAccessStatus.noAppAccess) ...[
            ClayCard(
              child: ListTile(
                leading: const Icon(Icons.mark_email_unread_outlined),
                title: const Text('Convidar paciente'),
                subtitle: const Text(
                  'Gerar link para o paciente criar senha e concluir o primeiro acesso.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  PatientRoutes.invitationCreate(role),
                  extra: PatientInvitationDraft(
                    fullName: patient.fullName,
                    email: patient.email,
                    phone: patient.phone,
                    responsiblePsychologistId:
                        patient.responsiblePsychologistId,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (role != ProfileRole.platformAdmin) ...[
            ClayCard(
              child: ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Gerar relatório'),
                subtitle: const Text(
                  'PDF clínico supervisionado (somente equipe).',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(
                  ClinicalReportRoutes.staffOptions(
                    role: role,
                    patientId: patient.id,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FutureModulesSection(role: role, patientId: patient.id),
          ],
          if (role == ProfileRole.platformAdmin) ...[
            const SizedBox(height: 8),
            _PatientDeleteCard(patient: patient),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  String? _birthPlace(Patient patient) {
    final parts = [patient.stateBirth, patient.countryBirth]
        .where((v) => v != null && v.trim().isNotEmpty)
        .cast<String>();
    if (parts.isEmpty) return null;
    return parts.join(' / ');
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

// ---------------------------------------------------------------------------
// Profile hero card
// ---------------------------------------------------------------------------

class _PatientProfileCard extends StatelessWidget {
  const _PatientProfileCard({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final age = _calcAge(patient.birthDate);

    return ClayCard(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tonal header band
          Container(
            color: AppColors.surfaceTintTurquoise,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PatientAvatar(
                  fullName: patient.fullName,
                  gender: patient.gender,
                  size: 68,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        patient.fullName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                          height: 1.2,
                        ),
                      ),
                      if (patient.displayGender != null || age != null) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (patient.displayGender != null)
                              _InfoChip(patient.displayGender!),
                            if (age != null) _InfoChip('$age anos'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Status + attribution strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatusBadge(
                      label: patient.isActive
                          ? 'Cadastro ativo'
                          : 'Cadastro inativo',
                      icon: patient.isActive
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color: patient.isActive
                          ? AppColors.onSuccessContainer
                          : AppColors.onErrorContainer,
                      bgColor: patient.isActive
                          ? AppColors.successContainer
                          : AppColors.errorContainer,
                    ),
                    if (patient.accessStatus != null)
                      _StatusBadge(
                        label: _accessLabel(patient.accessStatus!),
                        icon: _accessIcon(patient.accessStatus!),
                        color: _accessTextColor(patient.accessStatus!),
                        bgColor: _accessBgColor(patient.accessStatus!),
                      ),
                  ],
                ),
                if (patient.responsiblePsychologistName != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.person_pin_circle_outlined,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        patient.responsiblePsychologistName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  int? _calcAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _accessLabel(PatientAccessStatus s) => switch (s) {
        PatientAccessStatus.active => 'App ativo',
        PatientAccessStatus.inactive => 'App inativo',
        PatientAccessStatus.noAppAccess => 'Sem acesso ao app',
      };

  IconData _accessIcon(PatientAccessStatus s) => switch (s) {
        PatientAccessStatus.active => Icons.smartphone_outlined,
        PatientAccessStatus.inactive => Icons.phone_disabled_outlined,
        PatientAccessStatus.noAppAccess => Icons.no_cell_outlined,
      };

  Color _accessBgColor(PatientAccessStatus s) => switch (s) {
        PatientAccessStatus.active => AppColors.infoContainer,
        PatientAccessStatus.inactive => AppColors.warningContainer,
        PatientAccessStatus.noAppAccess => AppColors.surfaceMuted,
      };

  Color _accessTextColor(PatientAccessStatus s) => switch (s) {
        PatientAccessStatus.active => AppColors.onInfoContainer,
        PatientAccessStatus.inactive => AppColors.onWarningContainer,
        PatientAccessStatus.noAppAccess => AppColors.textSecondary,
      };
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.turquoise.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info group card
// ---------------------------------------------------------------------------

class _InfoGroupCard extends StatelessWidget {
  const _InfoGroupCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.turquoise),
                const SizedBox(width: 7),
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.turquoise,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 16, endIndent: 16),
            rows[i],
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Field rows
// ---------------------------------------------------------------------------

class _FieldRow extends StatelessWidget {
  const _FieldRow({this.icon, required this.label, required this.value});

  final IconData? icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 17, color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
          ] else
            const SizedBox(width: 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensitiveFieldRow extends StatefulWidget {
  const _SensitiveFieldRow({
    this.icon,
    required this.label,
    required this.value,
    required this.maskedValue,
  });

  final IconData? icon;
  final String label;
  final String value;
  final String maskedValue;

  @override
  State<_SensitiveFieldRow> createState() => _SensitiveFieldRowState();
}

class _SensitiveFieldRowState extends State<_SensitiveFieldRow> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.icon != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(widget.icon, size: 17, color: AppColors.textMuted),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _revealed ? widget.value : widget.maskedValue,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _revealed = !_revealed),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                _revealed
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lifecycle card (ativar / inativar)
// ---------------------------------------------------------------------------

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
