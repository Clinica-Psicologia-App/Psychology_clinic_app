// Renderiza a ficha clínica (StaffLibraryWorkPage) com dados de exemplo.
//
//   flutter test test/tools/render_library_staff.dart
//
// Saída: build/library_staff_work.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_work.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_work_full.dart';
import 'package:terapia_esquema/features/patient_library/presentation/staff_library_work_page.dart';
import 'package:terapia_esquema/features/patient_library/providers/staff_library_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

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

  testWidgets('renderiza a ficha clínica', (tester) async {
    const work = LibraryWorkFull(
      id: 'w1',
      fichaNumber: 1,
      displayTitle: 'História de um Casamento',
      workType: 'Filme',
      year: 2019,
      duration: '2h17min',
      rating: 'A14',
      synopsis:
          'Nicole e Charlie atravessam um divórcio doloroso, negociações de guarda e a reconstrução de suas identidades após o fim do vínculo.',
      primarySchema: 'Abandono/Instabilidade',
      domain: 'Desconexão e Rejeição',
      associatedSchemas: ['Privação Emocional', 'Padrões Inflexíveis'],
      intensity: 'Moderada',
      psychologist: LibraryPsychologistLayer(
        whenToIndicate: [
          'Pacientes para os quais seja relevante trabalhar luto relacional e comunicação de necessidades.',
          'Pacientes com recursos mínimos de regulação emocional.',
        ],
        objectives: [
          'Reconhecer o luto relacional na vida atual.',
          'Identificar necessidades, esquemas e modos ativados.',
        ],
        observationFocus: [
          'Como os personagens expressam ou evitam necessidades.',
          'O que ativa sofrimento ou hipercompensação.',
        ],
        emotionalMobilizations: [
          'identificação',
          'tristeza',
          'esperança',
          'raiva'
        ],
        clinicalCautions: [
          'Pode intensificar sofrimento em separações recentes ou litígios em andamento.'
        ],
        schemaModes: ['Criança Vulnerável', 'Criança Raivosa', 'Pai Punitivo'],
        sessionInterventions: [
          'Explorar o esquema de Abandono/Instabilidade.',
          'Mapear modos e necessidades ativados pela obra.',
        ],
        sessionQuestions: [
          'Qual personagem mais mobilizou você? Por quê?',
          'Como seu Adulto Saudável responderia?',
        ],
        clinicalNote:
            'Recurso para explorar luto relacional, sempre integrado à conceitualização.',
      ),
      patientLayer: LibraryPatientLayer(
        before:
            'Esta obra convida você a observar comunicação de necessidades. Pause se perceber ativação intensa.',
        after: [
          LibraryQuestion(question: 'O que mais chamou sua atenção?'),
          LibraryQuestion(question: 'Quais emoções apareceram?'),
        ],
      ),
    );

    tester.view.physicalSize = const Size(400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryWorkProvider.overrideWith((ref, id) => work),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const RepaintBoundary(
            key: Key('cap'),
            child: StaffLibraryWorkPage(
              role: ProfileRole.psychologist,
              patientId: 'p1',
              workId: 'w1',
            ),
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
    File('build/library_staff_work.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/library_staff_work.png');
  });
}
