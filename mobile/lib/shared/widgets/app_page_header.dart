import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'app_motion.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.primaryAction,
    this.secondaryAction,
    this.trailing,
    this.metadata = const [],
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final Widget? trailing;
  final List<Widget> metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MotionReveal(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlAll,
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 620;
            final titleBlock = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  _HeaderIcon(icon: icon!),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: metadata,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final actions = [
              if (secondaryAction != null) secondaryAction!,
              if (primaryAction != null) primaryAction!,
              if (trailing != null) trailing!,
            ];

            if (compact || actions.isEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: actions,
                    ),
                  ],
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: AppSpacing.md),
          action!,
        ],
      ],
    );
  }
}

class AppInfoCard extends StatelessWidget {
  const AppInfoCard({
    super.key,
    required this.title,
    this.body,
    this.icon,
    this.tone = AppInfoCardTone.neutral,
    this.child,
    this.action,
  });

  final String title;
  final String? body;
  final IconData? icon;
  final AppInfoCardTone tone;
  final Widget? child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final style = _infoStyle(tone);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: style.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: style.foreground.withValues(alpha: 0.1),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(icon, color: style.foreground, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (body != null && body!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
                if (child != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  child!,
                ],
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

enum AppInfoCardTone { neutral, info, success, warning, error }

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.1),
        borderRadius: AppRadius.lgAll,
      ),
      child: Icon(icon, color: AppColors.turquoise, size: 26),
    );
  }
}

({Color background, Color foreground, Color border}) _infoStyle(
  AppInfoCardTone tone,
) {
  return switch (tone) {
    AppInfoCardTone.info => (
        background: AppColors.infoContainer.withValues(alpha: 0.5),
        foreground: AppColors.info,
        border: AppColors.info.withValues(alpha: 0.18),
      ),
    AppInfoCardTone.success => (
        background: AppColors.successContainer.withValues(alpha: 0.5),
        foreground: AppColors.success,
        border: AppColors.success.withValues(alpha: 0.18),
      ),
    AppInfoCardTone.warning => (
        background: AppColors.warningContainer.withValues(alpha: 0.55),
        foreground: AppColors.warning,
        border: AppColors.warning.withValues(alpha: 0.2),
      ),
    AppInfoCardTone.error => (
        background: AppColors.errorContainer.withValues(alpha: 0.55),
        foreground: AppColors.error,
        border: AppColors.error.withValues(alpha: 0.2),
      ),
    AppInfoCardTone.neutral => (
        background: AppColors.surface,
        foreground: AppColors.cyan,
        border: AppColors.border,
      ),
  };
}
