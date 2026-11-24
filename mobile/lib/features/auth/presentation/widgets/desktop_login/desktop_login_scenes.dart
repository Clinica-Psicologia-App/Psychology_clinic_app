import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'desktop_login_tokens.dart';

/// Quatro cenas decorativas da vitrine (sem nomes nem dados de paciente).
/// Área lógica 520 x 310; [t] = segundos desde que a cena entrou.
/// Com [t] grande a cena fica completa (modo "reduzir movimento").
class DesktopLoginScenePainter extends CustomPainter {
  const DesktopLoginScenePainter({
    required this.scene,
    required this.t,
    required this.tokens,
  });

  final int scene;
  final double t;
  final DesktopLoginTokens tokens;

  static const double w = 520;
  static const double h = 310;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / w, size.height / h);
    canvas.save();
    canvas.translate((size.width - w * s) / 2, (size.height - h * s) / 2);
    canvas.scale(s);
    switch (scene) {
      case 0:
        _genogram(canvas);
      case 1:
        _questionnaire(canvas);
      case 2:
        _journey(canvas);
      default:
        _security(canvas);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DesktopLoginScenePainter old) =>
      old.scene != scene || old.t != t || old.tokens != tokens;

  // ── utilidades ────────────────────────────────────────────────────────────
  /// Progresso 0..1 de um item com atraso [delay] e duração [dur] (s).
  double _p(double delay, double dur, [Curve curve = Curves.easeInOut]) {
    final v = ((t - delay) / dur).clamp(0.0, 1.0);
    return curve.transform(v);
  }

  Paint _stroke(Color c, double wd, {double alpha = 1}) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = wd
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c.withValues(alpha: alpha);

  Paint _fill(Color c, {double alpha = 1}) =>
      Paint()..color = c.withValues(alpha: alpha);

  Path _poly(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  void _draw(Canvas canvas, Path path, Paint paint, double progress) {
    if (progress <= 0) return;
    for (final m in path.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * progress), paint);
    }
  }

  /// Escala + fade (pop) em torno de [c].
  void _pop(Canvas canvas, Offset c, double delay, void Function() body,
      {double dur = 0.34}) {
    final v = _p(delay, dur, Curves.easeOutBack);
    if (v <= 0) return;
    final a = _p(delay, dur, Curves.easeOut);
    canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: a));
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.5 + 0.5 * v);
    canvas.translate(-c.dx, -c.dy);
    body();
    canvas.restore();
  }

  void _fade(Canvas canvas, double delay, void Function() body,
      {double dur = 0.4}) {
    final a = _p(delay, dur, Curves.easeOut);
    if (a <= 0) return;
    canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: a));
    body();
    canvas.restore();
  }

  void _text(Canvas canvas, String s, Offset center,
      {double size = 11, Color? color, FontWeight? weight, double spacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color ?? tokens.tx3,
          fontWeight: weight,
          letterSpacing: spacing,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _rr(Canvas canvas, double x, double y, double wd, double ht, double r,
      {Paint? fill, Paint? stroke}) {
    final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, wd, ht), Radius.circular(r));
    if (fill != null) canvas.drawRRect(rr, fill);
    if (stroke != null) canvas.drawRRect(rr, stroke);
  }

  // ── cena 0: genograma se desenhando ───────────────────────────────────────
  void _genogram(Canvas canvas) {
    _fade(canvas, 0, () {
      _rr(canvas, 48, 14, 190, 196, 12,
          fill: _fill(DesktopLoginTokens.teal, alpha: .1));
    });
    _fade(canvas, .15, () {
      _rr(canvas, 282, 14, 190, 196, 12,
          fill: _fill(DesktopLoginTokens.purple, alpha: .1));
    });
    void line(List<Offset> pts, double d, double du) =>
        _draw(canvas, _poly(pts), _stroke(tokens.tx3, 1.5), _p(d, du));
    line(const [Offset(117, 50), Offset(169, 50)], .45, .3);
    line(const [Offset(351, 50), Offset(403, 50)], .55, .3);
    line(const [Offset(143, 50), Offset(143, 112), Offset(190, 112), Offset(190, 143)],
        .75, .45);
    line(const [Offset(377, 50), Offset(377, 112), Offset(330, 112), Offset(330, 143)],
        .85, .45);
    line(const [Offset(207, 160), Offset(313, 160)], 1.35, .35);
    line(const [Offset(260, 160), Offset(260, 226)], 1.65, .3);
    line(const [Offset(260, 226), Offset(150, 226), Offset(150, 253)], 1.9, .4);
    line(const [Offset(260, 226), Offset(260, 253)], 1.9, .3);
    line(const [Offset(260, 226), Offset(370, 226), Offset(370, 253)], 1.9, .4);

    // relação próxima: traço verde duplo
    final close = Path()
      ..moveTo(168, 262)
      ..quadraticBezierTo(200, 214, 316, 174);
    final pc = _p(2.7, .6);
    _draw(canvas, close, _stroke(const Color(0xFF059669), 5), pc);
    _draw(canvas, close, _stroke(tokens.bg, 1.8), pc);
    // relação conflituosa: zigue-zague
    final zig = Path()..moveTo(352, 262);
    var cur = const Offset(352, 262);
    for (final d in const [
      Offset(-6, -12), Offset(9, -8), Offset(-9, -9), Offset(8, -9),
      Offset(-8, -9), Offset(7, -9), Offset(-6, -10)
    ]) {
      cur += d;
      zig.lineTo(cur.dx, cur.dy);
    }
    _draw(canvas, zig, _stroke(const Color(0xFFC2410C), 1.6), _p(3, .5));

    void sq(double x, double y, double d, [Color? c]) =>
        _pop(canvas, Offset(x, y), d, () {
          _rr(canvas, x - 17, y - 17, 34, 34, 0,
              fill: _fill(tokens.rz), stroke: _stroke(c ?? tokens.tx, 1.8));
        });
    void ci(double x, double y, double d, [Color? c]) =>
        _pop(canvas, Offset(x, y), d, () {
          canvas.drawCircle(Offset(x, y), 17, _fill(tokens.rz));
          canvas.drawCircle(Offset(x, y), 17, _stroke(c ?? tokens.tx, 1.8));
        });
    sq(100, 50, .1);
    ci(186, 50, .2);
    sq(334, 50, .3);
    ci(420, 50, .4);
    sq(190, 160, 1.15, const Color(0xFF0F766E));
    ci(330, 160, 1.25, const Color(0xFF7B4FB8));
    _pop(canvas, const Offset(150, 270), 2.3, () {
      canvas.drawCircle(const Offset(150, 270), 26,
          _fill(DesktopLoginTokens.teal, alpha: .18));
    });
    ci(150, 270, 2.25, const Color(0xFF00A39B));
    sq(260, 270, 2.35);
    ci(370, 270, 2.45);
  }

  // ── cena 1: questionário + barras de resultado ────────────────────────────
  void _questionnaire(Canvas canvas) {
    var x = 28.0;
    const chips = ['PHQ-9', 'GAD-7', 'Young', 'NEO PI-R'];
    for (var i = 0; i < chips.length; i++) {
      final wd = chips[i].length * 7.2 + 22;
      final cx = x;
      _fade(canvas, i * .08, () {
        _rr(canvas, cx, 22, wd, 24, 6,
            fill: i == 0 ? _fill(DesktopLoginTokens.blue) : null,
            stroke: _stroke(i == 0 ? DesktopLoginTokens.blue : tokens.bd2, 1));
        _text(canvas, chips[i], Offset(cx + wd / 2, 34),
            size: 11.5,
            weight: FontWeight.w600,
            color: i == 0 ? Colors.white : tokens.tx2);
      });
      x += wd + 8;
    }
    const mk = [2, 4, 1];
    for (var k = 0; k < 3; k++) {
      final y = 74.0 + k * 76;
      _fade(canvas, .25 + k * .12, () {
        _rr(canvas, 28, y, const [210.0, 170.0, 230.0][k], 8, 4,
            fill: _fill(tokens.bd2));
        _rr(canvas, 28, y + 14, const [150.0, 200.0, 120.0][k], 8, 4,
            fill: _fill(tokens.bd));
        for (var i = 0; i < 6; i++) {
          final c = Offset(40.0 + i * 38, y + 44);
          canvas.drawCircle(c, 11, _fill(tokens.rz));
          canvas.drawCircle(c, 11, _stroke(tokens.bd2, 1.5));
          _text(canvas, '${i + 1}', c, size: 10.5);
        }
      });
      final mc = Offset(40.0 + mk[k] * 38, y + 44);
      _pop(canvas, mc, .9 + k * .55, () {
        canvas.drawCircle(mc, 12, _fill(DesktopLoginTokens.blue));
        _text(canvas, '${mk[k] + 1}', mc,
            size: 10.5, color: Colors.white, weight: FontWeight.w700);
      });
    }
    _fade(canvas, .3, () {
      _rr(canvas, 300, 62, 196, 232, 10,
          fill: _fill(tokens.rz), stroke: _stroke(tokens.bd2, 1));
    });
    _fade(canvas, .4, () {
      _rr(canvas, 316, 78, 90, 8, 4, fill: _fill(tokens.bd2));
    });
    _draw(
        canvas,
        _poly(const [Offset(316, 150), Offset(480, 150)]),
        _stroke(DesktopLoginTokens.purple, 1.3, alpha: .6),
        _p(2.5, .5));
    const hs = [64.0, 118.0, 150.0, 92.0, 134.0];
    for (var i = 0; i < hs.length; i++) {
      final g = _p(2.5 + i * .12, .6, Curves.easeOutCubic);
      final hh = hs[i] * g;
      if (g > 0) {
        _rr(canvas, 320.0 + i * 34, 262 - hh, 20, hh, 4,
            fill: _fill(hs[i] >= 112
                ? DesktopLoginTokens.purple
                : const Color(0xFF9DBBF9)));
      }
      _fade(canvas, .4, () {
        _rr(canvas, 320.0 + i * 34, 270, 20, 6, 3, fill: _fill(tokens.bd));
      });
    }
  }

  // ── cena 2: trilha da jornada + semana de check-ins ───────────────────────
  void _journey(Canvas canvas) {
    final path = Path()
      ..moveTo(52, 236)
      ..cubicTo(120, 236, 112, 112, 176, 112)
      ..cubicTo(240, 112, 252, 204, 318, 196)
      ..cubicTo(384, 188, 392, 84, 452, 84);
    canvas.drawPath(path, _stroke(tokens.bd2, 10));
    final grad = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = ui.Gradient.linear(const Offset(52, 0), const Offset(452, 0), [
        DesktopLoginTokens.teal,
        DesktopLoginTokens.blue,
        DesktopLoginTokens.purple,
      ], [
        0,
        .6,
        1
      ]);
    _draw(canvas, path, grad, _p(.2, 2.6));
    // pulso no último passo (repete)
    if (t > 2.9) {
      final v = ((t - 2.9) % 1.8) / 1.8;
      canvas.drawCircle(const Offset(452, 84), 20 * (0.7 + 0.8 * v),
          _fill(DesktopLoginTokens.purple, alpha: .7 * (1 - v)));
    }
    const pts = [Offset(52, 236), Offset(176, 112), Offset(318, 196), Offset(452, 84)];
    const cols = [
      Color(0xFF00A39B), Color(0xFF0096D6), Color(0xFF3B82F6), Color(0xFF7B5CF6)
    ];
    for (var i = 0; i < pts.length; i++) {
      final p = pts[i];
      canvas.drawCircle(p, 17, _fill(tokens.rz));
      canvas.drawCircle(p, 17, _stroke(tokens.bd2, 2));
      _pop(canvas, p, .25 + i * .85, () {
        canvas.drawCircle(p, 17, _fill(cols[i]));
        if (i < 3) {
          canvas.drawPath(
              _poly([p + const Offset(-7, 0), p + const Offset(-2, 5), p + const Offset(7, -5)]),
              _stroke(Colors.white, 2.4));
        } else {
          canvas.drawPath(
              _poly([
                p + const Offset(-4, 9), p + const Offset(-4, -9),
                p + const Offset(7, -9), p + const Offset(4, -4.5),
                p + const Offset(7, 0), p + const Offset(-4, 0)
              ]),
              _stroke(Colors.white, 2));
        }
      });
      _fade(canvas, .4 + i * .85, () {
        final dy = i.isOdd ? -46.0 : 30.0;
        _rr(canvas, p.dx - 30, p.dy + dy, 60, 7, 3.5, fill: _fill(tokens.bd2));
        _rr(canvas, p.dx - 20, p.dy + dy + 12, 40, 6, 3, fill: _fill(tokens.bd));
      });
    }
    const days = 'STQQSSD';
    for (var i = 0; i < days.length; i++) {
      final x = 300.0 + i * 26;
      _rr(canvas, x, 268, 20, 20, 5, stroke: _stroke(tokens.bd2, 1));
      if (i < 5) {
        _pop(canvas, Offset(x + 10, 278), 1.2 + i * .22, () {
          _rr(canvas, x, 268, 20, 20, 5, fill: _fill(const Color(0xFF00A39B)));
        });
      }
      _text(canvas, days[i], Offset(x + 10, 278),
          size: 10,
          weight: FontWeight.w600,
          color: i < 5 && _p(1.2 + i * .22, .34) > .5 ? Colors.white : tokens.tx3);
    }
  }

  // ── cena 3: escudo, cadeado, convite chegando ─────────────────────────────
  void _security(Canvas canvas) {
    if (t > 2) {
      final v = ((t - 2) % 1.8) / 1.8;
      canvas.drawCircle(const Offset(260, 160), 70 * (0.7 + 0.8 * v),
          _fill(DesktopLoginTokens.teal, alpha: .7 * (1 - v) * .5));
    }
    final shield = Path()
      ..moveTo(260, 66)
      ..relativeLineTo(82, 30)
      ..relativeLineTo(0, 60)
      ..relativeCubicTo(0, 52, -36, 82, -82, 94)
      ..relativeCubicTo(-46, -12, -82, -42, -82, -94)
      ..lineTo(178, 96)
      ..close();
    _fade(canvas, 0, () {
      canvas.drawPath(shield, _fill(DesktopLoginTokens.teal, alpha: .1));
    });
    _draw(canvas, shield, _stroke(const Color(0xFF00A39B), 2.4), _p(.1, 1.1));
    _pop(canvas, const Offset(260, 168), .9, () {
      _rr(canvas, 236, 148, 48, 40, 6, fill: _fill(tokens.tx));
      final shackle = Path()
        ..moveTo(246, 148)
        ..relativeLineTo(0, -12)
        ..arcToPoint(const Offset(274, 136),
            radius: const Radius.circular(14), clockwise: true)
        ..relativeLineTo(0, 12);
      canvas.drawPath(shackle, _stroke(tokens.tx, 4));
      canvas.drawCircle(const Offset(260, 166), 4.5, _fill(tokens.rz));
      _rr(canvas, 258.5, 166, 3, 10, 1.5, fill: _fill(tokens.rz));
    });
    _draw(canvas, _poly(const [Offset(96, 160), Offset(168, 160)]),
        _stroke(tokens.bd2, 1.5), _p(1.2, .5));
    // convite chegando (desliza da esquerda)
    final sl = _p(1.1, .8, Curves.easeOutCubic);
    if (sl > 0) {
      canvas.saveLayer(
          null, Paint()..color = Colors.white.withValues(alpha: sl));
      canvas.translate(-120 * (1 - sl), 0);
      _rr(canvas, 40, 138, 62, 44, 6,
          fill: _fill(tokens.rz),
          stroke: _stroke(DesktopLoginTokens.blue, 2));
      canvas.drawPath(
          _poly(const [Offset(41, 141), Offset(71, 163), Offset(101, 141)]),
          _stroke(DesktopLoginTokens.blue, 2));
      canvas.restore();
    }
    _pop(canvas, const Offset(334, 92), 2, () {
      canvas.drawCircle(const Offset(334, 92), 15, _fill(const Color(0xFF059669)));
      canvas.drawPath(
          _poly(const [Offset(327, 92), Offset(332, 97), Offset(341, 87)]),
          _stroke(Colors.white, 2.4));
    });
    for (var k = 0; k < 3; k++) {
      _fade(canvas, 1.5 + k * .25, () {
        final y = 112.0 + k * 40;
        _rr(canvas, 372, y, 124, 28, 7,
            fill: _fill(tokens.rz), stroke: _stroke(tokens.bd2, 1));
        _rr(canvas, 383, y + 12, 8, 8, 1.5, stroke: _stroke(tokens.tq, 1.4));
        _text(canvas, '•' * (9 - k), Offset(446, y + 14),
            size: 13, spacing: 2.5);
      });
    }
  }
}
