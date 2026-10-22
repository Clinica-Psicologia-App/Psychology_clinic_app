import 'package:flutter/material.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_motion.dart';

/// A stat item shown in the optional glass stats bar of [StaffSectionHeader].
class StaffSectionStat {
  const StaffSectionStat({
    required this.value,
    required this.label,
    this.accent,
  });

  final String value;
  final String label;

  /// Accent colour for the value text. Defaults to near-white when null.
  final Color? accent;
}

/// Public glass action button for use in [StaffSectionHeader.actions].
///
/// Mirrors the private `_GlassButton` used inside [_PatientsHeader].
class GlassActionButton extends StatelessWidget {
  const GlassActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  /// When true uses the teal fill colour; otherwise a translucent glass look.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return _GlassButton(
      onPressed: onPressed,
      icon: icon,
      label: label,
      filled: filled,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────────────────────

/// Shared premium navy→teal gradient wave header for staff-facing list pages.
///
/// Mirrors the visual treatment of `_PatientsHeader` from `patients_page.dart`.
/// The [headline] is typically a [RichText] or [Builder] that renders the page's
/// main big text, optionally with an accent word coloured in `Color(0xFF00D4C9)`.
///
/// Example:
/// ```dart
/// StaffSectionHeader(
///   navTitle: 'Convites',
///   eyebrow: 'CONVITES DE PACIENTES',
///   headline: Builder(builder: (ctx) {
///     final theme = Theme.of(ctx);
///     return RichText(
///       text: TextSpan(
///         style: theme.textTheme.headlineLarge?.copyWith(
///           fontWeight: FontWeight.w900, color: Colors.white, height: 1.1,
///         ),
///         children: const [
///           TextSpan(text: 'Convites', style: TextStyle(color: Color(0xFF00D4C9))),
///           TextSpan(text: '\nde pacientes'),
///         ],
///       ),
///     );
///   }),
///   onBack: () => context.pop(),
/// )
/// ```
class StaffSectionHeader extends StatelessWidget {
  const StaffSectionHeader({
    super.key,
    required this.navTitle,
    required this.eyebrow,
    required this.headline,
    required this.onBack,
    this.onRefresh,
    this.stats,
    this.actions,
    this.extraBottomPadding = 0,
  });

  /// Title shown in the nav row (AppBar level).
  final String navTitle;

  /// Uppercase faded label rendered above the main [headline].
  final String eyebrow;

  /// Main big headline widget — typically a [RichText] or [Builder].
  final Widget headline;

  /// Tapped when the back button is pressed.
  final VoidCallback onBack;

  /// Optional refresh button on the right side of the nav row.
  final VoidCallback? onRefresh;

  /// Optional glass stats bar. Pass `null` (or empty list) to omit the bar.
  final List<StaffSectionStat>? stats;

  /// Optional action buttons rendered below the stats bar.
  ///
  /// Use [GlassActionButton] for consistent styling.
  final List<Widget>? actions;

  /// Extra padding added to the bottom of the header content area.
  /// Useful when callers want a taller header without adding action buttons.
  final double extraBottomPadding;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isWide(context)) return _buildCompact(context);

    final theme = Theme.of(context);
    final statusBarTop = MediaQuery.paddingOf(context).top;
    final hasActions = actions != null && actions!.isNotEmpty;
    final hasStats = stats != null && stats!.isNotEmpty;

    return MotionReveal(
      child: ClipPath(
        clipper: _WaveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B2D5B),
                Color(0xFF1E4D8C),
                Color(0xFF0D7A75),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Status bar inset + nav row ──────────────────────────────
              SizedBox(height: statusBarTop),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Voltar',
                    ),
                    Expanded(
                      child: Text(
                        navTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (onRefresh != null)
                      IconButton(
                        onPressed: onRefresh,
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                        tooltip: 'Atualizar',
                      ),
                  ],
                ),
              ),

              // ── Eyebrow + headline + stats + actions ───────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  (hasActions ? 56 : 44) + extraBottomPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Eyebrow
                    Text(
                      eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Main headline
                    headline,

                    // Stats glass bar
                    if (hasStats) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: AppRadius.smAll,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            children: _buildStatItems(stats!),
                          ),
                        ),
                      ),
                    ],

                    // Action buttons row
                    if (hasActions) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          for (var i = 0; i < actions!.length; i++) ...[
                            if (i > 0) const SizedBox(width: AppSpacing.xs),
                            Expanded(child: actions![i]),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);

    const gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        Color(0xFF1B2D5B),
        Color(0xFF1E4D8C),
        Color(0xFF0D7A75),
      ],
      stops: [0.0, 0.55, 1.0],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E4D8C).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  navTitle,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00D4C9),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            for (final w in actions!) ...[
              w,
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
          if (onRefresh != null)
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'Atualizar',
            ),
        ],
      ),
    );
  }

  static List<Widget> _buildStatItems(List<StaffSectionStat> stats) {
    final result = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) result.add(_WaveStatDivider());
      result.add(
        _WaveStat(
          value: stats[i].value,
          label: stats[i].label,
          accent: stats[i].accent ?? Colors.white.withValues(alpha: 0.9),
        ),
      );
    }
    return result;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers (extracted from patients_page.dart)
// ─────────────────────────────────────────────────────────────────────────────

class _WaveStat extends StatelessWidget {
  const _WaveStat({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: accent,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 36)
      ..cubicTo(
        size.width * 0.22,
        size.height + 2,
        size.width * 0.72,
        size.height - 30,
        size.width,
        size.height - 8,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? AppColors.turquoise
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
