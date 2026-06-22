import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'status_chip.dart';
import 'app_motion.dart';

/// List tile padronizado para registros clínicos (problemas, objetivos, etc.).
class ClinicalRecordListTile extends StatelessWidget {
  const ClinicalRecordListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.article_outlined,
    this.accentColor,
    this.statusLabel,
    this.statusTone,
    this.trailing,
    this.onTap,
    this.leading,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? accentColor;
  final String? statusLabel;
  final AppStatusTone? statusTone;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Widget? leading;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? AppColors.cyan;

    return MotionSurface(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mdAll,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: dense ? AppSpacing.sm : AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading ??
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: AppRadius.smAll,
                      ),
                      child: Icon(icon, color: accent, size: 20),
                    ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (statusLabel != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        StatusChip(
                          label: statusLabel!,
                          tone: statusTone ?? AppStatusTone.neutral,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  trailing!,
                ] else if (onTap != null)
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
