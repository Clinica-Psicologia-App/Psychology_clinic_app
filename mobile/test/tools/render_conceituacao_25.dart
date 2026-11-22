// Render da síntese (#25) com itens em branco tocáveis, dados fictícios.
//
//   RENDER_OUT=<pasta> flutter test test/tools/render_conceituacao_25.dart
//
// Saída: 25_sintese.png (síntese com itens em branco e 1 preenchido).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/providers/initial_assessment_providers.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_page.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/mental_map/providers/mental_map_providers.dart';
import 'package:terapia_esquema/features/personality_assessment/providers/personality_assessment_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf'
    ]) {
      await ui.loadFontFromList(File('$dir/$f').readAsBytesSync(),
          fontFamily: 'Roboto');
    }
  });

  testWidgets('síntese com itens em branco', (tester) async {
    tester.view.physicalSize = const Size(520, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const role = ProfileRole.psychologist;
    final e = CaseConceptualization.empty();
    final concept = CaseConceptualization(
      unmetNeeds: e.unmetNeeds,
      modeSequences: e.modeSequences,
      relationship: e.relationship,
      centralSchemas: e.centralSchemas,
      therapyObjectives: e.therapyObjectives,
      origins: const CaseOrigins(earlyHistory: 'Infância com várias mudanças.'),
    );
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: ProviderScope(
        overrides: [
          staffMentalMapProvider(const StaffMentalMapContext(
                  role: role, patientId: 'p1'))
              .overrideWith((ref) async => MentalMapData.empty),
          caseConceptualizationProvider('p1').overrideWith((ref) async => concept),
          initialAssessmentProvider(
                  const InitialAssessmentContext(role: role, patientId: 'p1'))
              .overrideWith((ref) async => const InitialAssessment(patientId: 'p1')),
          personalityIntegrationsProvider('p1').overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
          home: const CaseConceptualizationPage(role: role, patientId: 'p1'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final img = (await tester.runAsync(() => b.toImage(pixelRatio: 1.2)))!;
    final png = (await tester
        .runAsync(() => img.toByteData(format: ui.ImageByteFormat.png)))!;
    final out = Platform.environment['RENDER_OUT'] ?? 'build';
    File('$out/25_sintese.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png.buffer.asUint8List());
  });
}
