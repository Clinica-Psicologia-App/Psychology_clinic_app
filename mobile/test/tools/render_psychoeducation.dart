// Renderiza a jornada de psicoeducação e o leitor de módulo do paciente.
//
//   flutter test test/tools/render_psychoeducation.dart
//
// Saídas: build/psychoeducation_journey.png, build/psychoeducation_module.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/psychoeducation_module.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/psychoeducation_journey_page.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/psychoeducation_module_page.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/psychoeducation_providers.dart';

const _modules = [
  PsychoeducationModule(
    id: 'm7',
    number: 7,
    stage: 'Compreender',
    title: 'Os Domínios dos Esquemas',
    presentation:
        'Os 18 esquemas se organizam em cinco grandes áreas da vida emocional.',
    accentColor: '#6366F1',
    cards: [
      PsychoeducationCard(
          title: 'Desconexão e Rejeição',
          patientText: 'Necessidades de segurança e vínculo não atendidas.'),
      PsychoeducationCard(
          title: 'Limites Prejudicados',
          patientText: 'Dificuldade com responsabilidade e autodisciplina.'),
    ],
  ),
  PsychoeducationModule(
    id: 'm9',
    number: 9,
    stage: 'Transformar',
    title: 'Reconhecendo Meus Padrões',
    presentation:
        'Da compreensão para a identificação pessoal: perceber quando o padrão aparece.',
    accentColor: '#059669',
    cards: [
      PsychoeducationCard(
        title: 'Quando esse padrão aparece?',
        patientText: 'Observe os momentos em que o padrão se manifesta.',
        reflection: 'Em que situações recentes você percebeu esse padrão?',
      ),
    ],
  ),
  PsychoeducationModule(
    id: 'm12',
    number: 12,
    stage: 'Transformar',
    title: 'Construindo o Adulto Saudável',
    presentation:
        'O começo da transformação: cuidar, escolher e viver com sentido.',
    closing:
        'Você não é definido pelo que aprendeu para sobreviver. Você pode construir novas formas de viver.',
    accentColor: '#059669',
    cards: [
      PsychoeducationCard(
          title: 'Autocompaixão',
          patientText: 'Tratar-se com a gentileza que ofereceria a quem ama.',
          exercise: 'Escreva uma frase gentil para você mesmo hoje.'),
    ],
  ),
];

Future<void> _capture(WidgetTester tester, String file) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
  late final Uint8List png;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    png = bytes!.buffer.asUint8List();
  });
  File('build/$file')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png);
  // ignore: avoid_print
  print('Gerado build/$file');
}

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

  testWidgets('jornada', (tester) async {
    tester.view.physicalSize = const Size(420, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          psychoeducationJourneyProvider.overrideWith((ref) async => _modules),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: const Key('cap'),
            child: PsychoeducationJourneyPage(
              moduleRouteBuilder: (id) => '/patient/psychoeducation/$id',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'psychoeducation_journey.png');
  });

  testWidgets('leitor de módulo', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          psychoeducationJourneyProvider.overrideWith((ref) async => _modules),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: Key('cap'),
            child: PsychoeducationModulePage(moduleId: 'm9'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await _capture(tester, 'psychoeducation_module.png');
  });
}
