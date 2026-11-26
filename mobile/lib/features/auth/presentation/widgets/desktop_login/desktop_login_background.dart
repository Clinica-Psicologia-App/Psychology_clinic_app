import 'package:flutter/material.dart';

import '../../../../../core/theme/app_animations.dart';
import 'desktop_login_lifecycle.dart';
import 'desktop_login_tokens.dart';

/// Fundo vivo: 3 manchas que derivam devagar + constelação tênue parada.
/// Uma única camada (`RepaintBoundary`) e um único controller (47 s).
class DesktopLoginBackground extends StatefulWidget {
  const DesktopLoginBackground({super.key});

  @override
  State<DesktopLoginBackground> createState() => DesktopLoginBackgroundState();
}

class DesktopLoginBackgroundState extends State<DesktopLoginBackground>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        DesktopLoginLifecycle {
  late final AnimationController _c;

  /// Para testes: o controller está rodando?
  bool get isAnimating => _c.isAnimating;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 47));
    attachLifecycle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncAnimation();
  }

  @override
  void syncAnimation() {
    if (AppAnimations.shouldAnimate(context) && !inBackground) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    detachLifecycle();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DesktopLoginTokens.of(context);
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            size: Size.infinite,
            painter: _BackgroundPainter(_c.value, tokens),
          ),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter(this.v, this.tokens);

  final double v;
  final DesktopLoginTokens tokens;

  static const _nodes = [
    Offset(.07, .30), Offset(.20, .12), Offset(.36, .30), Offset(.14, .62),
    Offset(.30, .80), Offset(.52, .14), Offset(.66, .34), Offset(.84, .16),
    Offset(.93, .44), Offset(.76, .70), Offset(.56, .86), Offset(.92, .88),
    Offset(.44, .56),
  ];
  static const _edges = [
    [0, 1], [1, 2], [0, 3], [3, 4], [2, 5], [5, 6], [6, 7], [7, 8], [6, 9],
    [9, 10], [8, 11], [9, 11], [2, 12], [12, 9], [4, 12], [12, 6],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = tokens.bg);
    final alpha = tokens.dark ? .22 : .17;
    // vai-e-vem suave (0 → 1 → 0)
    final k = v < .5 ? v * 2 : (1 - v) * 2;
    void blob(Color c, double cx, double cy, double dx, double dy) {
      final d = size.width * .52;
      final center = Offset(size.width * (cx + dx * k), size.height * (cy + dy * k));
      final r = d / 2;
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [c.withValues(alpha: alpha), c.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    blob(DesktopLoginTokens.teal, .12, .02, .09, .12);
    blob(DesktopLoginTokens.purple, .90, .06, -.10, .14);
    blob(DesktopLoginTokens.blue, .52, 1.02, .12, -.10);

    final line = Paint()
      ..strokeWidth = 1
      ..color = tokens.tx3.withValues(alpha: .08);
    for (final e in _edges) {
      canvas.drawLine(
        Offset(_nodes[e[0]].dx * size.width, _nodes[e[0]].dy * size.height),
        Offset(_nodes[e[1]].dx * size.width, _nodes[e[1]].dy * size.height),
        line,
      );
    }
    final dot = Paint()..color = tokens.tx3.withValues(alpha: .15);
    for (final n in _nodes) {
      canvas.drawCircle(Offset(n.dx * size.width, n.dy * size.height), 2.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter old) =>
      old.v != v || old.tokens != tokens;
}
