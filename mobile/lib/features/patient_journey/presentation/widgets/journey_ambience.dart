import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';

/// Atmosfera de fundo da trilha do paciente — "naturalismo abstrato".
///
/// Não é ilustração: é ambiente. Três auras de cor (uma por fase clínica)
/// respiram lentamente sobre um gradiente frio→quente, com planos de horizonte
/// quase imperceptíveis, hastes vegetais estilizadas nas bordas e partículas
/// de luz. O objetivo é preencher o vazio sem competir com o conteúdo nem
/// infantilizar o tema clínico.
///
/// Fica fixa no viewport (atrás do scroll da trilha), então as auras pulsam no
/// lugar em vez de acompanhar o conteúdo.
class JourneyAmbience extends StatefulWidget {
  const JourneyAmbience({super.key});

  @override
  State<JourneyAmbience> createState() => _JourneyAmbienceState();
}

class _JourneyAmbienceState extends State<JourneyAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.shouldAnimate(context);
    if (animate && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!animate && _anim.isAnimating) {
      _anim.stop();
    }

    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => CustomPaint(
            painter: _AmbiencePainter(t: animate ? _anim.value : 0.35),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}

class _AmbiencePainter extends CustomPainter {
  const _AmbiencePainter({required this.t});

  /// Fase do ciclo de respiração, 0..1.
  final double t;

  // Gradiente de base: leve toque teal no topo, neutro quente embaixo.
  static const _skyTop = Color(0xFFE2EEF5);
  static const _skyMid = Color(0xFFE8F2F5);
  static const _skyLow = Color(0xFFEDF0EE);
  static const _skyBottom = Color(0xFFF0EDE8);

  // Uma aura por fase clínica: Conhecer, Avaliar, Compreender.
  static const _auraConhecer = Color(0xFF00B2A9);
  static const _auraAvaliar = Color(0xFF7B5CF6);
  static const _auraCompreender = Color(0xFFC98F52);

  static const _horizon = Color(0xFFCBD9E8);
  static const _stem = Color(0xFF6A9BB8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    _paintSky(canvas, rect);
    _paintHorizons(canvas, w, h);
    _paintAuras(canvas, w, h);
    _paintDecorativeCircles(canvas, w, h);
    _paintVegetation(canvas, w, h);
    _paintParticles(canvas, w, h);
  }

  void _paintSky(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyMid, _skyLow, _skyBottom],
          stops: [0.0, 0.34, 0.72, 1.0],
        ).createShader(rect),
    );
  }

  /// Planos de horizonte: curvas largas e visíveis que dão profundidade.
  void _paintHorizons(Canvas canvas, double w, double h) {
    const alphas = [0.20, 0.15, 0.10];
    const ys = [0.27, 0.52, 0.77];

    for (var i = 0; i < ys.length; i++) {
      final y = h * ys[i];
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(w * 0.26, y - h * 0.045, w * 0.52, y + h * 0.032, w, y - h * 0.028)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = _horizon.withValues(alpha: alphas[i]),
      );
    }
  }

  /// As três auras respiram fora de fase entre si — o movimento fica orgânico
  /// em vez de pulsar em bloco.
  void _paintAuras(Canvas canvas, double w, double h) {
    const specs = <(Color, double, double)>[
      (_auraConhecer, 0.68, 0.20),
      (_auraAvaliar, 0.30, 0.52),
      (_auraCompreender, 0.72, 0.84),
    ];

    for (var i = 0; i < specs.length; i++) {
      final (color, cx, cy) = specs[i];
      // Defasagem de 1/3 de ciclo por aura.
      final phase = (t + i / specs.length) % 1.0;
      final breath = (math.sin(phase * 2 * math.pi) + 1) / 2; // 0..1
      final scale = 1.0 + 0.05 * breath;
      final alpha = 0.15 + 0.08 * breath;

      final center = Offset(w * cx, h * cy);
      final rx = w * 0.62 * scale;
      final ry = h * 0.24 * scale;
      final oval = Rect.fromCenter(center: center, width: rx * 2, height: ry * 2);

      canvas.drawOval(
        oval,
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 1.0],
          ).createShader(oval),
      );
    }
  }

  /// Hastes com folhas nas bordas — mais visíveis e em mais posições.
  void _paintVegetation(Canvas canvas, double w, double h) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = _stem.withValues(alpha: 0.42);
    final leaf = Paint()..color = _stem.withValues(alpha: 0.34);

    void sprig(double x, double baseY, double height, bool toRight) {
      final dir = toRight ? 1.0 : -1.0;
      final tipY = baseY - height;

      canvas.drawPath(
        Path()
          ..moveTo(x, baseY)
          ..cubicTo(
            x + 3 * dir, baseY - height * 0.42,
            x - 2 * dir, baseY - height * 0.72,
            x + 1.5 * dir, tipY,
          ),
        stroke,
      );

      void branch(double atFraction, double len, double lift) {
        final sy = baseY - height * atFraction;
        final ex = x + len * dir;
        final ey = sy - lift;
        canvas.drawPath(
          Path()
            ..moveTo(x, sy)
            ..quadraticBezierTo(x + len * 0.55 * dir, sy - lift * 0.35, ex, ey),
          stroke,
        );
        canvas.save();
        canvas.translate(ex, ey);
        canvas.rotate(dir * -0.5);
        canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 18, height: 8),
          leaf,
        );
        canvas.restore();
      }

      branch(0.52, 15, 12);
      branch(0.78, 12, 10);
    }

    // Hastes nas bordas — mais posições que antes.
    sprig(w * 0.055, h * 0.50, h * 0.14, true);
    sprig(w * 0.945, h * 0.34, h * 0.12, false);
    sprig(w * 0.94,  h * 0.93, h * 0.11, false);
    sprig(w * 0.05,  h * 0.98, h * 0.10, true);
    sprig(w * 0.06,  h * 0.22, h * 0.10, true);
    sprig(w * 0.94,  h * 0.65, h * 0.12, false);
    sprig(w * 0.055, h * 0.76, h * 0.09, true);
    sprig(w * 0.945, h * 0.10, h * 0.08, false);
  }

  /// Círculos decorativos sutis — reforçam a sensação de profundidade de mapa.
  void _paintDecorativeCircles(Canvas canvas, double w, double h) {
    const specs = <(double, double, double, Color)>[
      (0.88, 0.18, 38, _auraConhecer),
      (0.12, 0.42, 28, _auraAvaliar),
      (0.90, 0.72, 32, _auraCompreender),
      (0.08, 0.88, 24, _auraConhecer),
    ];
    for (final (fx, fy, r, color) in specs) {
      canvas.drawCircle(
        Offset(w * fx, h * fy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = color.withValues(alpha: 0.14),
      );
      canvas.drawCircle(
        Offset(w * fx, h * fy),
        r * 1.55,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = color.withValues(alpha: 0.08),
      );
    }
  }

  /// Partículas de luz: pontos brancos difusos que dão vida ao campo vazio.
  void _paintParticles(Canvas canvas, double w, double h) {
    const spots = <(double, double, double, double)>[
      (0.26, 0.14, 3.0, 0.65),
      (0.83, 0.28, 2.5, 0.55),
      (0.17, 0.47, 2.8, 0.52),
      (0.87, 0.55, 2.4, 0.50),
      (0.39, 0.70, 2.6, 0.55),
      (0.79, 0.86, 2.3, 0.48),
      (0.13, 0.22, 2.2, 0.50),
      (0.47, 0.38, 2.0, 0.45),
      (0.62, 0.62, 2.0, 0.42),
      (0.30, 0.92, 2.2, 0.45),
      (0.55, 0.18, 1.8, 0.40),
      (0.72, 0.44, 1.6, 0.38),
      (0.22, 0.68, 1.7, 0.40),
      (0.91, 0.40, 1.8, 0.38),
      (0.48, 0.82, 1.6, 0.36),
    ];

    for (final (fx, fy, r, a) in spots) {
      canvas.drawCircle(
        Offset(w * fx, h * fy),
        r,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_AmbiencePainter old) => old.t != t;
}
