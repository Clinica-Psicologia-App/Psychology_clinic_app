import 'package:flutter/material.dart';

/// Marca do cérebro EsquemaCore desenhada em vetor — mesma geometria do
/// ícone do launcher. Ideal para fundos de gradiente/escuros onde os PNGs
/// da marca não funcionam (bordas recortadas).
///
/// Os "furos" (fissura, spokes, anéis dos nós) são transparentes e revelam
/// o fundo por trás, como no ícone oficial.
class BrandBrainMark extends StatelessWidget {
  const BrandBrainMark({
    super.key,
    required this.size,
    this.color = Colors.white,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(size, size),
          painter: _BrainMarkPainter(color: color),
        ),
      ),
    );
  }
}

class _BrainMarkPainter extends CustomPainter {
  const _BrainMarkPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Geometria de design em 1024×1024 (idêntica ao gerador do ícone)
    final scale = size.width / 1024;
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.scale(scale);
    canvas.translate(-4.5, 2);

    final ink = Paint()
      ..color = color
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
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

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

    final tail = Path()
      ..moveTo(575, 690)
      ..quadraticBezierTo(615, 795, 680, 820)
      ..quadraticBezierTo(700, 745, 750, 630)
      ..close();
    canvas.drawPath(tail, ink);

    final fissure = Path()
      ..moveTo(512, 300)
      ..cubicTo(500, 380, 524, 420, 512, 490)
      ..cubicTo(502, 545, 520, 590, 512, 640);
    canvas.drawPath(fissure, clearStroke(20));

    canvas.drawLine(
        const Offset(300, 445), const Offset(148, 398), inkStroke(14));
    canvas.drawLine(
        const Offset(640, 345), const Offset(795, 230), inkStroke(14));
    canvas.drawLine(
        const Offset(720, 530), const Offset(885, 545), inkStroke(14));

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
    for (final node in nodes) {
      canvas.drawCircle(node, 20, clearFill);
      canvas.drawCircle(node, 9, ink);
    }
    canvas.drawCircle(hub, 44, clearFill);
    canvas.drawCircle(hub, 21, ink);

    const externalNodes = [
      Offset(148, 398),
      Offset(795, 230),
      Offset(885, 545),
    ];
    for (final node in externalNodes) {
      canvas.drawCircle(node, 30, ink);
      canvas.drawCircle(node, 14, clearFill);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_BrainMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
