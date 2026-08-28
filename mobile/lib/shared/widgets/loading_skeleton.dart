import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

/// Skeleton discreto para listas e cards durante carregamento.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    this.height = 16,
    this.width,
    this.borderRadius,
  });

  const LoadingSkeleton.card({super.key})
      : height = 88,
        width = double.infinity,
        borderRadius = null;

  final double height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return _ShimmerBox(
      height: height,
      width: width,
      borderRadius: borderRadius ?? AppRadius.smAll,
    );
  }
}

class LoadingSkeletonList extends StatelessWidget {
  const LoadingSkeletonList({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    // Column em vez de ListView: funciona tanto em contexto com altura
    // limitada quanto ilimitada (ex.: dentro de outro scrollable).
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < itemCount; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            const LoadingSkeleton.card(),
          ],
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.height,
    this.width,
    required this.borderRadius,
  });

  final double height;
  final double? width;
  final BorderRadius borderRadius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skeletonColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;

    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: skeletonColor,
          borderRadius: widget.borderRadius,
        ),
      );
    }

    // Faixa de luz diagonal que percorre o bloco em loop — a mesma linguagem
    // do brilho "neural" da splash, aplicada a qualquer skeleton de loading.
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: skeletonColor),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // A faixa viaja de fora a fora (-0.25 → 1.25) para não piscar
                // nas bordas do bloco.
                final pos = -0.25 + _controller.value * 1.5;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Color(0x00FFFFFF),
                        Color(0x99FFFFFF),
                        Color(0x00FFFFFF),
                      ],
                      stops: [
                        (pos - 0.18).clamp(0.0, 1.0),
                        pos.clamp(0.0, 1.0),
                        (pos + 0.18).clamp(0.0, 1.0),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
