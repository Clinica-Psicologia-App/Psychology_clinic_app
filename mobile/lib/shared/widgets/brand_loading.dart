import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'esquema_core_logo.dart';

/// Indicador de carregamento da marca: o ícone do app (cérebro) pulsando
/// suavemente com uma faixa de luz "neural" percorrendo o desenho, envolto por
/// dois arcos contra-girando (turquesa + azul) que sinalizam o progresso —
/// mesma linguagem da splash.
///
/// Respeita reduce-motion: sem pulso, sem brilho e sem arcos girando, apenas o
/// ícone estático.
class BrandLoader extends StatefulWidget {
  const BrandLoader({
    super.key,
    this.size = 76,
    this.label,
  });

  /// Aresta do ícone (o cérebro é contido nesse tamanho). O anel é desenhado
  /// ao redor, ocupando ~1.7x esse valor.
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
  late final AnimationController _ringOuter;
  late final AnimationController _ringInner;

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
    _ringOuter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _ringInner = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();
  }

  @override
  void dispose() {
    _breathe.dispose();
    _shimmer.dispose();
    _ringOuter.dispose();
    _ringInner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final ringSize = widget.size * 1.7;

    final Widget mark;
    if (reduceMotion) {
      mark = EsquemaCoreLogo(size: widget.size);
    } else {
      mark = SizedBox(
        width: ringSize,
        height: ringSize,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _breathe,
            _shimmer,
            _ringOuter,
            _ringInner,
          ]),
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Dois arcos contra-girando ao redor do ícone.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RingPainter(
                      outerAngle: _ringOuter.value * 2 * math.pi,
                      innerAngle: -_ringInner.value * 2 * math.pi,
                    ),
                  ),
                ),
                // Ícone com respiração + brilho neural.
                Transform.scale(
                  scale: 1 + _breathe.value * 0.05,
                  child: _NeuralMark(
                    size: widget.size,
                    shimmer: _shimmer.value,
                  ),
                ),
              ],
            );
          },
        ),
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

/// Desenha dois arcos ao redor do ícone: um externo (turquesa, com trilho
/// tênue) e um interno (azul), cada um numa posição angular própria — a
/// animação vem de fora, variando esses ângulos em sentidos opostos.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.outerAngle, required this.innerAngle});

  final double outerAngle;
  final double innerAngle;

  static const double _outerSweep = 1.2566; // ~72°
  static const double _innerSweep = 1.0472; // ~60°

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rOuter = size.width / 2 - 2.5;
    final rInner = rOuter - 9;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = AppColors.turquoise.withValues(alpha: 0.12);
    canvas.drawCircle(center, rOuter, track);

    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.turquoise;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rOuter),
      outerAngle,
      _outerSweep,
      false,
      outer,
    );

    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..color = AppColors.cyan;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: rInner),
      innerAngle,
      _innerSweep,
      false,
      inner,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.outerAngle != outerAngle ||
        oldDelegate.innerAngle != innerAngle;
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
