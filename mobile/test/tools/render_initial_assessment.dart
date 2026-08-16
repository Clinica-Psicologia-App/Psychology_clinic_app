// Renderiza a tela de Conceitualização inicial (lente do terapeuta) com dados
// de exemplo, para conferência visual do redesenho.
//
//   flutter test test/tools/render_initial_assessment.dart
//
// Saída: build/initial_assessment.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/patient_intake.dart';
import 'package:terapia_esquema/features/initial_assessment/presentation/initial_assessment_therapist_page.dart';
import 'package:terapia_esquema/features/initial_assessment/providers/initial_assessment_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  setUpAll(() async {
    final fontBytes = File(
      r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ).readAsBytesSync();
    await ui.loadFontFromList(fontBytes, fontFamily: 'MaterialIcons');
  });

  testWidgets('renderiza conceitualização inicial', (tester) async {
    final areas = kLifeAreasInOrder;
    final sample = InitialAssessment(
      patientId: 'p1',
      intake: const PatientIntake(
        reasonForSeeking:
            'Estou tendo problemas na minha área profissional, não consigo evoluir.',
        problemDuration: 'um ano',
        mainDiscomfort: 'Não conseguir uma promoção no trabalho',
        expectations: 'Poder ser um profissional melhor no trabalho.',
        relatedEvent:
            'Não consigo ter confiança e atitude para fazer tais coisas.',
      ),
      lifeAreas: [
        LifeAreaAssessment(
          area: areas[0],
          score: 7,
          suffering: 3,
          guidedAnswer:
              'Tenho me dedicado, mas sinto que falta reconhecimento.',
        ),
        LifeAreaAssessment(
          area: areas[1],
          score: 4,
          suffering: 6,
          guidedAnswer: 'Sinto que estagnei e isso me angustia.',
        ),
      ],
    );

    tester.view.physicalSize = const Size(460, 2100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          initialAssessmentProvider.overrideWith((ref, ctx) => sample),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: Key('cap'),
            child: InitialAssessmentTherapistPage(
              role: ProfileRole.psychologist,
              patientId: 'p1',
            ),
          ),
        ),
      ),
    );
    // Resolve o provider e deixa o shimmer/entrada assentar.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('cap')),
    );
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/initial_assessment.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/initial_assessment.png');
  });
}
