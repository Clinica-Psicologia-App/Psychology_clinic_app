// Renderiza o HomologationEmptyPanel com os ícones dos estados vazios do mapa
// mental, para conferir visualmente o centramento do glifo sobre o hub.
//
//   flutter test test/tools/render_empty_panel_icons.dart
//
// Saída: build/empty_panel_icons.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/shared/widgets/homologation_ui.dart';

const _icons = <(String, IconData)>[
  ('Problemas', Icons.report_problem_outlined),
  ('Objetivos', Icons.flag_outlined),
  ('Síntese', Icons.psychology_alt_outlined),
  ('Mapa', Icons.hub_outlined),
];

void main() {
  setUpAll(() async {
    final fontBytes = File(
      r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ).readAsBytesSync();
    await ui.loadFontFromList(fontBytes, fontFamily: 'MaterialIcons');
  });

  testWidgets('renderiza estados vazios', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFE9EEF9),
          body: RepaintBoundary(
            key: const Key('p'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, icon) in _icons)
                  // Reproduz o container real (MentalMapSectionCard):
                  // card branco de largura fixa + Column(crossAxisAlignment
                  // .start) com um header full-width que estica a coluna.
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(icon, size: 20, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Cabeçalho da seção')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        HomologationEmptyPanel(
                          icon: icon,
                          title: label,
                          message: 'Estado vazio de exemplo aqui.',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('p')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/empty_panel_icons.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/empty_panel_icons.png');
  });
}
