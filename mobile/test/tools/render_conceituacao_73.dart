// Render do campo 7.3 do editor da conceitualização (#29), dados fictícios.
//
//   RENDER_OUT=<pasta> flutter test test/tools/render_conceituacao_73.dart
//
// Saída: 29_campo_73.png (com resultado, após "Trazer da Personalidade") e
// 29_campo_73_sem_resultado.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_edit_page.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_assessment.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_instrument.dart';
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

  final out = Platform.environment['RENDER_OUT'] ?? 'build';

  for (final withResult in [true, false]) {
    testWidgets('7.3 ${withResult ? 'com' : 'sem'} resultado', (tester) async {
      tester.view.physicalSize = const Size(520, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final when = DateTime(2026, 11, 1);
      final list = withResult
          ? [
              PersonalityAssessment(
                id: 'a',
                patientId: 'p1',
                instrument: 'NEO_PI_R',
                createdAt: when,
                updatedAt: when,
                appliedOn: when,
                results: const PersonalityResults(domains: {
                  'neuroticism':
                      DomainResult(overall: ScoreEntry(level: PersonalityLevel.high)),
                  'extraversion':
                      DomainResult(overall: ScoreEntry(level: PersonalityLevel.low)),
                  'openness':
                      DomainResult(overall: ScoreEntry(level: PersonalityLevel.medium)),
                  'agreeableness': DomainResult(
                      overall: ScoreEntry(level: PersonalityLevel.veryHigh)),
                  'conscientiousness':
                      DomainResult(overall: ScoreEntry(level: PersonalityLevel.low)),
                }),
              ),
            ]
          : <PersonalityAssessment>[];
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ProviderScope(
          overrides: [
            caseConceptualizationProvider('p1')
                .overrideWith((ref) async => CaseConceptualization.empty()),
            personalityAssessmentsProvider('p1')
                .overrideWith((ref) async => list),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
            home: const CaseConceptualizationEditPage(
              role: ProfileRole.psychologist,
              patientId: 'p1',
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final field = find.widgetWithText(TextField, 'Temperamento / biológico');
      await tester.scrollUntilVisible(field, 300,
          scrollable: find.byType(Scrollable).first);
      await tester.enterText(field, 'Irritabilidade desde a infância.');
      await tester.pump();
      if (withResult) {
        await tester.ensureVisible(find.byKey(const Key('edit_pull_personality')));
        tester
            .widget<OutlinedButton>(find.byKey(const Key('edit_pull_personality')))
            .onPressed!();
        await tester.pump();
      }
      await Scrollable.ensureVisible(
          tester.element(find.textContaining('7.3 ·')),
          alignment: 0.05);
      await tester.pumpAndSettle();
      final b = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final img = (await tester.runAsync(() => b.toImage(pixelRatio: 1.5)))!;
      final png = (await tester.runAsync(
          () => img.toByteData(format: ui.ImageByteFormat.png)))!;
      File('$out/${withResult ? '29_campo_73' : '29_campo_73_sem_resultado'}.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(png.buffer.asUint8List());
    });
  }
}
