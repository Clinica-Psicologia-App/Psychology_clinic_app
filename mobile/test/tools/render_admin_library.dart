// Renderiza a AdminLibraryCatalogPage (curadoria do catálogo).
//
//   flutter test test/tools/render_admin_library.dart
//
// Saída: build/admin_library.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_library/data/admin_library_repository.dart';
import 'package:terapia_esquema/features/patient_library/presentation/admin_library_catalog_page.dart';
import 'package:terapia_esquema/features/patient_library/providers/admin_library_providers.dart';

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

  testWidgets('renderiza o catálogo admin', (tester) async {
    const works = [
      AdminLibraryWork(
        id: 'w1',
        displayTitle: 'História de um Casamento',
        workType: 'Filme',
        year: 2019,
        primarySchema: 'Abandono/Instabilidade',
        intensity: 'Moderada',
        isPublished: true,
      ),
      AdminLibraryWork(
        id: 'w2',
        displayTitle: 'Normal People',
        workType: 'Série',
        year: 2020,
        primarySchema: 'Defectividade/Vergonha',
        intensity: 'Alta',
        isPublished: false,
      ),
      AdminLibraryWork(
        id: 'w3',
        displayTitle: 'Divertida Mente',
        workType: 'Filme',
        year: 2015,
        primarySchema: 'Privação Emocional',
        isPublished: true,
      ),
    ];

    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminLibraryListProvider(null).overrideWith((ref) async => works),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: Key('cap'),
            child: AdminLibraryCatalogPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/admin_library.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/admin_library.png');
  });
}
