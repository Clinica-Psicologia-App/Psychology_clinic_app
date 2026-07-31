// Gerador dos assets de ícone do launcher (marca EsquemaCore).
// Fora da suíte automática (sem sufixo _test) — rodar manualmente:
//   flutter test test/tools/generate_brand_icon.dart
//   dart run flutter_launcher_icons
//
// Visual (alinhado ao guia da marca): cérebro em gradiente
// turquesa→ciano→azul→roxo sobre fundo branco, centralizado.
//
// Saídas em assets/branding/:
//   esquema_core_icon.png            — fundo branco + cérebro gradiente
//   esquema_core_icon_foreground.png — cérebro gradiente em fundo transparente
//   esquema_core_icon_bg.png         — fundo branco (adaptive background)

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;

const _turquoise = Color(0xFF00B2A9);
const _cyan = Color(0xFF0096D6);
const _blue = Color(0xFF3B82F6);
const _purple = Color(0xFF7B5CF6);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('gera assets de ícone da marca', () async {
    final dir = Directory('assets/branding');
    expect(dir.existsSync(), isTrue,
        reason: 'Rodar a partir da raiz do pacote mobile/');

    await _writePng('assets/branding/esquema_core_icon.png', (canvas) {
      _paintWhite(canvas);
      _paintMark(canvas, scale: 0.94);
    });

    await _writePng('assets/branding/esquema_core_icon_foreground.png',
        (canvas) {
      _paintMark(canvas, scale: 0.72);
    });

    await _writePng('assets/branding/esquema_core_icon_bg.png', (canvas) {
      _paintWhite(canvas);
    });
  });
}

Future<void> _writePng(
  String path,
  void Function(Canvas canvas) paint,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  image.dispose();
}

void _paintWhite(Canvas canvas) {
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, _size, _size),
    Paint()..color = Colors.white,
  );
}

/// Shader do gradiente da marca. A caixa cobre apenas a massa do cérebro
/// para o gradiente atravessar a área visível (turquesa → roxo); os nós
/// externos herdam as cores das extremidades, como no guia.
Shader _brandShader() => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_turquoise, _cyan, _blue, _purple],
      stops: [0.02, 0.34, 0.62, 0.92],
    ).createShader(const Rect.fromLTRB(235, 260, 790, 730));

/// Desenha o cérebro em gradiente com rede de nós. Coordenadas de design em
/// 1024×1024; `scale` reduz o conteúdo mantendo o centro (safe zone adaptive).
/// Os "furos" (fissura, spokes, anéis) revelam o fundo por trás.
void _paintMark(Canvas canvas, {required double scale}) {
  canvas.saveLayer(const Rect.fromLTWH(0, 0, _size, _size), Paint());
  canvas.translate(_size / 2 * (1 - scale), _size / 2 * (1 - scale));
  canvas.scale(scale);
  // Centraliza a massa do desenho (bounds ≈ 118..915 × 200..820)
  canvas.translate(-4.5, 2);

  final ink = Paint()
    ..shader = _brandShader()
    ..isAntiAlias = true;
  final clearFill = Paint()
    ..blendMode = BlendMode.clear
    ..isAntiAlias = true;
  Paint clearStroke(double width) => Paint()
    ..blendMode = BlendMode.clear
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;
  Paint inkStroke(double width) => Paint()
    ..shader = _brandShader()
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  // ── Silhueta do cérebro: bumps sobrepostos + elipse unificadora ──
  const bumps = [
    (Offset(400, 330), 100.0),
    (Offset(545, 300), 95.0),
    (Offset(665, 355), 90.0),
    (Offset(300, 435), 95.0),
    (Offset(725, 465), 85.0),
    (Offset(320, 565), 90.0),
    (Offset(700, 585), 80.0),
    (Offset(450, 625), 95.0),
    (Offset(595, 635), 90.0),
  ];
  for (final (center, radius) in bumps) {
    canvas.drawCircle(center, radius, ink);
  }
  canvas.drawOval(
    Rect.fromCenter(center: const Offset(512, 475), width: 470, height: 350),
    ink,
  );

  // Cauda inferior direita (flick da marca) — extremidades dentro da massa
  final tail = Path()
    ..moveTo(575, 690)
    ..quadraticBezierTo(615, 795, 680, 820)
    ..quadraticBezierTo(700, 745, 750, 630)
    ..close();
  canvas.drawPath(tail, ink);

  // ── Fissura central (revela o fundo) ──
  final fissure = Path()
    ..moveTo(512, 300)
    ..cubicTo(500, 380, 524, 420, 512, 490)
    ..cubicTo(502, 545, 520, 590, 512, 640);
  canvas.drawPath(fissure, clearStroke(20));

  // ── Conectores externos (linhas gradiente + anéis fora da silhueta) ──
  canvas.drawLine(
      const Offset(300, 445), const Offset(148, 398), inkStroke(14));
  canvas.drawLine(
      const Offset(640, 345), const Offset(795, 230), inkStroke(14));
  canvas.drawLine(
      const Offset(720, 530), const Offset(885, 545), inkStroke(14));

  // ── Rede interna: spokes do hub para os nós ──
  const hub = Offset(512, 485);
  const nodes = [
    Offset(398, 372),
    Offset(630, 368),
    Offset(362, 545),
    Offset(662, 550),
    Offset(455, 632),
  ];
  for (final node in nodes) {
    canvas.drawLine(hub, node, clearStroke(12));
  }

  // Nós internos: furo + ponto gradiente central
  for (final node in nodes) {
    canvas.drawCircle(node, 20, clearFill);
    canvas.drawCircle(node, 9, ink);
  }

  // Hub central: furo maior + ponto gradiente
  canvas.drawCircle(hub, 44, clearFill);
  canvas.drawCircle(hub, 21, ink);

  // Nós externos: anel gradiente com centro vazado
  const externalNodes = [Offset(148, 398), Offset(795, 230), Offset(885, 545)];
  for (final node in externalNodes) {
    canvas.drawCircle(node, 30, ink);
    canvas.drawCircle(node, 14, clearFill);
  }

  canvas.restore();
}
