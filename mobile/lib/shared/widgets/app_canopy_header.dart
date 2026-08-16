import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/profile/domain/user_profile.dart';
import '../../features/profile/presentation/widgets/user_avatar.dart';
import 'brand_brain_mark.dart';

/// Cabeçalho premium "canopy" das home de cada papel.
///
/// Diferente do card de saudação anterior (que ficava *dentro* do corpo, com
/// uma AppBar plana redundante acima), o canopy é o próprio topo da tela: um
/// gradiente da cor da área que sobe atrás da status bar (full-bleed), com a
/// marca, a saudação e o avatar unificados numa superfície só. Os cards de
/// conteúdo fluem logo abaixo, sobre o fundo claro — dando profundidade em
/// camadas em vez do visual chapado anterior.
///
/// O [accent] dá a identidade de cada área (turquesa = profissional, azul =
/// paciente, roxo = plataforma); o gradiente é derivado dele, então o mesmo
/// componente serve todas as telas, cada uma na sua cor de módulo.
///
/// Motion: entrada única suave (fade + leve subida), respeitando a preferência
/// de reduzir movimento do sistema.
class AppCanopyHeader extends StatelessWidget {
  const AppCanopyHeader({
    super.key,
    required this.profile,
    required this.accent,
    required this.name,
    required this.contextLine,
    required this.areaLabel,
    required this.watermarkIcon,
    this.onProfileTap,
    this.footer,
  });

  final UserProfile profile;
  final Color accent;
  final String name;
  final String contextLine;

  /// Rótulo curto da área ("Profissional", "Meu espaço", "Plataforma"),
  /// exibido como pílula discreta ao lado da marca.
  final String areaLabel;
  final IconData watermarkIcon;
  final VoidCallback? onProfileTap;

  /// Cartão opcional que "flutua" sobre a base do gradiente (ex.: o resumo da
  /// carteira do psicólogo). Fica meio dentro do canopy, meio no conteúdo —
  /// criando a profundidade em camadas do visual premium.
  final Widget? footer;

  static String _greetingForHour(int hour) {
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  static String _timeAsset(int hour) {
    if (hour < 12) return 'assets/greeting/sunrise.svg';
    if (hour < 18) return 'assets/greeting/sun.svg';
    return 'assets/greeting/moon.svg';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final hour = DateTime.now().hour;
    final greeting = _greetingForHour(hour);

    // Gradiente derivado do acento: um leve realce no topo e um fundo mais
    // profundo (acento mesclado ao navy) — o mesmo desenho funciona para
    // turquesa, azul e roxo, cada área com sua cor.
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(accent, Colors.white, 0.10)!,
        accent,
        Color.lerp(accent, AppColors.navy, 0.42)!,
      ],
      stops: const [0.0, 0.45, 1.0],
    );

    final canopy = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        topInset + AppSpacing.sm,
        AppSpacing.xl,
        footer != null ? AppSpacing.xxxl : AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(accent, AppColors.navy, 0.3)!
                .withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Marca-d'água discreta assinando o cabeçalho.
          Positioned(
            right: -12,
            top: 8,
            child: Icon(
              watermarkIcon,
              size: 116,
              color: Colors.white.withValues(alpha: 0.09),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _WordmarkRow(areaLabel: areaLabel),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AvatarBadge(profile: profile, onTap: onProfileTap),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              _timeAsset(hour),
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              greeting.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
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
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          contextLine,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    final content = footer == null
        ? canopy
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              canopy,
              // Sobe o cartão para dentro da base do gradiente: metade sobre o
              // canopy, metade sobre o conteúdo. O `xxxl` de padding inferior
              // acima reserva o espaço para essa sobreposição não cobrir o
              // texto da saudação.
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: footer,
                ),
              ),
            ],
          );

    if (!AppAnimations.shouldAnimate(context)) return content;
    return _CanopyReveal(child: content);
  }
}

class _WordmarkRow extends StatelessWidget {
  const _WordmarkRow({required this.areaLabel});

  final String areaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandBrainMark(size: 20, color: Colors.white),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'EsquemaCore',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              areaLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.profile, this.onTap});

  final UserProfile profile;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.28),
        shape: BoxShape.circle,
      ),
      child: UserAvatar(profile: profile, size: 60),
    );

    if (onTap == null) return badge;
    return Semantics(
      button: true,
      label: 'Meu perfil',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: badge,
      ),
    );
  }
}

/// Fade + leve subida de entrada, uma vez só.
class _CanopyReveal extends StatefulWidget {
  const _CanopyReveal({required this.child});

  final Widget child;

  @override
  State<_CanopyReveal> createState() => _CanopyRevealState();
}

class _CanopyRevealState extends State<_CanopyReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: AppAnimations.emphasis);
    final curved = CurvedAnimation(parent: _c, curve: AppAnimations.enterCurve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.03),
      end: Offset.zero,
    ).animate(curved);
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
