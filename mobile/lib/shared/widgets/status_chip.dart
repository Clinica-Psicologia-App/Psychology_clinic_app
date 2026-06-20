import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum AppStatusTone {
  available,
  inProgress,
  completed,
  development,
  blocked,
  neutral,
  success,
  warning,
  error,
  info,
}

/// Chip de status padronizado com cor semântica e ícone opcional.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: style.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: style.foreground),
            const SizedBox(width: AppSpacing.xxs),
          ] else ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: style.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  static AppStatusTone fromJourneyKey(String key) => switch (key) {
        'completed' => AppStatusTone.completed,
        'inProgress' => AppStatusTone.inProgress,
        'dev' => AppStatusTone.development,
        'blocked' => AppStatusTone.blocked,
        _ => AppStatusTone.available,
      };
}

({Color background, Color foreground, Color border}) _styleFor(
  AppStatusTone tone,
) {
  return switch (tone) {
    AppStatusTone.available => (
        background: const Color(0xFFE0F7F5),
        foreground: AppColors.turquoise,
        border: AppColors.turquoise.withValues(alpha: 0.25),
      ),
    AppStatusTone.inProgress => (
        background: AppColors.infoContainer,
        foreground: AppColors.onInfoContainer,
        border: AppColors.info.withValues(alpha: 0.2),
      ),
    AppStatusTone.completed => (
        background: AppColors.successContainer,
        foreground: AppColors.onSuccessContainer,
        border: AppColors.success.withValues(alpha: 0.2),
      ),
    AppStatusTone.development => (
        background: AppColors.disabledSurface,
        foreground: AppColors.textMuted,
        border: AppColors.border,
      ),
    AppStatusTone.blocked => (
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        border: AppColors.error.withValues(alpha: 0.2),
      ),
    AppStatusTone.success => (
        background: AppColors.successContainer,
        foreground: AppColors.onSuccessContainer,
        border: AppColors.success.withValues(alpha: 0.2),
      ),
    AppStatusTone.warning => (
        background: AppColors.warningContainer,
        foreground: AppColors.onWarningContainer,
        border: AppColors.warning.withValues(alpha: 0.2),
      ),
    AppStatusTone.error => (
        background: AppColors.errorContainer,
        foreground: AppColors.onErrorContainer,
        border: AppColors.error.withValues(alpha: 0.2),
      ),
    AppStatusTone.info => (
        background: AppColors.infoContainer,
        foreground: AppColors.onInfoContainer,
        border: AppColors.info.withValues(alpha: 0.2),
      ),
    AppStatusTone.neutral => (
        background: AppColors.surfaceMuted,
        foreground: AppColors.textSecondary,
        border: AppColors.border,
      ),
  };
}
