import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Rosto do humor com a boca calculada a partir da nota: em vez de cinco
/// desenhos fixos, a curva varia de 0 a 10, então um 6 e um 7 se distinguem.
/// Usa traço próprio (não emoji do sistema) para ficar igual em todo aparelho
/// e poder herdar a cor da valência.
class MoodFace extends StatelessWidget {
  const MoodFace({
    super.key,
    required this.score,
    this.size = 24,
    this.color,
  });

  /// 0–10. Fora do intervalo é fixado nas pontas.
  final int score;
  final double size;

  /// Quando nulo, usa a cor da valência (vermelho / âmbar / verde).
  final Color? color;

  static Color toneFor(int score) => score >= 7
      ? AppColors.success
      : score >= 4
          ? AppColors.warning
          : AppColors.error;

  /// Palavra que acompanha a nota, para leitor de tela e legendas.
  static String labelFor(int score) => switch (score.clamp(0, 10)) {
        <= 1 => 'Muito baixo',
        <= 3 => 'Baixo',
        <= 6 => 'Neutro',
        <= 8 => 'Bom',
        _ => 'Muito bom',
      };

  @override
  Widget build(BuildContext context) {
    final v = score.clamp(0, 10);
    return Semantics(
      label: 'Humor ${labelFor(v)}, $v de 10',
      child: CustomPaint(
        size: Size.square(size),
        painter: _MoodFacePainter(score: v, color: color ?? toneFor(v)),
      ),
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  _MoodFacePainter({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - size.width * 0.045;
    final stroke = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.075
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, r, stroke);

    final eyeY = center.dy - r * 0.28;
    final eye = Paint()..color = color;
    canvas.drawCircle(Offset(center.dx - r * 0.34, eyeY), r * 0.075 + 0.9, eye);
    canvas.drawCircle(Offset(center.dx + r * 0.34, eyeY), r * 0.075 + 0.9, eye);

    // -1 (cantos para baixo) → +1 (cantos para cima), contínuo.
    final curve = (score / 10) * 2 - 1;
    final mouthY = center.dy + r * 0.26;
    final path = Path()
      ..moveTo(center.dx - r * 0.42, mouthY - curve * r * 0.10)
      ..quadraticBezierTo(
        center.dx,
        mouthY + curve * r * 0.42,
        center.dx + r * 0.42,
        mouthY - curve * r * 0.10,
      );
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_MoodFacePainter old) =>
      old.score != score || old.color != color;
}
