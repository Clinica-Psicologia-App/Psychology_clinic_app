// Renderiza as telas do novo fluxo "Minha História / Linha do Tempo" para
// conferir o visual (abertura, etapas do fluxo, trilha vertical).
//
//   flutter test test/tools/render_life_story.dart
//
// Saídas em build/life_story_*.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/life_story/domain/life_story_enums.dart';
import 'package:terapia_esquema/features/life_story/domain/life_timeline_event.dart';
import 'package:terapia_esquema/features/life_story/domain/timeline_person.dart';
import 'package:terapia_esquema/features/life_story/presentation/my_timeline_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/timeline_event_flow_page.dart';
import 'package:terapia_esquema/features/life_story/providers/life_story_providers.dart';

const _events = [
  LifeTimelineEvent(
    id: '1',
    patientId: 'p',
    title: 'Nasceu minha irmã',
    lifeChapter: LifeChapter.childhood,
    ageAtEvent: 5,
    emotions: [TimelineEmotion.happy],
  ),
  LifeTimelineEvent(
    id: '2',
    patientId: 'p',
    title: 'Separação dos meus pais',
    lifeChapter: LifeChapter.childhood,
    ageAtEvent: 8,
    emotions: [TimelineEmotion.sad, TimelineEmotion.afraid],
  ),
  LifeTimelineEvent(
    id: '3',
    patientId: 'p',
    title: 'Entrei na faculdade',
    lifeChapter: LifeChapter.adulthood,
    ageAtEvent: 18,
    emotions: [TimelineEmotion.happy, TimelineEmotion.proud],
  ),
];

const _people = [
  TimelinePerson(id: 'a', fullName: 'Maria', role: RelationshipRole.mother),
  TimelinePerson(id: 'b', fullName: 'João', role: RelationshipRole.father),
  TimelinePerson(id: 'c', fullName: 'Ana', role: RelationshipRole.sister),
];

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

  Future<void> capture(WidgetTester tester, String file) async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
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

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(child: page),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('abertura (convite, sem eventos)', (tester) async {
    await pump(tester, const MyTimelinePage(), overrides: [
      myTimelineProvider.overrideWith((ref) async => <LifeTimelineEvent>[]),
    ]);
    await capture(tester, 'life_story_abertura.png');
  });

  testWidgets('trilha com acontecimentos', (tester) async {
    await pump(tester, const MyTimelinePage(), overrides: [
      myTimelineProvider.overrideWith((ref) async => _events),
    ]);
    await capture(tester, 'life_story_trilha.png');
  });

  testWidgets('fluxo etapa 1 — quando', (tester) async {
    await pump(tester, const TimelineEventFlowPage(), overrides: [
      myTimelinePeopleProvider.overrideWith((ref) async => _people),
    ]);
    await capture(tester, 'life_story_etapa_quando.png');
  });

  testWidgets('fluxo etapa 4 — como se sentiu', (tester) async {
    await pump(tester, const TimelineEventFlowPage(), overrides: [
      myTimelinePeopleProvider.overrideWith((ref) async => _people),
    ]);
    // Avança: quando → o quê (precisa título) → quem → como se sentiu.
    await tester.tap(find.text('Primeiros anos'));
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Separação dos meus pais');
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'life_story_etapa_sentiu.png');
  });
}
