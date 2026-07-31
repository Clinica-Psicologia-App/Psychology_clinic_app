import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'app_motion.dart';
import 'brand_constellation.dart';

/// Superfície de ação principal — família distinta dos cards de módulo.
///
/// Fundo tonal do acento, ícone em destaque, caminho de nodos decorativo e
/// seta proeminente. Deve existir no máximo uma por seção.
class ActionSurface extends StatelessWidget {
  const ActionSurface({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
    this.enabled = true,
    this.statusLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool enabled;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    const radius = BorderRadius.all(Radius.circular(AppRadius.xl));
    final effectiveTap = enabled ? onTap : null;

    return MotionSurface(
      onTap: effectiveTap,
      borderRadius: radius,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.62,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: radius,
            boxShadow: AppShadows.card,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: effectiveTap,
                borderRadius: radius,
                child: Stack(
                  children: [
                    // Caminho de nodos decorativo à direita
                    Positioned(
                      right: 8,
                      top: 8,
                      bottom: 8,
                      width: 120,
                      child: BrandConstellation(
                        size: const Size(120, 100),
                        preset: BrandConstellationPreset.path,
                        color: accentColor,
                        opacity: 0.18,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: enabled ? accentColor : AppColors.disabled,
                              borderRadius: AppRadius.lgAll,
                              boxShadow: enabled
                                  ? [
                                      BoxShadow(
                                        color: Colors.white
                                            .withValues(alpha: 0.45),
                                        blurRadius: 4,
                                        offset: const Offset(-2, -2),
                                      ),
                                      BoxShadow(
                                        color:
                                            accentColor.withValues(alpha: 0.38),
                                        blurRadius: 12,
                                        offset: const Offset(3, 5),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(icon, color: Colors.white, size: 27),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        title,
                                        style: textTheme.titleMedium?.copyWith(
                                          color: AppColors.navy,
                                          fontWeight: FontWeight.w700,
                                          height: 1.15,
                                        ),
                                      ),
                                    ),
                                    if (statusLabel != null) ...[
                                      const SizedBox(width: AppSpacing.xs),
                                      _StatusPill(
                                        label: statusLabel!,
                                        accent: enabled
                                            ? accentColor
                                            : AppColors.disabled,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: enabled ? accentColor : AppColors.disabled,
                            ),
                            child: Icon(
                              enabled
                                  ? Icons.arrow_forward_rounded
                                  : Icons.lock_outline_rounded,
                              color: Colors.white,
                              size: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
