// Renderiza a PatientLibraryPage real com indicações de exemplo (override do
// provider), validando o fluxo dados → builder → tela.
//
//   flutter test test/tools/render_library_page.dart
//
// Saída: build/library_page.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_indication.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_work.dart';
import 'package:terapia_esquema/features/patient_library/presentation/patient_library_page.dart';
import 'package:terapia_esquema/features/patient_library/providers/patient_library_providers.dart';

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

  LibraryIndication ind(String id, String title, String type, String status,
      {int? year}) {
    return LibraryIndication(
      id: id,
      status: status,
      indicatedAt: DateTime(2026, 8, 1),
      work: LibraryWork(
        id: 'w_$id',
        displayTitle: title,
        workType: type,
        year: year,
        synopsis: 'Uma obra escolhida para conversarmos em sessão.',
        patientLayer: const LibraryPatientLayer(
          before:
              'Assista no seu ritmo e pause se perceber ativação emocional intensa.',
          during: ['O que desperta identificação.', 'Como lidam com limites.'],
        ),
      ),
    );
  }

  testWidgets('renderiza a página da biblioteca', (tester) async {
    final indications = [
      ind('1', 'Extraordinário', 'Filme', 'Indicado', year: 2017),
      ind('2', 'O Lado Bom da Vida', 'Filme', 'Indicado', year: 2012),
      ind('3', 'Falando a Real', 'Série', 'Indicado', year: 2023),
      ind('4', 'À Procura da Felicidade', 'Filme', 'Em andamento', year: 2006),
      ind('5', 'Normal People', 'Minissérie', 'Assistido', year: 2020),
    ];

    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myLibraryIndicationsProvider.overrideWith((ref) => indications),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: Key('cap'),
            child: PatientLibraryPage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/library_page.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/library_page.png');
  });
}
