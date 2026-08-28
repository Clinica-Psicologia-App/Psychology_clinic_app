import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import 'app_motion.dart';

/// Card compacto vertical para grids de módulos (2 colunas em telas
/// estreitas). Ícone em box gradiente do acento + título + subtítulo.
class ModuleGridCard extends StatelessWidget {
  const ModuleGridCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = AppRadius.lgAll;
    final effectiveTap = enabled ? onTap : null;

    return MotionSurface(
      onTap: effectiveTap,
      borderRadius: radius,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.62,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: effectiveTap,
            borderRadius: radius,
            child: Ink(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: radius,
                boxShadow: AppShadows.card,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: enabled ? accentColor : AppColors.disabled,
                          borderRadius: AppRadius.mdAll,
                          boxShadow: enabled
                              ? [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.45),
                                    blurRadius: 4,
                                    offset: const Offset(-2, -2),
                                  ),
                                  BoxShadow(
                                    color: accentColor.withValues(alpha: 0.38),
                                    blurRadius: 10,
                                    offset: const Offset(3, 5),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(icon, color: Colors.white, size: 21),
                      ),
                      const Spacer(),
                      if (!enabled)
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11.5,
                      height: 1.3,
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
}
