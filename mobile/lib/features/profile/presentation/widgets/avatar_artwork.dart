import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/avatar_config.dart';
import 'avatar_palette.dart';

/// Desenha o avatar personalizado a partir de [AvatarConfig].
///
/// Por que vetorial e não assets em camadas: um conjunto completo de rosto,
/// cabelo, barba, óculos e roupas seriam dezenas de PNGs com licença para
/// auditar — e a spec proíbe material sem procedência clara. Desenhando por
/// código não há asset algum, o resultado é idêntico em Web, Android e iOS,
/// escala para qualquer tamanho sem perder nitidez e nada precisa ser
/// pré-carregado. Também não há arquivo no Storage: o avatar vive em
/// `avatar_config` e é redesenhado a cada frame.
///
/// Todo o desenho acontece num espaço lógico de 100x100 e é escalado para o
/// tamanho real, então as proporções não dependem da resolução.
class AvatarPainter extends CustomPainter {
  const AvatarPainter(this.config);

  final AvatarConfig config;

  /// Lado do espaço lógico de desenho.
  static const double _canvas = 100;

  // Âncoras do rosto. Centralizadas para que as partes conversem entre si —
  // mexer no raio da cabeça reposiciona olhos, orelhas e cabelo juntos.
  static const Offset _headCenter = Offset(50, 44);
  static const double _headRx = 21;
  static const double _headRy = 25;
  static const double _eyeY = 46;
  static const double _eyeDx = 8.4;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _canvas;
    canvas.save();
    canvas.scale(scale);

    final skin = AvatarPalette.skin(config.skinTone);
    final hair = AvatarPalette.hair(config.hairColor);

    _paintBackground(canvas);
    // Cabelos longos passam por trás dos ombros e da cabeça.
    _paintHairBack(canvas, hair);
    _paintBody(canvas, skin);
    _paintHead(canvas, skin);
    _paintEyebrows(canvas, hair);
    _paintEyes(canvas);
    _paintNose(canvas, skin);
    _paintMouth(canvas);
    _paintFacialHair(canvas, hair);
    _paintHairFront(canvas, hair);
    _paintGlasses(canvas);

    canvas.restore();
  }

  // ── Fundo ──────────────────────────────────────────────────────────────────

  void _paintBackground(Canvas canvas) {
    final base = AvatarPalette.of(config.backgroundColor);
    // Leve gradiente em vez de chapado: dá profundidade sem custar
    // configuração extra para o usuário.
    final rect = const Rect.fromLTWH(0, 0, _canvas, _canvas);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, 0.22)!,
            Color.lerp(base, Colors.black, 0.10)!,
          ],
        ).createShader(rect),
    );
  }

  // ── Corpo: pescoço, ombros e roupa ────────────────────────────────────────

  void _paintBody(Canvas canvas, Color skin) {
    // Pescoço primeiro, para a gola cobrir a base dele.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43, 60, 14, 18),
        const Radius.circular(6),
      ),
      Paint()..color = Color.lerp(skin, Colors.black, 0.10)!,
    );

    final outfit = AvatarPalette.of(config.outfitColor);
    final shoulders = Path()
      ..moveTo(16, _canvas)
      ..lineTo(16, 88)
      ..quadraticBezierTo(16, 74, 34, 71)
      ..lineTo(66, 71)
      ..quadraticBezierTo(84, 74, 84, 88)
      ..lineTo(84, _canvas)
      ..close();
    canvas.drawPath(shoulders, Paint()..color = outfit);

    _paintCollar(canvas, outfit, skin);
  }

  void _paintCollar(Canvas canvas, Color outfit, Color skin) {
    final dark = Paint()..color = Color.lerp(outfit, Colors.black, 0.20)!;
    final skinPaint = Paint()..color = skin;

    switch (config.outfit) {
      case AvatarOutfit.crewneck:
        canvas.drawArc(
          const Rect.fromLTWH(41, 66, 18, 12),
          0,
          math.pi,
          true,
          dark,
        );

      case AvatarOutfit.vNeck:
        final v = Path()
          ..moveTo(42, 70)
          ..lineTo(50, 82)
          ..lineTo(58, 70)
          ..close();
        canvas.drawPath(v, skinPaint);

      case AvatarOutfit.collared:
        canvas.drawPath(
          Path()
            ..moveTo(42, 70)
            ..lineTo(50, 80)
            ..lineTo(58, 70)
            ..close(),
          Paint()..color = Color.lerp(outfit, Colors.white, 0.55)!,
        );
        canvas.drawPath(
          Path()
            ..moveTo(41, 69)
            ..lineTo(50, 81)
            ..lineTo(45, 69)
            ..close(),
          dark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(59, 69)
            ..lineTo(50, 81)
            ..lineTo(55, 69)
            ..close(),
          dark,
        );

      case AvatarOutfit.blazer:
        // Lapelas sobre uma camisa clara.
        canvas.drawPath(
          Path()
            ..moveTo(43, 70)
            ..lineTo(50, 84)
            ..lineTo(57, 70)
            ..close(),
          Paint()..color = Color.lerp(outfit, Colors.white, 0.70)!,
        );
        canvas.drawPath(
          Path()
            ..moveTo(40, 70)
            ..lineTo(50, 86)
            ..lineTo(44, 70)
            ..close(),
          dark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(60, 70)
            ..lineTo(50, 86)
            ..lineTo(56, 70)
            ..close(),
          dark,
        );

      case AvatarOutfit.hoodie:
        canvas.drawArc(
          const Rect.fromLTWH(38, 64, 24, 16),
          0,
          math.pi,
          true,
          dark,
        );
        // Cordões.
        final cord = Paint()
          ..color = Color.lerp(outfit, Colors.white, 0.65)!
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(46, 76), const Offset(45, 88), cord);
        canvas.drawLine(const Offset(54, 76), const Offset(55, 88), cord);
    }
  }

  // ── Cabeça e orelhas ──────────────────────────────────────────────────────

  void _paintHead(Canvas canvas, Color skin) {
    final ear = Paint()..color = Color.lerp(skin, Colors.black, 0.06)!;
    canvas.drawCircle(Offset(_headCenter.dx - _headRx, _eyeY + 4), 3.4, ear);
    canvas.drawCircle(Offset(_headCenter.dx + _headRx, _eyeY + 4), 3.4, ear);

    canvas.drawOval(
      Rect.fromCenter(
        center: _headCenter,
        width: _headRx * 2,
        height: _headRy * 2,
      ),
      Paint()..color = skin,
    );
  }

  void _paintNose(Canvas canvas, Color skin) {
    canvas.drawPath(
      Path()
        ..moveTo(50, 48)
        ..lineTo(47.6, 54)
        ..quadraticBezierTo(50, 55.4, 52.4, 54),
      Paint()
        ..color = Color.lerp(skin, Colors.black, 0.16)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Chamada duas vezes de propósito quando há barba: uma no fluxo normal e
  /// outra depois dos pelos faciais, para a boca não sumir sob a barba.
  void _paintMouth(Canvas canvas) {
    canvas.drawArc(
      const Rect.fromLTWH(45, 55, 10, 8),
      0.15,
      math.pi - 0.3,
      false,
      Paint()
        ..color = const Color(0xFF7A3B3B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  // ── Olhos e sobrancelhas ──────────────────────────────────────────────────

  void _paintEyes(Canvas canvas) {
    for (final side in const [-1, 1]) {
      final cx = _headCenter.dx + side * _eyeDx;
      _paintEye(canvas, cx);
    }
  }

  void _paintEye(Canvas canvas, double cx) {
    final white = Paint()..color = Colors.white;
    final iris = Paint()..color = const Color(0xFF3A2A1E);
    final line = Paint()
      ..color = const Color(0xFF2C2C2C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    switch (config.eyeStyle) {
      case AvatarEyeStyle.round:
        canvas.drawCircle(Offset(cx, _eyeY), 3.2, white);
        canvas.drawCircle(Offset(cx, _eyeY), 1.7, iris);

      case AvatarEyeStyle.almond:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, _eyeY), width: 7, height: 4.4),
          white,
        );
        canvas.drawCircle(Offset(cx, _eyeY), 1.7, iris);

      case AvatarEyeStyle.narrow:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, _eyeY), width: 7, height: 2.8),
          white,
        );
        canvas.drawCircle(Offset(cx, _eyeY), 1.3, iris);

      case AvatarEyeStyle.wide:
        canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, _eyeY), width: 8, height: 6),
          white,
        );
        canvas.drawCircle(Offset(cx, _eyeY), 2.1, iris);

      case AvatarEyeStyle.happy:
        // Olhos fechados sorrindo: só o arco, sem esclera nem íris.
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, _eyeY), width: 7, height: 5),
          math.pi,
          math.pi,
          false,
          line,
        );
    }
  }

  void _paintEyebrows(Canvas canvas, Color hair) {
    final paint = Paint()
      ..color = Color.lerp(hair, Colors.black, 0.15)!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = switch (config.eyebrowStyle) {
        AvatarEyebrowStyle.thick => 2.4,
        AvatarEyebrowStyle.thin => 1.0,
        _ => 1.6,
      };

    for (final side in const [-1, 1]) {
      final cx = _headCenter.dx + side * _eyeDx;
      final y = switch (config.eyebrowStyle) {
        AvatarEyebrowStyle.raised => 38.0,
        _ => 40.0,
      };

      final path = Path()..moveTo(cx - 3.6, y);
      switch (config.eyebrowStyle) {
        case AvatarEyebrowStyle.arched:
          path.quadraticBezierTo(cx, y - 2.6, cx + 3.6, y);
        case AvatarEyebrowStyle.raised:
          path.quadraticBezierTo(cx, y - 1.8, cx + 3.6, y - 0.6);
        default:
          path.quadraticBezierTo(cx, y - 1.2, cx + 3.6, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  // ── Pelos faciais ─────────────────────────────────────────────────────────

  void _paintFacialHair(Canvas canvas, Color hair) {
    if (config.facialHair == AvatarFacialHair.none) return;

    final paint = Paint()..color = hair;

    switch (config.facialHair) {
      case AvatarFacialHair.none:
        return;

      case AvatarFacialHair.stubble:
        _paintBeard(canvas, Paint()..color = hair.withValues(alpha: 0.34),
            sideY: 54, dipY: 62);

      case AvatarFacialHair.mustache:
        _paintMustache(canvas, paint);

      case AvatarFacialHair.goatee:
        // Cavanhaque fica no queixo, ABAIXO da boca — cobri-la faria o rosto
        // parecer sem boca.
        canvas.save();
        canvas.clipPath(Path()..addOval(_headRect));
        canvas.drawPath(
          Path()
            ..moveTo(45.5, 63)
            ..quadraticBezierTo(50, 61.6, 54.5, 63)
            ..quadraticBezierTo(53.4, 70, 50, 71)
            ..quadraticBezierTo(46.6, 70, 45.5, 63)
            ..close(),
          paint,
        );
        canvas.restore();
        _paintMustache(canvas, paint);

      case AvatarFacialHair.shortBeard:
        _paintBeard(canvas, paint, sideY: 54, dipY: 62);
        _paintMustache(canvas, paint);
        _paintMouth(canvas);

      case AvatarFacialHair.fullBeard:
        _paintBeard(canvas, paint, sideY: 46, dipY: 61);
        _paintMustache(canvas, paint);
        _paintMouth(canvas);
    }
  }

  /// Barba acompanhando a mandíbula.
  ///
  /// A borda superior é uma curva que sobe nas laterais (costeletas) e desce no
  /// meio, e o preenchimento vai daí até embaixo, recortado pelo oval da
  /// cabeça. A primeira versão usava `drawArc(useCenter: true)`, que preenche
  /// um semidisco a partir do centro — o resultado era um corte horizontal reto
  /// atravessando o rosto.
  void _paintBeard(
    Canvas canvas,
    Paint paint, {
    required double sideY,
    required double dipY,
  }) {
    canvas.save();
    canvas.clipPath(Path()..addOval(_headRect));
    canvas.drawPath(
      Path()
        ..moveTo(_headCenter.dx - _headRx - 2, sideY)
        ..quadraticBezierTo(
          _headCenter.dx,
          dipY,
          _headCenter.dx + _headRx + 2,
          sideY,
        )
        ..lineTo(_headCenter.dx + _headRx + 2, _canvas)
        ..lineTo(_headCenter.dx - _headRx - 2, _canvas)
        ..close(),
      paint,
    );
    canvas.restore();
  }

  void _paintMustache(Canvas canvas, Paint paint) {
    canvas.drawPath(
      Path()
        ..moveTo(43.5, 56.4)
        ..quadraticBezierTo(46.5, 53.4, 50, 55.2)
        ..quadraticBezierTo(53.5, 53.4, 56.5, 56.4)
        ..quadraticBezierTo(53.5, 58.4, 50, 57.4)
        ..quadraticBezierTo(46.5, 58.4, 43.5, 56.4)
        ..close(),
      paint,
    );
  }

  Rect get _headRect => Rect.fromCenter(
        center: _headCenter,
        width: _headRx * 2,
        height: _headRy * 2,
      );

  // ── Cabelo ────────────────────────────────────────────────────────────────

  /// Volume que passa por trás da cabeça e dos ombros (comprimentos longos).
  void _paintHairBack(Canvas canvas, Color hair) {
    final paint = Paint()..color = Color.lerp(hair, Colors.black, 0.10)!;

    switch (config.hairStyle) {
      case AvatarHairStyle.long:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(26, 28, 48, 52),
            const Radius.circular(22),
          ),
          paint,
        );

      case AvatarHairStyle.longCurly:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(23, 26, 54, 54),
            const Radius.circular(26),
          ),
          paint,
        );
        for (var i = 0; i < 6; i++) {
          final t = i / 5;
          canvas.drawCircle(Offset(24 + t * 52, 74), 6, paint);
        }

      case AvatarHairStyle.ponytail:
        canvas.drawCircle(const Offset(74, 44), 7.5, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(69, 44, 11, 24),
            const Radius.circular(6),
          ),
          paint,
        );

      case AvatarHairStyle.bun:
        canvas.drawCircle(const Offset(50, 17), 8, paint);

      case AvatarHairStyle.afro:
        canvas.drawCircle(const Offset(50, 36), 30, paint);

      case AvatarHairStyle.medium:
        // O volume lateral vem por trás da cabeça; à frente fica só a calota.
        // Desenhar essa massa na frente exigiria repintar o rosto por cima
        // dela — e o rosto já foi desenhado com olhos e boca a essa altura.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(26, 30, 48, 32),
            const Radius.circular(17),
          ),
          paint,
        );

      default:
        return;
    }
  }

  /// Franja e topo, desenhados sobre o rosto.
  void _paintHairFront(Canvas canvas, Color hair) {
    if (config.hairStyle == AvatarHairStyle.none) return;

    final paint = Paint()..color = hair;

    // Calota superior comum a quase todos os estilos: um arco que acompanha o
    // topo do crânio.
    void cap({double spread = 1.0, double drop = 0.0}) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(_headCenter.dx, _headCenter.dy + drop),
          width: _headRx * 2 * spread + 2,
          height: _headRy * 2 * spread + 2,
        ),
        math.pi,
        math.pi,
        true,
        paint,
      );
    }

    switch (config.hairStyle) {
      case AvatarHairStyle.none:
        return;

      case AvatarHairStyle.buzz:
        canvas.save();
        canvas.clipPath(Path()..addOval(_headRect));
        canvas.drawArc(
          _headRect,
          math.pi,
          math.pi,
          true,
          Paint()..color = hair.withValues(alpha: 0.75),
        );
        canvas.restore();

      case AvatarHairStyle.short:
        cap();
        // Franja lateral leve.
        canvas.drawPath(
          Path()
            ..moveTo(30, 42)
            ..quadraticBezierTo(38, 30, 58, 33)
            ..quadraticBezierTo(48, 36, 42, 44)
            ..close(),
          paint,
        );

      case AvatarHairStyle.shortCurly:
        cap();
        for (var i = 0; i < 7; i++) {
          final angle = math.pi + (i / 6) * math.pi;
          canvas.drawCircle(
            Offset(
              _headCenter.dx + math.cos(angle) * (_headRx + 1),
              _headCenter.dy + math.sin(angle) * (_headRy + 1),
            ),
            5,
            paint,
          );
        }

      case AvatarHairStyle.medium:
        cap(spread: 1.08);

      case AvatarHairStyle.long:
      case AvatarHairStyle.longCurly:
        cap(spread: 1.06);
        canvas.drawPath(
          Path()
            ..moveTo(29, 44)
            ..quadraticBezierTo(36, 28, 50, 28)
            ..quadraticBezierTo(64, 28, 71, 44)
            ..quadraticBezierTo(64, 34, 50, 34)
            ..quadraticBezierTo(36, 34, 29, 44)
            ..close(),
          paint,
        );

      case AvatarHairStyle.bun:
      case AvatarHairStyle.ponytail:
        cap();

      case AvatarHairStyle.afro:
        // O volume inteiro já veio por trás; aqui fica só a linha do cabelo,
        // que é acima dos olhos e portanto não apaga o rosto.
        cap(spread: 0.98, drop: -3);
    }
  }

  // ── Óculos ────────────────────────────────────────────────────────────────

  void _paintGlasses(Canvas canvas) {
    if (config.glasses == AvatarGlasses.none) return;

    final frame = Paint()
      ..color = const Color(0xFF2F3640)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final lens = Paint()..color = Colors.white.withValues(alpha: 0.22);

    final left = Rect.fromCenter(
      center: Offset(_headCenter.dx - _eyeDx, _eyeY),
      width: 11,
      height: 9,
    );
    final right = Rect.fromCenter(
      center: Offset(_headCenter.dx + _eyeDx, _eyeY),
      width: 11,
      height: 9,
    );

    switch (config.glasses) {
      case AvatarGlasses.none:
        return;

      case AvatarGlasses.rounded:
        for (final r in [left, right]) {
          canvas.drawOval(r, lens);
          canvas.drawOval(r, frame);
        }

      case AvatarGlasses.square:
        for (final r in [left, right]) {
          final rr = RRect.fromRectAndRadius(r, const Radius.circular(2));
          canvas.drawRRect(rr, lens);
          canvas.drawRRect(rr, frame);
        }

      case AvatarGlasses.halfRim:
        // Só a barra superior e as laterais — sem aro embaixo.
        for (final r in [left, right]) {
          canvas.drawOval(r, lens);
          canvas.drawArc(r, math.pi, math.pi, false, frame);
        }
    }

    // Ponte e hastes.
    canvas.drawLine(
      Offset(left.right, _eyeY),
      Offset(right.left, _eyeY),
      frame,
    );
    canvas.drawLine(
      Offset(left.left, _eyeY),
      Offset(_headCenter.dx - _headRx, _eyeY + 1),
      frame,
    );
    canvas.drawLine(
      Offset(right.right, _eyeY),
      Offset(_headCenter.dx + _headRx, _eyeY + 1),
      frame,
    );
  }

  @override
  bool shouldRepaint(AvatarPainter old) => old.config != config;
}

/// Avatar personalizado pronto para uso, recortado em círculo.
class AvatarArtwork extends StatelessWidget {
  const AvatarArtwork({
    super.key,
    required this.config,
    this.size = 44,
  });

  final AvatarConfig config;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: CustomPaint(
        size: Size.square(size),
        painter: AvatarPainter(config),
        isComplex: true,
      ),
    );
  }
}
