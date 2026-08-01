import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/patient.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientListTile extends StatelessWidget {
  const PatientListTile({
    super.key,
    required this.patient,
    required this.onTap,
  });

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final psychologist = patient.responsiblePsychologistName ?? 'Não informado';
    final status =
        patient.isActive ? patient.accessStatus?.label : 'Paciente inativo';
    final avatarColor = patient.isActive
        ? AppColors.blue.withValues(alpha: 0.12)
        : AppColors.surfaceMuted;
    final avatarTextColor =
        patient.isActive ? AppColors.navy : AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: MotionSurface(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: ClayCard(
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.lgAll,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: avatarColor,
                    child: Text(
                      _initials(patient.fullName),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: avatarTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.fullName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        if (patient.email != null && patient.email!.isNotEmpty)
                          Text(
                            patient.email!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Psicólogo: $psychologist',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (status != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          StatusChip(
                            label: status,
                            tone: !patient.isActive
                                ? AppStatusTone.warning
                                : patient.accessStatus ==
                                        PatientAccessStatus.active
                                    ? AppStatusTone.success
                                    : AppStatusTone.neutral,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: AppColors.blue,
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

  /// Primeira letra do primeiro e do último nome (ex.: "Maria Souza" → "MS").
  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
