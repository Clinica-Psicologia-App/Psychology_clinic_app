import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'esquema_core_logo.dart';

/// Indicador de carregamento da marca: o ícone do app (cérebro) pulsando
/// suavemente com uma faixa de luz "neural" percorrendo o desenho — a mesma
/// linguagem da splash. Usado como estado de loading padrão das telas.
///
/// Respeita reduce-motion: sem pulso e sem brilho, apenas o ícone estático.
class BrandLoader extends StatefulWidget {
  const BrandLoader({
    super.key,
    this.size = 76,
    this.label,
  });

  /// Aresta do ícone (o cérebro é contido nesse tamanho).
  final double size;

  /// Legenda opcional abaixo do ícone (ex.: "Carregando...").
  final String? label;

  @override
  State<BrandLoader> createState() => _BrandLoaderState();
}

class _BrandLoaderState extends State<BrandLoader>
    with TickerProviderStateMixin {
  late final AnimationController _breathe;
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _breathe.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final Widget mark;
    if (reduceMotion) {
      mark = EsquemaCoreLogo(size: widget.size);
    } else {
      mark = AnimatedBuilder(
        animation: Listenable.merge([_breathe, _shimmer]),
        builder: (context, _) {
          return Transform.scale(
            scale: 1 + _breathe.value * 0.05,
            child: _NeuralMark(size: widget.size, shimmer: _shimmer.value),
          );
        },
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          mark,
          if (widget.label != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.label!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// O mark oficial com a faixa de luz diagonal recortada na silhueta do
/// cérebro (ShaderMask sobre os pixels opacos).
class _NeuralMark extends StatelessWidget {
  const _NeuralMark({required this.size, required this.shimmer});

  final double size;

  /// 0..1 — posição da faixa de luz.
  final double shimmer;

  @override
  Widget build(BuildContext context) {
    final logo = EsquemaCoreLogo(size: size);
    // A faixa viaja de fora a fora (-0.3 → 1.3) para não piscar nas bordas.
    final pos = -0.3 + shimmer * 1.6;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: const [
          Colors.transparent,
          Color(0x73FFFFFF),
          Colors.transparent,
        ],
        stops: [
          (pos - 0.16).clamp(0.0, 1.0),
          pos.clamp(0.0, 1.0),
          (pos + 0.16).clamp(0.0, 1.0),
        ],
      ).createShader(rect),
      child: logo,
    );
  }
}
