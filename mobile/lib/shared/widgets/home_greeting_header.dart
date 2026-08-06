import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/profile/presentation/widgets/user_avatar.dart';

/// Cabeçalho de saudação das home de cada papel (psicólogo, paciente, admin).
///
/// Avatar em destaque com anel + brilho clay, saudação pelo período do dia
/// (eyebrow com ícone), primeiro nome grande e uma linha de contexto. O
/// [accent] dá a identidade de cada área; a [watermarkIcon] assina o cartão.
class HomeGreetingHeader extends StatelessWidget {
  const HomeGreetingHeader({
    super.key,
    required this.profile,
    required this.accent,
    required this.name,
    required this.contextLine,
    required this.watermarkIcon,
  });

  final UserProfile profile;
  final Color accent;
  final String name;
  final String contextLine;
  final IconData watermarkIcon;

  static String greetingForHour(int hour) {
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static IconData _timeIcon(int hour) {
    if (hour < 12) return Icons.wb_twilight_outlined;
    if (hour < 18) return Icons.wb_sunny_outlined;
    return Icons.nightlight_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hour = DateTime.now().hour;
    final greeting = greetingForHour(hour);

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        // Um leve véu do acento sobre a superfície dá calor sem virar um
        // "hero" chapado de gradiente.
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surface, accent.withValues(alpha: 0.10)],
        ),
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: accent.withValues(alpha: 0.16)),
        boxShadow: AppShadows.clay(),
      ),
      child: Stack(
        children: [
          // Marca-d'água discreta: assina o cabeçalho sem competir com o texto.
          Positioned(
            right: -10,
            top: -12,
            child: Icon(
              watermarkIcon,
              size: 108,
              color: accent.withValues(alpha: 0.07),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar maior, com anel branco e brilho clay.
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.clay(accent),
                  ),
                  child: UserAvatar(profile: profile, size: 76),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(_timeIcon(hour), size: 15, color: accent),
                          const SizedBox(width: 5),
                          Text(
                            greeting.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        contextLine,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
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
