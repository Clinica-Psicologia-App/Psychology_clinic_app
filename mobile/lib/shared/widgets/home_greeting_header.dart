import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';
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
///
/// Motion: entrada encadeada one-shot — o cartão surge, o avatar dá um leve
/// "pop" e a saudação/nome/contexto entram escalonados. Respeita a preferência
/// de reduzir movimento do sistema (via [AppAnimations.resolve]).
class HomeGreetingHeader extends StatefulWidget {
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
  State<HomeGreetingHeader> createState() => _HomeGreetingHeaderState();
}

class _HomeGreetingHeaderState extends State<HomeGreetingHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  // Coreografia: janelas de tempo (0–1) para cada peça entrar em sequência.
  late final Animation<double> _cardIn;
  late final Animation<double> _avatarFade;
  late final Animation<double> _avatarScale;
  late final Animation<double> _eyebrowIn;
  late final Animation<double> _nameIn;
  late final Animation<double> _contextIn;

  Animation<double> _window(double begin, double end, {Curve? curve}) {
    return CurvedAnimation(
      parent: _c,
      curve: Interval(begin, end, curve: curve ?? AppAnimations.enterCurve),
    );
  }

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 660),
    );

    _cardIn = _window(0.0, 0.5);
    _avatarFade = _window(0.05, 0.45);
    _avatarScale = Tween<double>(begin: 0.85, end: 1.0)
        .animate(_window(0.05, 0.55, curve: Curves.easeOutBack));
    _eyebrowIn = _window(0.30, 0.65);
    _nameIn = _window(0.42, 0.78);
    _contextIn = _window(0.55, 0.92);

    // Depois do primeiro frame: aí o context já resolve o reduce-motion. Com
    // movimento reduzido, a duração vira zero e a coreografia assenta direto
    // no estado final (sem animar).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _c.duration = AppAnimations.resolve(
        context,
        const Duration(milliseconds: 660),
      );
      _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Fade + leve subida (translateY) conforme a janela [a] avança de 0 a 1.
  Widget _rise(Animation<double> a, Widget child, {double dy = 8}) {
    return AnimatedBuilder(
      animation: a,
      builder: (_, c) => Opacity(
        opacity: a.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - a.value) * dy),
          child: c,
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accent;
    final hour = DateTime.now().hour;
    final greeting = HomeGreetingHeader.greetingForHour(hour);

    return _rise(
      _cardIn,
      dy: 12,
      Container(
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
                widget.watermarkIcon,
                size: 108,
                color: accent.withValues(alpha: 0.07),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar maior, com anel branco e brilho clay — entra com
                  // um leve "pop".
                  ScaleTransition(
                    scale: _avatarScale,
                    child: FadeTransition(
                      opacity: _avatarFade,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.clay(accent),
                        ),
                        child: UserAvatar(profile: widget.profile, size: 76),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _rise(
                          _eyebrowIn,
                          Row(
                            children: [
                              Icon(HomeGreetingHeader._timeIcon(hour),
                                  size: 15, color: accent),
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
                        ),
                        const SizedBox(height: 3),
                        _rise(
                          _nameIn,
                          Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: AppColors.navy,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        _rise(
                          _contextIn,
                          Text(
                            widget.contextLine,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                            ),
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
      ),
    );
  }
}
