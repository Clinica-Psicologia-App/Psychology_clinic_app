import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_severity.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/severity_indicator.dart';
import '../../domain/clinical_dashboard_score_row.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Seção expansível do dashboard clínico com animação suave.
class ExpandableDashboardSection extends StatefulWidget {
  const ExpandableDashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.initiallyExpanded = true,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;
  final bool initiallyExpanded;
  final EdgeInsets margin;

  @override
  State<ExpandableDashboardSection> createState() =>
      _ExpandableDashboardSectionState();
}

class _ExpandableDashboardSectionState
    extends State<ExpandableDashboardSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = AppAnimations.resolve(context, AppAnimations.section);

    return ClayCard(
      margin: widget.margin,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: AppColors.cyan, size: 22),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            widget.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: duration,
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: duration,
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Barra de score animada com paleta EsquemaCore (valores inalterados).
class AnimatedClinicalScoreBar extends StatelessWidget {
  const AnimatedClinicalScoreBar({
    super.key,
    required this.row,
    required this.maxScore,
    this.rank,
  });

  final ClinicalDashboardScoreRow row;
  final double maxScore;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeMax = maxScore > 0 ? maxScore : 1.0;
    final fraction = (row.score / safeMax).clamp(0.0, 1.0);
    final duration = AppAnimations.resolve(context, AppAnimations.bar);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        label: '${row.name}, score ${row.score.toStringAsFixed(2)}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rank != null) ...[
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        AppColors.turquoise.withValues(alpha: 0.15),
                    child: Text(
                      '$rank',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.turquoise,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (row.code.isNotEmpty)
                        Text(
                          row.code,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  row.score.toStringAsFixed(2),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TweenAnimationBuilder<double>(
              duration: duration,
              curve: AppAnimations.standardCurve,
              tween: Tween(begin: 0, end: fraction),
              builder: (context, value, _) {
                return ClipRRect(
                  borderRadius: AppRadius.smAll,
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: _barColor(theme, row),
                  ),
                );
              },
            ),
            if (row.hasSeverity)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: SeverityBadge.fromColorKey(
                  row.severityColorKey,
                  label: row.severityLabel,
                  compact: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _barColor(ThemeData theme, ClinicalDashboardScoreRow row) {
    final severity = AppSeverity.fromColorKey(row.severityColorKey);
    return severity.hasSeverity ? severity.color : AppColors.cyan;
  }
}
