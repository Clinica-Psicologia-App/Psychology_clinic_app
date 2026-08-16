// Renderiza a PatientLibraryWorkPage (experiência do paciente na obra).
//
//   flutter test test/tools/render_library_work_patient.dart
//
// Saída: build/library_work_patient.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_indication.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_work.dart';
import 'package:terapia_esquema/features/patient_library/presentation/patient_library_work_page.dart';
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

  testWidgets('renderiza a obra (paciente)', (tester) async {
    const ind = LibraryIndication(
      id: 'i1',
      status: 'Em andamento',
      activation: 8, // dispara o card de segurança
      work: LibraryWork(
        id: 'w1',
        displayTitle: 'Extraordinário',
        workType: 'Filme',
        year: 2017,
        intensity: 'Alta',
        patientLayer: LibraryPatientLayer(
          before:
              'Esta obra fala sobre se aceitar e se deixar ver. Assista no seu ritmo e pause se perceber ativação emocional intensa.',
          during: [
            'O que desperta identificação ou desconforto.',
            'Como os personagens lidam com o que sentem.',
          ],
          after: [
            LibraryQuestion(question: 'O que mais chamou sua atenção?'),
            LibraryQuestion(
                question: 'Com qual personagem você mais se identificou?'),
            LibraryQuestion(
                question: 'Qual foi a intensidade da ativação emocional?',
                fieldType:
                    'Escala de intensidade da ativação emocional: 0 a 10.'),
          ],
        ),
      ),
    );

    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myLibraryIndicationsProvider.overrideWith((ref) => [ind]),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: Key('cap'),
            child: PatientLibraryWorkPage(indicationId: 'i1'),
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
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/library_work_patient.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/library_work_patient.png');
  });
}
