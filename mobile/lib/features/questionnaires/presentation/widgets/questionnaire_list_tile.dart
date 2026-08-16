import 'package:flutter/material.dart';

import 'package:terapia_esquema/shared/widgets/clay_card.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../domain/questionnaire.dart';
import '../../domain/questionnaire_patient_status.dart';
import '../../domain/reference_period.dart';

class QuestionnaireListTile extends StatelessWidget {
  const QuestionnaireListTile({
    super.key,
    required this.questionnaire,
    required this.onTap,
    this.enabled = true,
    this.showStaffDetails = false,
    this.patientStatus,
  });

  final Questionnaire questionnaire;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showStaffDetails;
  final QuestionnairePatientStatus? patientStatus;

  Color _headerColor() {
    if (!enabled) return AppColors.disabledSurface;
    return switch (patientStatus) {
      QuestionnairePatientStatus.completed => AppColors.successContainer,
      QuestionnairePatientStatus.draft => AppColors.warningContainer,
      _ => AppColors.surfaceTintBlue,
    };
  }

  Color _iconColor() {
    if (!enabled) return AppColors.disabled;
    return switch (patientStatus) {
      QuestionnairePatientStatus.completed => AppColors.success,
      QuestionnairePatientStatus.draft => AppColors.warning,
      _ => AppColors.moduleQuestionnaires,
    };
  }

  IconData _headerIcon() {
    return switch (patientStatus) {
      QuestionnairePatientStatus.completed => Icons.check_circle_outline,
      QuestionnairePatientStatus.draft => Icons.edit_note_outlined,
      _ => Icons.assignment_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final chips = <Widget>[
      if (questionnaire.referencePeriod != ReferencePeriod.unspecified)
        _MetaChip(
          icon: Icons.schedule_outlined,
          label: _referencePeriodLabel(questionnaire.referencePeriod),
        ),
      if (questionnaire.isParentalStyles)
        const _MetaChip(
          icon: Icons.family_restroom_outlined,
          label: 'Mãe e pai',
        ),
      _MetaChip(
        icon: questionnaire.isClinicallyApproved
            ? Icons.verified_outlined
            : Icons.science_outlined,
        label: questionnaire.clinicalStatus.label,
      ),
      if (showStaffDetails)
        _MetaChip(icon: Icons.tag_outlined, label: questionnaire.code),
      if (showStaffDetails &&
          questionnaire.authorName != null &&
          questionnaire.authorName!.trim().isNotEmpty)
        _MetaChip(
          icon: Icons.person_outline,
          label: questionnaire.authorName!,
        ),
      if (showStaffDetails &&
          questionnaire.instrumentVersion != null &&
          questionnaire.instrumentVersion!.trim().isNotEmpty)
        _MetaChip(
          icon: Icons.label_outline,
          label: questionnaire.instrumentVersion!,
        ),
    ];

    final hasDescription = questionnaire.description != null &&
        questionnaire.description!.trim().isNotEmpty;
    final hasLicenseNote = showStaffDetails &&
        questionnaire.licenseNotes != null &&
        questionnaire.licenseNotes!.trim().isNotEmpty;
    final hasBody = hasDescription || chips.isNotEmpty || hasLicenseNote;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── cabeçalho tonal ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _headerColor(),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // avatar branco com ícone colorido
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(_headerIcon(), size: 17, color: _iconColor()),
                  ),
                  const SizedBox(width: 10),
                  // nome + badge de status abaixo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          questionnaire.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            height: 1.3,
                          ),
                        ),
                        if (patientStatus ==
                            QuestionnairePatientStatus.draft) ...[
                          const SizedBox(height: 4),
                          const _StatusBadge(
                            label: 'Em andamento',
                            fg: AppColors.onWarningContainer,
                          ),
                        ] else if (patientStatus ==
                            QuestionnairePatientStatus.completed) ...[
                          const SizedBox(height: 4),
                          const _StatusBadge(
                            label: 'Concluído',
                            fg: AppColors.onSuccessContainer,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // chevron ou cadeado
                  if (enabled)
                    const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted)
                  else
                    const Icon(Icons.lock_outline,
                        size: 16, color: AppColors.disabled),
                ],
              ),
            ),

            // ── corpo ────────────────────────────────────────────
            if (hasBody)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasDescription) ...[
                      Text(
                        questionnaire.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chips.isNotEmpty || hasLicenseNote)
                        const SizedBox(height: 8),
                    ],
                    if (chips.isNotEmpty)
                      Wrap(spacing: 6, runSpacing: 6, children: chips),
                    if (hasLicenseNote) ...[
                      if (chips.isNotEmpty) const SizedBox(height: 6),
                      Text(
                        questionnaire.licenseNotes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: questionnaire.hasLicensePendingValidation
                              ? colors.error
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Badge inline no cabeçalho: fundo branco semi-transparente para destacar
/// sobre a cor tonal do cabeçalho.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.fg});

  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: .25), width: .8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: .1,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.moduleQuestionnaires),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

String _referencePeriodLabel(ReferencePeriod period) {
  return switch (period) {
    ReferencePeriod.lastMonth => 'Último mês',
    ReferencePeriod.lastYear => 'Últimos 12 meses',
    ReferencePeriod.lifetime => 'História de vida',
    ReferencePeriod.unspecified => 'Sem período',
  };
}
