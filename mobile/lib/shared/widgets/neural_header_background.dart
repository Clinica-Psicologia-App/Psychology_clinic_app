import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';

/// Fundo animado bem sutil para headers em gradiente: nós conectados por
/// linhas finas, com brilho pulsando devagar — eco da rede neural da marca.
/// Branco de baixa opacidade, funciona sobre qualquer gradiente. Não bloqueia
/// toques e respeita "reduzir movimento".
class NeuralHeaderBackground extends StatefulWidget {
  const NeuralHeaderBackground({super.key});

  @override
  State<NeuralHeaderBackground> createState() => _NeuralHeaderBackgroundState();
}

class _NeuralHeaderBackgroundState extends State<NeuralHeaderBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Cria o controller sem iniciar: repeat() é ligado em didChangeDependencies
    // depois que o contexto está disponível, permitindo verificar shouldAnimate
    // (que respeita MediaQuery.disableAnimations — dispositivos com "reduzir
    // movimento" ativo e testes que injetam disableAnimations:true).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.shouldAnimate(context)) {
      // Animação habilitada: inicia (ou mantém) o loop contínuo.
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      // "Reduzir movimento" ativo: para o ticker para não desperdiçar CPU
      // e para permitir que pumpAndSettle() funcione nos testes.
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) {
      return const IgnorePointer(
        child: CustomPaint(
          painter: _NeuralHeaderPainter(0),
          size: Size.infinite,
        ),
      );
    }
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) => CustomPaint(
          painter: _NeuralHeaderPainter(_controller.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _NeuralHeaderPainter extends CustomPainter {
  const _NeuralHeaderPainter(this.t);

  final double t;

  static const List<Offset> _nodes = [
    Offset(0.10, 0.34),
    Offset(0.27, 0.66),
    Offset(0.43, 0.22),
    Offset(0.58, 0.70),
    Offset(0.73, 0.34),
    Offset(0.89, 0.60),
    Offset(0.52, 0.46),
  ];

  static const List<List<int>> _edges = [
    [0, 2],
    [2, 6],
    [6, 3],
    [3, 1],
    [6, 4],
    [4, 5],
    [2, 4],
    [1, 6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const tau = 2 * math.pi;

    Offset pos(int i) {
      final base = _nodes[i];
      final phase = i * 0.9;
      final dx = math.sin(tau * t + phase) * 7;
      final dy = math.cos(tau * t + phase * 1.3) * 6;
      return Offset(base.dx * size.width + dx, base.dy * size.height + dy);
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (final e in _edges) {
      canvas.drawLine(pos(e[0]), pos(e[1]), linePaint);
    }

    for (var i = 0; i < _nodes.length; i++) {
      final p = pos(i);
      final pulse = 0.5 + 0.5 * math.sin(tau * t + i);
      canvas.drawCircle(
        p,
        8 + 4 * pulse,
        Paint()..color = Colors.white.withValues(alpha: 0.05),
      );
      canvas.drawCircle(
        p,
        2.4,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
    }
  }

  @override
  bool shouldRepaint(_NeuralHeaderPainter oldDelegate) => oldDelegate.t != t;
}
