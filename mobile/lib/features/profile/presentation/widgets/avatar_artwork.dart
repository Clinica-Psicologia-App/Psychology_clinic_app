import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/avatar_config.dart';
import 'avatar_palette.dart';

/// Desenha o avatar personalizado a partir de [AvatarConfig].
///
/// **Direção artística**: retrato adulto em flat 2D, formas arredondadas,
/// fundo pastel dessaturado, sombreado discreto e expressão acolhedora. Nada
/// de proporção caricata — a cabeça tem tamanho natural em relação aos ombros,
/// e a roupa é uma peça de verdade (gola, lapela, decote), não uma mancha.
///
/// **Por que vetorial e não assets SVG**: um conjunto de rosto, cabelo, barba,
/// óculos e roupas seriam dezenas de arquivos com licença para auditar, e a
/// spec proíbe material sem procedência clara. Desenhando por código não há
/// asset algum, o resultado é idêntico em Web, Android e iOS, escala sem
/// perder nitidez e nada precisa ser pré-carregado. Também não há arquivo no
/// Storage: o avatar vive em `avatar_config` e é redesenhado a cada frame, o
/// que elimina de saída arquivo órfão, consistência entre banco e Storage, e a
/// incompatibilidade de `toImage` no Flutter Web.
///
/// Todo o desenho acontece num espaço lógico de 100x100 e é escalado para o
/// tamanho real, então as proporções não dependem da resolução.
class AvatarPainter extends CustomPainter {
  const AvatarPainter(this.config);

  final AvatarConfig config;

  static const double _canvas = 100;

  // Âncoras do rosto. Tudo se posiciona a partir daqui, então ajustar o
  // tamanho da cabeça reposiciona olhos, orelhas, cabelo e barba juntos.
  static const Offset _headCenter = Offset(50, 41);
  static const double _headRy = 25;
  static const double _eyeY = 42;
  static const double _eyeDx = 7.8;
  static const double _mouthY = 55;

  /// Onde o cabelo termina e a testa começa. Sem essa âncora o cabelo era
  /// desenhado como "metade superior da cabeça", e essa metade termina
  /// exatamente na linha dos olhos — o rosto ficava sem testa.
  static const double _hairlineY = 34;

  double get _headRx => switch (config.faceShape) {
        AvatarFaceShape.oval => 18.5,
        AvatarFaceShape.round => 20.5,
        AvatarFaceShape.square => 19.5,
      };

  /// Contorno do rosto. O formato "anguloso" usa um retângulo bem arredondado
  /// em vez de elipse — mandíbula mais marcada, sem virar quadrado.
  Path get _facePath {
    final rect = Rect.fromCenter(
      center: _headCenter,
      width: _headRx * 2,
      height: _headRy * 2,
    );
    return switch (config.faceShape) {
      AvatarFaceShape.square => Path()
        ..addRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          ),
        ),
      _ => Path()..addOval(rect),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / _canvas;
    canvas.save();
    canvas.scale(scale);

    final skin = AvatarPalette.skin(config.skinTone);
    final hair = AvatarPalette.hair(config.hairColor);

    _paintBackground(canvas);
    _paintHairBack(canvas, hair);
    _paintNeckAndBody(canvas, skin);
    _paintFace(canvas, skin);
    _paintEyebrows(canvas, hair);
    _paintEyes(canvas);
    _paintNose(canvas, skin);
    _paintMouth(canvas);
    _paintFacialHair(canvas, hair);
    _paintHairFront(canvas, hair);
    _paintGlasses(canvas);
    _paintAccessory(canvas);

    canvas.restore();
  }

  // ── Fundo ──────────────────────────────────────────────────────────────────

  void _paintBackground(Canvas canvas) {
    final base = AvatarPalette.background(config.backgroundColor);
    const rect = Rect.fromLTWH(0, 0, _canvas, _canvas);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(base, Colors.white, 0.35)!,
            base,
          ],
        ).createShader(rect),
    );
  }

  // ── Pescoço, ombros e roupa ───────────────────────────────────────────────

  void _paintNeckAndBody(Canvas canvas, Color skin) {
    // Pescoço, com a sombra projetada pelo queixo — é o detalhe que mais
    // separa um retrato "chapado" de um com alguma profundidade.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43.5, 56, 13, 22),
        const Radius.circular(6),
      ),
      Paint()..color = skin,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(43.5, 56, 13, 8),
        const Radius.circular(4),
      ),
      Paint()..color = Color.lerp(skin, const Color(0xFF6B3F2A), 0.22)!,
    );

    final outfit = AvatarPalette.of(config.outfitColor);
    final shoulders = Path()
      ..moveTo(12, _canvas)
      ..lineTo(12, 90)
      ..quadraticBezierTo(14, 74, 34, 71)
      ..lineTo(66, 71)
      ..quadraticBezierTo(86, 74, 88, 90)
      ..lineTo(88, _canvas)
      ..close();
    canvas.drawPath(shoulders, Paint()..color = outfit);

    // Sombra suave onde os ombros encontram o pescoço.
    canvas.drawPath(
      shoulders,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(const Rect.fromLTWH(12, 71, 76, 18)),
    );

    _paintCollar(canvas, outfit, skin);
  }

  void _paintCollar(Canvas canvas, Color outfit, Color skin) {
    final dark = Paint()..color = Color.lerp(outfit, Colors.black, 0.22)!;
    final light = Paint()..color = Color.lerp(outfit, Colors.white, 0.78)!;

    switch (config.outfit) {
      case AvatarOutfit.crewneck:
        canvas.drawArc(
          const Rect.fromLTWH(41, 66, 18, 11),
          0,
          math.pi,
          true,
          dark,
        );

      case AvatarOutfit.vNeck:
        canvas.drawPath(
          Path()
            ..moveTo(42.5, 70)
            ..lineTo(50, 81)
            ..lineTo(57.5, 70)
            ..close(),
          Paint()..color = skin,
        );

      case AvatarOutfit.collared:
        // Camisa clara aparecendo, com as pontas da gola por cima.
        canvas.drawPath(
          Path()
            ..moveTo(42, 70)
            ..lineTo(50, 82)
            ..lineTo(58, 70)
            ..close(),
          light,
        );
        canvas.drawPath(
          Path()
            ..moveTo(41.5, 69.5)
            ..lineTo(50, 82)
            ..lineTo(46, 69.5)
            ..close(),
          light,
        );
        canvas.drawPath(
          Path()
            ..moveTo(58.5, 69.5)
            ..lineTo(50, 82)
            ..lineTo(54, 69.5)
            ..close(),
          light,
        );
        canvas.drawLine(
          const Offset(50, 82),
          const Offset(50, 100),
          Paint()
            ..color = Color.lerp(outfit, Colors.black, 0.14)!
            ..strokeWidth = 1.2,
        );

      case AvatarOutfit.blazer:
        // Camisa por baixo, lapelas por cima.
        canvas.drawPath(
          Path()
            ..moveTo(43, 70)
            ..lineTo(50, 100)
            ..lineTo(57, 70)
            ..close(),
          light,
        );
        canvas.drawPath(
          Path()
            ..moveTo(39, 70)
            ..lineTo(50, 88)
            ..lineTo(45, 70)
            ..close(),
          dark,
        );
        canvas.drawPath(
          Path()
            ..moveTo(61, 70)
            ..lineTo(50, 88)
            ..lineTo(55, 70)
            ..close(),
          dark,
        );

      case AvatarOutfit.hoodie:
        canvas.drawArc(
          const Rect.fromLTWH(37, 64, 26, 16),
          0,
          math.pi,
          true,
          dark,
        );
        final cord = Paint()
          ..color = light.color
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(46, 77), const Offset(45, 90), cord);
        canvas.drawLine(const Offset(54, 77), const Offset(55, 90), cord);
    }
  }

  // ── Rosto ─────────────────────────────────────────────────────────────────

  void _paintFace(Canvas canvas, Color skin) {
    final ear = Paint()..color = Color.lerp(skin, Colors.black, 0.07)!;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_headCenter.dx - _headRx, _eyeY + 4),
        width: 5,
        height: 8,
      ),
      ear,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_headCenter.dx + _headRx, _eyeY + 4),
        width: 5,
        height: 8,
      ),
      ear,
    );

    canvas.drawPath(_facePath, Paint()..color = skin);

    // Bochechas: quase imperceptíveis, só para o rosto não ficar plano.
    final blush = Paint()
      ..color = Color.lerp(skin, const Color(0xFFD98080), 0.30)!
          .withValues(alpha: 0.38);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_headCenter.dx - _headRx * 0.62, 49),
        width: 8,
        height: 4.6,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_headCenter.dx + _headRx * 0.62, 49),
        width: 8,
        height: 4.6,
      ),
      blush,
    );
  }

  void _paintNose(Canvas canvas, Color skin) {
    final ink = Paint()
      ..color = Color.lerp(skin, const Color(0xFF6B3F2A), 0.42)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    switch (config.noseStyle) {
      case AvatarNose.soft:
        canvas.drawPath(
          Path()
            ..moveTo(48.4, 48.6)
            ..quadraticBezierTo(50, 50.4, 51.6, 48.6),
          ink,
        );
      case AvatarNose.straight:
        canvas.drawPath(
          Path()
            ..moveTo(50, 44)
            ..lineTo(48.6, 49.4)
            ..quadraticBezierTo(50, 50.6, 51.4, 49.4),
          ink,
        );
      case AvatarNose.wide:
        canvas.drawPath(
          Path()
            ..moveTo(47.4, 48.4)
            ..quadraticBezierTo(50, 51, 52.6, 48.4),
          ink..strokeWidth = 1.3,
        );
    }
  }

  void _paintMouth(Canvas canvas) {
    final lip = Paint()
      ..color = const Color(0xFF9C5A52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    switch (config.mouthStyle) {
      case AvatarMouth.softSmile:
        canvas.drawPath(
          Path()
            ..moveTo(46.6, _mouthY)
            ..quadraticBezierTo(50, _mouthY + 2.6, 53.4, _mouthY),
          lip,
        );
      case AvatarMouth.smile:
        canvas.drawPath(
          Path()
            ..moveTo(45.4, _mouthY - 0.4)
            ..quadraticBezierTo(50, _mouthY + 4, 54.6, _mouthY - 0.4),
          lip..strokeWidth = 1.5,
        );
      case AvatarMouth.neutral:
        canvas.drawLine(
          Offset(46.8, _mouthY + 0.8),
          Offset(53.2, _mouthY + 0.8),
          lip,
        );
      case AvatarMouth.grin:
        // Boca aberta: preenchimento escuro com os dentes em cima.
        final mouth = Path()
          ..moveTo(45.4, _mouthY - 0.6)
          ..quadraticBezierTo(50, _mouthY + 5.4, 54.6, _mouthY - 0.6)
          ..close();
        canvas.drawPath(mouth, Paint()..color = const Color(0xFF7A3B3B));
        canvas.save();
        canvas.clipPath(mouth);
        canvas.drawRect(
          Rect.fromLTWH(44, _mouthY - 1, 12, 2.2),
          Paint()..color = Colors.white,
        );
        canvas.restore();
    }
  }

  // ── Olhos e sobrancelhas ──────────────────────────────────────────────────

  void _paintEyes(Canvas canvas) {
    for (final side in const [-1, 1]) {
      _paintEye(canvas, _headCenter.dx + side * _eyeDx);
    }
  }

  void _paintEye(Canvas canvas, double cx) {
    final white = Paint()..color = const Color(0xFFFBFBFB);
    final iris = Paint()..color = const Color(0xFF4A3626);
    final pupil = Paint()..color = const Color(0xFF241A12);
    final lid = Paint()
      ..color = const Color(0xFF3A2A20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    void irisAt(Offset center, double r) {
      canvas.drawCircle(center, r, iris);
      canvas.drawCircle(center, r * 0.5, pupil);
      // Brilho: é o que dá vida ao olhar.
      canvas.drawCircle(
        center.translate(-r * 0.32, -r * 0.36),
        r * 0.28,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    }

    switch (config.eyeStyle) {
      case AvatarEyeStyle.round:
        final rect =
            Rect.fromCenter(center: Offset(cx, _eyeY), width: 6.4, height: 6);
        canvas.drawOval(rect, white);
        irisAt(Offset(cx, _eyeY), 2.3);
        canvas.drawArc(rect, math.pi + 0.2, math.pi - 0.4, false, lid);

      case AvatarEyeStyle.almond:
        final rect =
            Rect.fromCenter(center: Offset(cx, _eyeY), width: 7.2, height: 4.6);
        canvas.drawOval(rect, white);
        irisAt(Offset(cx, _eyeY), 2.1);
        canvas.drawArc(rect, math.pi + 0.15, math.pi - 0.3, false, lid);

      case AvatarEyeStyle.narrow:
        final rect =
            Rect.fromCenter(center: Offset(cx, _eyeY), width: 7.2, height: 3.4);
        canvas.drawOval(rect, white);
        irisAt(Offset(cx, _eyeY), 1.7);
        canvas.drawArc(rect, math.pi + 0.1, math.pi - 0.2, false, lid);

      case AvatarEyeStyle.wide:
        final rect =
            Rect.fromCenter(center: Offset(cx, _eyeY), width: 7.6, height: 6.4);
        canvas.drawOval(rect, white);
        irisAt(Offset(cx, _eyeY), 2.5);
        canvas.drawArc(rect, math.pi + 0.2, math.pi - 0.4, false, lid);

      case AvatarEyeStyle.happy:
        // Olhos fechados sorrindo: só o arco.
        canvas.drawArc(
          Rect.fromCenter(center: Offset(cx, _eyeY), width: 7, height: 5),
          math.pi + 0.1,
          math.pi - 0.2,
          false,
          lid..strokeWidth = 1.4,
        );
    }
  }

  void _paintEyebrows(Canvas canvas, Color hair) {
    final paint = Paint()
      ..color = Color.lerp(hair, Colors.black, 0.12)!
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = switch (config.eyebrowStyle) {
        AvatarEyebrowStyle.thick => 2.2,
        AvatarEyebrowStyle.thin => 1.0,
        _ => 1.5,
      };

    for (final side in const [-1, 1]) {
      final cx = _headCenter.dx + side * _eyeDx;
      final y = config.eyebrowStyle == AvatarEyebrowStyle.raised ? 34.6 : 36.2;

      final path = Path()..moveTo(cx - 3.6, y + 0.6);
      switch (config.eyebrowStyle) {
        case AvatarEyebrowStyle.arched:
          path.quadraticBezierTo(cx, y - 2.4, cx + 3.6, y + 0.4);
        case AvatarEyebrowStyle.raised:
          path.quadraticBezierTo(cx, y - 1.6, cx + 3.6, y - 0.4);
        default:
          path.quadraticBezierTo(cx, y - 1.0, cx + 3.6, y);
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
        _paintBeard(
          canvas,
          Paint()..color = hair.withValues(alpha: 0.30),
          sideY: 48,
          dipY: 58,
        );

      case AvatarFacialHair.mustache:
        _paintMustache(canvas, paint);

      case AvatarFacialHair.goatee:
        canvas.save();
        canvas.clipPath(_facePath);
        canvas.drawPath(
          Path()
            ..moveTo(46, 60)
            ..quadraticBezierTo(50, 58.6, 54, 60)
            ..quadraticBezierTo(53, 67, 50, 68)
            ..quadraticBezierTo(47, 67, 46, 60)
            ..close(),
          paint,
        );
        canvas.restore();
        _paintMustache(canvas, paint);

      case AvatarFacialHair.shortBeard:
        _paintBeard(canvas, paint, sideY: 47, dipY: 58);
        _paintMustache(canvas, paint);
        _paintMouth(canvas);

      case AvatarFacialHair.fullBeard:
        // Costeletas abaixo da linha dos olhos: mais acima a barba invade a
        // têmpora e o rosto vira uma máscara.
        _paintBeard(canvas, paint, sideY: 46, dipY: 57);
        _paintMustache(canvas, paint);
        _paintMouth(canvas);
    }
  }

  /// Barba acompanhando a mandíbula.
  ///
  /// A borda superior é uma curva que sobe nas laterais (costeletas) e desce no
  /// meio, e o preenchimento vai daí até embaixo, recortado pelo contorno do
  /// rosto. Uma versão anterior usava `drawArc(useCenter: true)`, que preenche
  /// um semidisco a partir do centro — cortava o rosto com uma linha reta.
  void _paintBeard(
    Canvas canvas,
    Paint paint, {
    required double sideY,
    required double dipY,
  }) {
    canvas.save();
    canvas.clipPath(_facePath);
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
        ..moveTo(44.6, 53.4)
        ..quadraticBezierTo(47.2, 50.8, 50, 52.4)
        ..quadraticBezierTo(52.8, 50.8, 55.4, 53.4)
        ..quadraticBezierTo(52.8, 55.2, 50, 54.2)
        ..quadraticBezierTo(47.2, 55.2, 44.6, 53.4)
        ..close(),
      paint,
    );
  }

  // ── Cabelo ────────────────────────────────────────────────────────────────

  /// Volume que passa por trás da cabeça e dos ombros.
  void _paintHairBack(Canvas canvas, Color hair) {
    final paint = Paint()..color = Color.lerp(hair, Colors.black, 0.12)!;

    switch (config.hairStyle) {
      case AvatarHairStyle.long:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 20, 46, 56),
            const Radius.circular(22),
          ),
          paint,
        );

      case AvatarHairStyle.longCurly:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(24, 18, 52, 58),
            const Radius.circular(26),
          ),
          paint,
        );
        for (var i = 0; i < 5; i++) {
          canvas.drawCircle(Offset(26 + i * 12.0, 72), 6.5, paint);
        }

      case AvatarHairStyle.ponytail:
        canvas.drawCircle(const Offset(72, 40), 7, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(67, 40, 10, 22),
            const Radius.circular(5),
          ),
          paint,
        );

      case AvatarHairStyle.bun:
        canvas.drawCircle(const Offset(50, 14), 8, paint);

      case AvatarHairStyle.afro:
        canvas.drawCircle(const Offset(50, 34), 28, paint);

      case AvatarHairStyle.medium:
        // O volume lateral vem por trás; à frente fica só a calota. Desenhar
        // essa massa na frente exigiria repintar o rosto por cima dela — e o
        // rosto já foi desenhado com olhos e boca a essa altura.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 20, 46, 42),
            const Radius.circular(19),
          ),
          paint,
        );

      default:
        return;
    }
  }

  /// Franja e topo, desenhados sobre o rosto — sempre acima da linha dos
  /// olhos, para não apagar feições já pintadas.
  void _paintHairFront(Canvas canvas, Color hair) {
    if (config.hairStyle == AvatarHairStyle.none) return;

    final paint = Paint()..color = hair;
    final shine = Paint()..color = Colors.white.withValues(alpha: 0.10);

    void cap({double spread = 1.0, double drop = 0.0}) {
      final bottom = _hairlineY + drop;
      final top = _headCenter.dy - _headRy - 1.5;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(_headCenter.dx, bottom),
          width: _headRx * 2 * spread + 2.5,
          height: (bottom - top) * 2,
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
        canvas.clipPath(_facePath);
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(_headCenter.dx, _hairlineY),
            width: _headRx * 2,
            height: (_hairlineY - (_headCenter.dy - _headRy)) * 2,
          ),
          math.pi,
          math.pi,
          true,
          Paint()..color = hair.withValues(alpha: 0.78),
        );
        canvas.restore();

      case AvatarHairStyle.short:
        cap();
        canvas.drawPath(
          Path()
            ..moveTo(_headCenter.dx - _headRx - 1, 35)
            ..quadraticBezierTo(38, 22, 60, 26)
            ..quadraticBezierTo(50, 29, 44, 36)
            ..close(),
          paint,
        );

      case AvatarHairStyle.shortCurly:
        cap();
        for (var i = 0; i < 7; i++) {
          final angle = math.pi + (i / 6) * math.pi;
          canvas.drawCircle(
            Offset(
              _headCenter.dx + math.cos(angle) * (_headRx + 0.5),
              _hairlineY + math.sin(angle) * (_hairlineY - 16),
            ),
            5,
            paint,
          );
        }

      case AvatarHairStyle.medium:
        cap(spread: 1.06);

      case AvatarHairStyle.long:
      case AvatarHairStyle.longCurly:
        cap(spread: 1.04);
        canvas.drawPath(
          Path()
            ..moveTo(30, 36)
            ..quadraticBezierTo(36, 18, 50, 18)
            ..quadraticBezierTo(64, 18, 70, 36)
            ..quadraticBezierTo(63, 26, 50, 26)
            ..quadraticBezierTo(37, 26, 30, 36)
            ..close(),
          paint,
        );

      case AvatarHairStyle.bun:
      case AvatarHairStyle.ponytail:
        cap();

      case AvatarHairStyle.afro:
        cap(spread: 0.98, drop: -3);
    }

    // Brilho discreto no topo — o mesmo truque das ilustrações de referência.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(_headCenter.dx - 6, _headCenter.dy - _headRy + 4),
        width: 13,
        height: 5,
      ),
      shine,
    );
  }

  // ── Óculos e acessórios ───────────────────────────────────────────────────

  void _paintGlasses(Canvas canvas) {
    if (config.glasses == AvatarGlasses.none) return;

    final frame = Paint()
      ..color = const Color(0xFF3A3F4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final lens = Paint()..color = Colors.white.withValues(alpha: 0.20);

    final left = Rect.fromCenter(
      center: Offset(_headCenter.dx - _eyeDx, _eyeY),
      width: 10.5,
      height: 8.6,
    );
    final right = Rect.fromCenter(
      center: Offset(_headCenter.dx + _eyeDx, _eyeY),
      width: 10.5,
      height: 8.6,
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
        for (final r in [left, right]) {
          canvas.drawOval(r, lens);
          canvas.drawArc(r, math.pi, math.pi, false, frame);
        }
    }

    canvas.drawLine(
        Offset(left.right, _eyeY), Offset(right.left, _eyeY), frame);
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

  void _paintAccessory(Canvas canvas) {
    if (config.accessory == AvatarAccessory.none) return;

    final gold = Paint()..color = const Color(0xFFD9A441);
    final earY = _eyeY + 6.5;

    switch (config.accessory) {
      case AvatarAccessory.none:
        return;

      case AvatarAccessory.studs:
        canvas.drawCircle(Offset(_headCenter.dx - _headRx, earY), 1.4, gold);
        canvas.drawCircle(Offset(_headCenter.dx + _headRx, earY), 1.4, gold);

      case AvatarAccessory.hoops:
        final ring = Paint()
          ..color = const Color(0xFFD9A441)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        for (final side in const [-1, 1]) {
          canvas.drawCircle(
            Offset(_headCenter.dx + side * _headRx, earY + 3),
            3.2,
            ring,
          );
        }

      case AvatarAccessory.necklace:
        canvas.drawArc(
          const Rect.fromLTWH(42, 70, 16, 12),
          0.15,
          math.pi - 0.3,
          false,
          Paint()
            ..color = const Color(0xFFD9A441)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.1,
        );
        canvas.drawCircle(const Offset(50, 81), 1.6, gold);
    }
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
