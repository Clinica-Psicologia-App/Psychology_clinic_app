import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'brand_brain_mark.dart';
import 'brand_constellation.dart';

/// Chip informativo exibido dentro do [BrandHeroCard].
class BrandHeroChip {
  const BrandHeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Hero assinatura da marca — camadas: gradiente em respiração, glow radial
/// que deriva, constelação de nodos, marca d'água, conteúdo.
///
/// Usar apenas em homes e contextos de destaque real; uso excessivo dilui
/// o impacto. A variante [dense] (admin) reduz decoração emocional.
class BrandHeroCard extends StatefulWidget {
  const BrandHeroCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.chips = const <BrandHeroChip>[],
    this.greetingOverride,
    this.dense = false,
  });

  final String name;
  final String subtitle;
  final List<BrandHeroChip> chips;

  /// Substitui a saudação automática por horário.
  final String? greetingOverride;

  /// Variante operacional (admin): menos decoração, mais compacta.
  final bool dense;

  @override
  State<BrandHeroCard> createState() => _BrandHeroCardState();
}

class _BrandHeroCardState extends State<BrandHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && AppAnimations.shouldAnimate(context)) {
        _breathe.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  String get _greeting {
    if (widget.greetingOverride != null) return widget.greetingOverride!;
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Bom dia';
    if (hour >= 12 && hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary isola a animação contínua do hero do resto da lista,
    // evitando repintar a tela inteira a cada frame.
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(_breathe.value);
          return Container(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xlAll,
              gradient: LinearGradient(
                begin: Alignment.lerp(
                  Alignment.topLeft,
                  const Alignment(-0.6, -1),
                  t,
                )!,
                end: Alignment.lerp(
                  Alignment.bottomRight,
                  const Alignment(1, 0.55),
                  t,
                )!,
                colors: [
                  Color.lerp(AppColors.turquoise, AppColors.cyan, t * 0.55)!,
                  Color.lerp(
                      AppColors.blue, const Color(0xFF4F74F0), t * 0.45)!,
                  AppColors.purple,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.blue.withValues(alpha: 0.28),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: AppRadius.xlAll,
          child: Stack(
            children: [
              // Constelação de nodos da marca (estática — custo zero)
              if (!widget.dense)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: LayoutBuilder(
                      builder: (context, constraints) => BrandConstellation(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        opacity: 0.14,
                      ),
                    ),
                  ),
                ),
              if (!widget.dense)
                const Positioned(
                  right: -30,
                  top: -22,
                  child: Opacity(
                    opacity: 0.14,
                    child: BrandBrainMark(size: 170),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(
                  widget.dense ? AppSpacing.lg : AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Avatar(
                          name: widget.name,
                          size: widget.dense ? 50 : 64,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _greeting,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                widget.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      height: 1.08,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                widget.subtitle,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.82),
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (widget.chips.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final chip in widget.chips)
                            _HeroChip(icon: chip.icon, label: chip.label),
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
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.name,
    this.size = 64,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.22),
            blurRadius: 14,
            offset: const Offset(4, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Clay: chip sólido e "fofo" — sem transparência de vidro.
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(3, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.cyan),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
