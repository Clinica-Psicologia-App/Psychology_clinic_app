// Renderiza a trilha do paciente com a atmosfera de fundo para conferir o
// acabamento visual do redesign ("naturalismo abstrato").
//
//   flutter test test/tools/render_journey_trail.dart
//
// Saída: build/journey_trail.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/patient_journey/presentation/widgets/journey_ambience.dart';
import 'package:terapia_esquema/features/patient_journey/presentation/widgets/journey_trail.dart';

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
      'roboto-black.ttf',
    ]) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  testWidgets('trilha com atmosfera', (tester) async {
    tester.view.physicalSize = const Size(390, 820);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Progresso parcial: exercita trecho concluído (luz correndo), nó em
    // andamento com anel preenchido e trecho pendente pontilhado.
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 5,
      completedQuestionnaireCount: 2,
      hasMonitorToday: true,
      releasedResourceCount: 4,
      completedResourceCount: 1,
      activeTherapyGoalCount: 3,
      completedTherapyGoalCount: 2,
      totalProblemCount: 4,
      openProblemCount: 1,
      hasCheckInToday: false,
      timelineEventCount: 6,
      genogramPeopleCount: 5,
      genogramRelationshipCount: 4,
      checkInCount: 8,
      dailyMonitorCount: 12,
      hasYsqStructuredResult: true,
      hasYamiStructuredResult: false,
    );
    final steps = buildPatientJourneySteps(progress);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: RepaintBoundary(
            key: const Key('cap'),
            child: Stack(
              children: [
                const Positioned.fill(child: JourneyAmbience()),
                JourneyTrail(steps: steps, onStepTap: (_) {}),
              ],
            ),
          ),
        ),
      ),
    );

    Future<void> capture(String file) async {
      final boundary = tester
          .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
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

    // A entrada usa Future.delayed por item; vários pumps drenam os timers.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await capture('journey_trail.png');

    // Frames posteriores mostram as partículas em outra posição do ciclo.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
    await capture('journey_trail_b.png');
  });
}
