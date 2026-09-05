// Comparação dos três tratamentos possíveis para a carinha de humor.
//
//   flutter test test/tools/render_mood_faces.dart
//
// Saída: build/mood_faces.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';

const _scores = [1, 3, 5, 7, 9];
const _emoji = ['😭', '😞', '😐', '🙂', '😄'];
const _icons = [
  Icons.sentiment_very_dissatisfied_rounded,
  Icons.sentiment_dissatisfied_rounded,
  Icons.sentiment_neutral_rounded,
  Icons.sentiment_satisfied_rounded,
  Icons.sentiment_very_satisfied_rounded,
];

Color _tone(int v) => v >= 7
    ? AppColors.success
    : v >= 4
        ? AppColors.warning
        : AppColors.error;

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      await ui.loadFontFromList(
        File('assets/fonts/$f').readAsBytesSync(),
        fontFamily: 'Poppins',
      );
    }
  });

  testWidgets('três tratamentos da carinha', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 430 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final theme = AppTheme.light;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Poppins'),
      ),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: RepaintBoundary(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Row(
                  title: 'A · Emoji do sistema',
                  note: 'É o que o app já usa hoje no resumo do check-in.',
                ),
                _Strip(builder: (i) => Text(_emoji[i],
                    style: const TextStyle(fontSize: 20))),
                const SizedBox(height: 26),
                const _Row(
                  title: 'B · Ícone da fonte do app',
                  note: 'Mesmo desenho em todo aparelho, e herda a cor.',
                ),
                _Strip(
                    builder: (i) => Icon(_icons[i],
                        size: 21, color: _tone(_scores[i]))),
                const SizedBox(height: 26),
                const _Row(
                  title: 'C · Rosto desenhado',
                  note: 'Traço próprio: a boca acompanha a nota.',
                ),
                _Strip(
                    builder: (i) => CustomPaint(
                          size: const Size(24, 24),
                          painter: _FacePainter(_scores[i]),
                        )),
              ],
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/mood_faces.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/mood_faces.png');
  });
}

class _Row extends StatelessWidget {
  const _Row({required this.title, required this.note});
  final String title;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.navy)),
        Text(note,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textMuted)),
        const SizedBox(height: 10),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.builder});
  final Widget Function(int i) builder;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Column(children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _tone(_scores[i]).withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: builder(i),
            ),
            const SizedBox(height: 4),
            Text('${_scores[i]}',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _tone(_scores[i]))),
          ]),
        ],
      ],
    );
  }
}

/// Rosto simples cuja boca curva com a nota (0 = triste, 10 = feliz).
class _FacePainter extends CustomPainter {
  _FacePainter(this.score);
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final color = _tone(score);
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1;

    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(c, r, stroke);
    final eyeY = c.dy - r * 0.28;
    final eye = Paint()..color = color;
    canvas.drawCircle(Offset(c.dx - r * 0.34, eyeY), 1.6, eye);
    canvas.drawCircle(Offset(c.dx + r * 0.34, eyeY), 1.6, eye);

    // -1 (canto para baixo) → +1 (canto para cima)
    final curve = (score / 10) * 2 - 1;
    final mouthY = c.dy + r * 0.26;
    final path = Path()
      ..moveTo(c.dx - r * 0.42, mouthY - curve * r * 0.1)
      ..quadraticBezierTo(
          c.dx, mouthY + curve * r * 0.42, c.dx + r * 0.42, mouthY - curve * r * 0.1);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.score != score;
}
