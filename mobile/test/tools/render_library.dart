// Preview da Biblioteca Netflix com títulos REAIS do catálogo (93 obras),
// agrupados em prateleiras acolhedoras (sem nome de esquema, como manda o doc).
//
//   flutter test test/tools/render_library.dart
//
// Saída: build/library.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_content.dart';
import 'package:terapia_esquema/features/patient_library/presentation/widgets/patient_library_view.dart';

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf'
    ]) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  // Paleta de gradientes cinematográficos (placeholders até as capas reais).
  const gr = <List<Color>>[
    [Color(0xFF3B2F8F), Color(0xFF11808F)],
    [Color(0xFF7A2E5D), Color(0xFF2B1030)],
    [Color(0xFF1F6FEB), Color(0xFF0B2A5B)],
    [Color(0xFFB5462A), Color(0xFF3A150C)],
    [Color(0xFF2E7D57), Color(0xFF0F2E22)],
    [Color(0xFFC79A17), Color(0xFF4A3708)],
    [Color(0xFF9B2C6F), Color(0xFF35102A)],
    [Color(0xFF2A9D9A), Color(0xFF0E3A3A)],
    [Color(0xFF334155), Color(0xFF0F172A)],
    [Color(0xFF3B0764), Color(0xFF16032B)],
  ];

  int gi = 0;
  LibraryItem work(String title, String sub, String tipo,
      {bool isNew = false, double? progress}) {
    final g = gr[gi++ % gr.length];
    final icon = tipo == 'Série'
        ? Icons.live_tv_outlined
        : tipo == 'Minissérie'
            ? Icons.subscriptions_outlined
            : Icons.movie_outlined;
    return LibraryItem(
      id: title,
      title: title,
      subtitle: sub,
      badge: tipo,
      badgeIcon: icon,
      coverGradient: g,
      isNew: isNew,
      progress: progress,
    );
  }

  final content = LibraryContent(
    hero: const LibraryHero(
      title: 'Extraordinário',
      tagline:
          'Sobre se aceitar e se deixar ver — indicado pelo seu psicólogo para conversarmos sobre autoimagem e vínculos.',
      eyebrow: 'Indicado pelo seu psicólogo',
      coverGradient: [Color(0xFF1F6FEB), Color(0xFF0B2A5B)],
    ),
    rows: [
      LibraryRow(
        title: 'Continue assistindo',
        layout: LibraryRowLayout.landscape,
        items: [
          work('À Procura da Felicidade', 'Filme', 'Filme', progress: 0.6),
          work('Ted Lasso', 'Série', 'Série', progress: 0.25),
        ],
      ),
      LibraryRow(
        title: 'Indicados pelo seu psicólogo',
        subtitle: 'Selecionados a partir da sua conceitualização',
        items: [
          work('Extraordinário', 'Autoimagem', 'Filme', isNew: true),
          work('O Lado Bom da Vida', 'Recomeços', 'Filme'),
          work('Falando a Real', 'Cuidado', 'Série'),
          work('Soul', 'Sentido de vida', 'Filme'),
          work('Ainda Alice', 'Aceitação', 'Filme'),
        ],
      ),
      LibraryRow(
        title: 'Vínculos e relações',
        items: [
          work('This Is Us', 'Família', 'Série'),
          work('Normal People', 'Intimidade', 'Minissérie', isNew: true),
          work('Vidas Passadas', 'Escolhas', 'Filme'),
          work('História de um Casamento', 'Separação', 'Filme'),
          work('Big Little Lies', 'Segredos', 'Série'),
        ],
      ),
      LibraryRow(
        title: 'Sentir-se cuidado',
        items: [
          work('Manchester à Beira-Mar', 'Luto', 'Filme'),
          work('After Life', 'Reconstrução', 'Série'),
          work('Ela', 'Solidão', 'Filme'),
          work('Dias Perfeitos', 'Presença', 'Filme'),
          work('Meu Bolo Favorito', 'Afeto', 'Filme'),
        ],
      ),
      LibraryRow(
        title: 'Autoimagem e valor próprio',
        items: [
          work('A Baleia', 'Vergonha', 'Filme'),
          work('Rocketman', 'Aceitação', 'Filme'),
          work('Cisne Negro', 'Perfeição', 'Filme'),
          work('O Diabo Veste Prada', 'Aprovação', 'Filme'),
          work('Whiplash', 'Autoexigência', 'Filme'),
        ],
      ),
      LibraryRow(
        title: 'Pertencer e se conectar',
        items: [
          work('As Vantagens de Ser Invisível', 'Pertencer', 'Filme'),
          work('Heartstopper', 'Primeiros vínculos', 'Série', isNew: true),
          work('Pequena Miss Sunshine', 'Família', 'Filme'),
          work('Soul', 'Propósito', 'Filme'),
        ],
      ),
    ],
  );

  testWidgets('preview biblioteca netflix', (tester) async {
    tester.view.physicalSize = const Size(390, 1700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('cap'),
            child: PatientLibraryView(content: content),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/library.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/library.png');
  });
}
