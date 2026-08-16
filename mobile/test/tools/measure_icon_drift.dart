// Mede, por pixel, o quanto a "tinta" de cada glifo pende para um lado dentro
// da sua caixa. Não é teste de regressão — é uma ferramenta de medição.
//
//   flutter test test/tools/measure_icon_drift.dart
//
// Para cada ícone, renderiza o glifo grande (256px) e centralizado numa caixa,
// varre o canal alfa e calcula o centroide da tinta. O desvio é a diferença
// entre esse centroide e o centro geométrico, expresso como fração do tamanho
// do ícone (para valer em qualquer tamanho de render).
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _icons = <(String, IconData)>[
  ('report_problem_outlined', Icons.report_problem_outlined),
  ('flag_outlined', Icons.flag_outlined),
  ('hub_outlined', Icons.hub_outlined),
  ('psychology_alt_outlined', Icons.psychology_alt_outlined),
  ('shield_outlined', Icons.shield_outlined),
  ('favorite_border', Icons.favorite_border),
  ('self_improvement_outlined', Icons.self_improvement_outlined),
  ('timeline_outlined', Icons.timeline_outlined),
  ('analytics_outlined', Icons.analytics_outlined),
  ('schema_outlined', Icons.schema_outlined),
];

void main() {
  setUpAll(() async {
    final fontBytes = File(
      r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ).readAsBytesSync();
    await ui.loadFontFromList(fontBytes, fontFamily: 'MaterialIcons');
  });

  testWidgets('mede o desvio óptico de cada glifo', (tester) async {
    const box = 320.0;
    const glyph = 256.0;

    tester.view.physicalSize = const Size(box, box);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final results = <String>[];

    for (final (name, icon) in _icons) {
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: const Key('b'),
            child: Container(
              width: box,
              height: box,
              color: Colors.white,
              child: Center(
                child: Icon(icon, size: glyph, color: Colors.black),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 40));

      final boundary = tester
          .renderObject<RenderRepaintBoundary>(find.byKey(const Key('b')));
      // As operações de imagem completam na thread de raster — exigem
      // runAsync() no ambiente de teste, senão o Future nunca completa.
      late final ByteData data;
      late final int w;
      late final int h;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.0);
        data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        w = image.width;
        h = image.height;
      });
      final bytes = data.buffer.asUint8List();

      // Centroide da tinta: pixels escuros (o glifo é preto sobre branco).
      double sumX = 0, sumY = 0, mass = 0;
      for (var y = 0; y < h; y++) {
        for (var x = 0; x < w; x++) {
          final i = (y * w + x) * 4;
          // "Tinta" = quão escuro (255 - luminância aproximada pelo R).
          final ink = 255 - bytes[i];
          if (ink > 20) {
            sumX += x * ink;
            sumY += y * ink;
            mass += ink;
          }
        }
      }

      final cx = sumX / mass;
      final cy = sumY / mass;
      // Desvio em relação ao centro da caixa, como fração do tamanho do glifo.
      final driftX = (cx - w / 2) / glyph;
      final driftY = (cy - h / 2) / glyph;
      results.add(
        '$name: dx=${driftX.toStringAsFixed(4)} dy=${driftY.toStringAsFixed(4)}',
      );
    }

    // ignore: avoid_print
    print('=== DESVIO ÓPTICO (fração do tamanho do ícone) ===');
    for (final r in results) {
      // ignore: avoid_print
      print(r);
    }
  });
}
