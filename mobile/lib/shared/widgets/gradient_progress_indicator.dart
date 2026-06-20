import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';

/// Barra de progresso com gradiente institucional EsquemaCore.
class GradientProgressIndicator extends StatelessWidget {
  const GradientProgressIndicator({
    super.key,
    required this.value,
    this.height = 8,
    this.label,
  });

  final double value;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Semantics(
      label: label ?? 'Progresso ${(clamped * 100).round()} por cento',
      value: '${(clamped * 100).round()}%',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: AppRadius.smAll,
            child: SizedBox(
              height: height,
              child: TweenAnimationBuilder<double>(
                duration: AppAnimations.standard,
                curve: AppAnimations.standardCurve,
                tween: Tween(begin: 0, end: clamped),
                builder: (context, animatedValue, _) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: animatedValue,
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: AppGradients.progress()),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
