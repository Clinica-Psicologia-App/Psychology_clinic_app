import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../coach/domain/coach_step.dart';
import '../../coach/domain/coach_tour.dart';
import '../../coach/providers/coach_providers.dart';
import '../../clinical_reports/presentation/clinical_report_routes.dart';
import '../../life_story/presentation/life_story_routes.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../patient_invitations/domain/patient_invitation_draft.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../therapy_goals/presentation/therapy_goal_routes.dart';
import '../domain/patient.dart';
import '../domain/patient_vitals.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/future_modules_section.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';
import '../../../shared/widgets/brand_loading.dart';

class PatientDetailsPage extends ConsumerStatefulWidget {
  const PatientDetailsPage({
    super.key,
    required this.patientId,
    required this.role,
  });

  final String patientId;
  final ProfileRole role;

  @override
  ConsumerState<PatientDetailsPage> createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends ConsumerState<PatientDetailsPage> {
  final _reportKey = GlobalKey();
  final _genogramKey = GlobalKey();
  final _vitalsKey = GlobalKey();
  bool _tourRequested = false;

  bool get _tourEnabled => widget.role == ProfileRole.psychologist;

  CoachTour _tour() => CoachTour(
        id: 'tour_ficha_paciente',
        steps: [
          const CoachStep(
            id: 'intro',
            text:
                'Esta é a ficha completa do paciente. Deixa eu te mostrar os '
                'atalhos clínicos principais.',
            pose: MascotPose.wave,
          ),
          CoachStep(
            id: 'relatorio',
            text:
                'Gere aqui um relatório clínico em PDF, com as seções revisadas '
                'por você antes de compartilhar.',
            pose: MascotPose.point,
            targetKey: _reportKey,
          ),
          CoachStep(
            id: 'genograma',
            text:
                'Abra o Genograma para ver a família, os vínculos e os padrões '
                'que o paciente registrou.',
            pose: MascotPose.point,
            targetKey: _genogramKey,
          ),
          CoachStep(
            id: 'resumo',
            text:
                'O Resumo rápido mostra último check-in, metas ativas e '
                'questionários. Toque em cada número para ir direto ao módulo. 🙂',
            pose: MascotPose.celebrate,
            targetKey: _vitalsKey,
          ),
        ],
      );

  Future<void> _startTour({bool force = false}) async {
    if (!mounted) return;
    await ref
        .read(coachControllerProvider.notifier)
        .startTour(context, _tour(), force: force);
  }

  @override
  Widget build(BuildContext context) {
    final asyncPatient = ref.watch(patientDetailProvider(widget.patientId));

    if (_tourEnabled && !_tourRequested && asyncPatient.hasValue &&
        asyncPatient.value != null) {
      _tourRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
    }

    return AppScaffold(
      title: 'Paciente',
      accent: AppColors.blue,
      actions: _tourEnabled
          ? [
              IconButton(
                tooltip: 'Rever tutorial',
                onPressed: () => _startTour(force: true),
                icon: const Icon(Icons.help_outline_rounded),
              ),
            ]
          : null,
      body: asyncPatient.when(
        loading: () => const BrandLoader(),
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
                      ref.invalidate(patientDetailProvider(widget.patientId)),
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
          return _PatientDetailsBody(
            patient: patient,
            role: widget.role,
            reportKey: _reportKey,
            genogramKey: _genogramKey,
            vitalsKey: _vitalsKey,
          );
        },
      ),
    );
  }
}

class _PatientDetailsBody extends StatelessWidget {
  const _PatientDetailsBody({
    required this.patient,
    required this.role,
    this.reportKey,
    this.genogramKey,
    this.vitalsKey,
  });

  final Patient patient;
  final ProfileRole role;
  final Key? reportKey;
  final Key? genogramKey;
  final Key? vitalsKey;

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
              _InfoRow(
                  icon: Icons.mail_outline,
                  label: 'E-mail',
                  value: patient.email),
              _SensitiveInfoRow(
                icon: Icons.phone_outlined,
                label: 'Telefone',
                value: patient.phone,
                maskedValue: _maskPhone(patient.phone),
              ),
              _SensitiveInfoRow(
                icon: Icons.badge_outlined,
                label: 'CPF',
                value: patient.cpf,
                maskedValue: _maskCpf(patient.cpf),
              ),
              _InfoRow(
                icon: Icons.cake_outlined,
                label: 'Nascimento',
                value: patient.birthDate != null
                    ? dateFormat.formatFullDate(patient.birthDate!)
                    : null,
              ),
              _InfoRow(
                  icon: Icons.wc_outlined,
                  label: 'Gênero',
                  value: patient.displayGender),
              _InfoRow(
                icon: Icons.favorite_border,
                label: 'Estado civil',
                value: patient.displayRelationshipStatus,
              ),
              _InfoRow(
                icon: Icons.school_outlined,
                label: 'Escolaridade',
                value: patient.displayEducationLevel,
              ),
              _InfoRow(
                  icon: Icons.work_outline,
                  label: 'Ocupação',
                  value: patient.occupation),
              _InfoRow(
                  icon: Icons.place_outlined,
                  label: 'Naturalidade',
                  value: _birthPlace(patient)),
              _InfoRow(
                icon: Icons.self_improvement_outlined,
                label: 'Religião',
                value: patient.religiousOrientation,
              ),
              _InfoRow(
                  icon: Icons.groups_outlined,
                  label: 'Grupo étnico',
                  value: patient.displayEthnicGroup),
              _InfoRow(
                icon: Icons.diversity_1_outlined,
                label: 'Orient. sexual',
                value: patient.displaySexualOrientation,
              ),
              _InfoRow(
                icon: Icons.child_care_outlined,
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
              key: reportKey,
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
            const SizedBox(height: AppSpacing.md),
            AppInfoCard(
              key: genogramKey,
              icon: Icons.account_tree_outlined,
              title: 'Genograma',
              body:
                  'Veja a família, os vínculos e os padrões que o paciente registrou.',
              action: IconButton(
                tooltip: 'Abrir genograma',
                onPressed: () => context.push(
                  LifeStoryRoutes.genogramPanel,
                  extra: patient.id,
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _PatientVitalsSummary(
                key: vitalsKey, role: role, patient: patient),
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
      leading: UserAvatar.parts(
        fullName: patient.fullName,
        initials: _initialsOf(patient.fullName),
        role: ProfileRole.patient,
        avatarType: patient.avatarType,
        photoUrl: patient.photoUrl,
        avatarConfig: patient.avatarConfig,
        size: 60,
      ),
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

  /// Iniciais (1–2 letras) para o fallback do avatar, seguindo a mesma regra
  /// de UserProfile.initials.
  static String _initialsOf(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Resumo vital do paciente
// ---------------------------------------------------------------------------

/// Painel de três métricas que dá ao psicólogo um panorama imediato
/// antes de entrar nos módulos: último check-in, metas ativas e
/// questionários em andamento. Cada coluna é tappable.
class _PatientVitalsSummary extends ConsumerWidget {
  const _PatientVitalsSummary(
      {super.key, required this.role, required this.patient});

  final ProfileRole role;
  final Patient patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitalsAsync = ref.watch(patientVitalsProvider(patient.id));

    return vitalsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (vitals) {
        if (vitals == null) return const SizedBox.shrink();
        return _VitalsPanel(role: role, patient: patient, vitals: vitals);
      },
    );
  }
}

class _VitalsPanel extends StatelessWidget {
  const _VitalsPanel({
    required this.role,
    required this.patient,
    required this.vitals,
  });

  final ProfileRole role;
  final Patient patient;
  final PatientVitals vitals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xs,
            ),
            child: Text(
              'Resumo rápido',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _VitalCell(
                    icon: Icons.favorite_border,
                    accent: AppColors.turquoise,
                    label: 'Último check-in',
                    value: vitals.lastCheckinLabel,
                    daysCount: vitals.lastCheckinDays,
                    onTap: () => context.push(
                      PatientCheckInRoutes.staffList(
                        role: role,
                        patientId: patient.id,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 52, color: AppColors.border),
                Expanded(
                  child: _VitalCell(
                    icon: Icons.flag_outlined,
                    accent: AppColors.purple,
                    label: 'Metas ativas',
                    value: '${vitals.activeGoals}',
                    onTap: () => context.push(
                      TherapyGoalRoutes.staffList(
                        role: role,
                        patientId: patient.id,
                      ),
                    ),
                  ),
                ),
                Container(width: 1, height: 52, color: AppColors.border),
                Expanded(
                  child: _VitalCell(
                    icon: Icons.assignment_outlined,
                    accent: AppColors.blue,
                    label: 'Questionários',
                    value: vitals.pendingQuestionnaires == 0
                        ? 'Em dia'
                        : '${vitals.pendingQuestionnaires} pend.',
                    highlight: vitals.pendingQuestionnaires > 0,
                    onTap: () => context.push(
                      QuestionnaireRoutes.list(
                        role: role,
                        patientId: patient.id,
                      ),
                    ),
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

class _VitalCell extends StatelessWidget {
  const _VitalCell({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.onTap,
    this.daysCount,
    this.highlight = false,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;
  final VoidCallback onTap;
  final int? daysCount;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent = highlight ? AppColors.warning : accent;

    // Anima o número para dar vida ao painel sem pesar.
    Widget valueWidget;
    final numericValue = int.tryParse(value.replaceAll(RegExp(r'\D'), ''));
    if (numericValue != null && !highlight) {
      final duration = AppAnimations.resolve(
        context,
        const Duration(milliseconds: 320),
      );
      valueWidget = TweenAnimationBuilder<int>(
        duration: duration,
        tween: IntTween(begin: 0, end: numericValue),
        builder: (_, v, __) => Text(
          value.replaceAll(RegExp(r'\d+'), '$v'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    } else {
      valueWidget = Text(
        value,
        style: theme.textTheme.titleMedium?.copyWith(
          color: highlight ? effectiveAccent : AppColors.navy,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Semantics(
      button: true,
      label: '$label: $value',
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: effectiveAccent),
              const SizedBox(height: 4),
              valueWidget,
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  const _InfoRow({
    required this.label,
    required this.value,
    this.icon = Icons.info_outline,
  });

  final String label;
  final String? value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return _InfoRowLayout(
      icon: icon,
      label: label,
      value: Text(
        value!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }
}

/// Layout base de uma linha de dado: ícone + rótulo + valor (à direita).
class _InfoRowLayout extends StatelessWidget {
  const _InfoRowLayout({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: AppColors.cyan),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: value,
            ),
          ),
          if (trailing != null) trailing!,
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
    this.icon = Icons.lock_outline,
  });

  final String label;
  final String? value;
  final String? maskedValue;
  final IconData icon;

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

    return _InfoRowLayout(
      icon: widget.icon,
      label: widget.label,
      value: Text(
        _revealed ? widget.value! : widget.maskedValue!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w500,
              letterSpacing: _revealed ? 0 : 1.5,
            ),
      ),
      trailing: IconButton(
        visualDensity: VisualDensity.compact,
        tooltip:
            _revealed ? 'Ocultar ${widget.label}' : 'Mostrar ${widget.label}',
        onPressed: () => setState(() => _revealed = !_revealed),
        icon: Icon(
          _revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: 20,
          color: AppColors.textMuted,
        ),
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
