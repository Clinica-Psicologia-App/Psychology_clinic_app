// Prova visual da Linha do Tempo (Tela 2, lente do terapeuta) com os widgets
// reais da espinha.
//
//   flutter test test/tools/render_timeline_spine.dart
//
// Saída: build/timeline_espinha.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_chapter.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/timeline_entry.dart';
import 'package:terapia_esquema/features/initial_assessment/presentation/widgets/timeline_spine.dart';

TimelineEntry _e(
  String id,
  String title, {
  int? age,
  int? impact,
  LifeChapter? chapter,
  bool sensitive = false,
}) =>
    TimelineEntry(
      id: id,
      patientId: 'p',
      lifeChapter: chapter,
      title: title,
      ageAtEvent: age,
      emotionalImpact: impact,
      isSensitive: sensitive,
    );

// Os mesmos acontecimentos do print do cliente, mais um sem idade e um
// sensível, para ver como o nó se comporta nos extremos.
final _byChapter = <LifeChapter?, List<TimelineEntry>>{
  LifeChapter.childhood: [
    _e('1', 'conflitos',
        age: 8, impact: 7, chapter: LifeChapter.childhood, sensitive: true),
  ],
  LifeChapter.adolescence: [
    _e('2', 'Sozinho', age: 15, impact: 10, chapter: LifeChapter.adolescence),
  ],
  LifeChapter.adulthood: [
    _e('3', 'Novo emprego', age: 18, impact: 8, chapter: LifeChapter.adulthood),
    _e('4', 'Nova rotina', age: 30, impact: 7, chapter: LifeChapter.adulthood),
  ],
  LifeChapter.maturity: [],
  LifeChapter.today: [
    _e('6', 'organizando minha vida profissional e pessoal',
        age: 30, impact: 8, chapter: LifeChapter.today),
  ],
  null: [
    _e('7', 'Momentos felizes', impact: 5),
  ],
};

const _withComment = {'1', '4'};

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      await ui.loadFontFromList(
        File('assets/fonts/$f').readAsBytesSync(),
        fontFamily: 'Poppins',
      );
    }
  });

  testWidgets('linha do tempo com espinha contínua', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 900 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final rows = <Widget>[const TimelineBirthCap()];
    _byChapter.forEach((chapter, entries) {
      rows.add(TimelineChapterMarker(chapter: chapter, onAdd: () {}));
      if (entries.isEmpty) {
        rows.add(const TimelineEmptyChapterHint());
        return;
      }
      for (final entry in entries) {
        rows.add(TimelineEventNode(
          entry: entry,
          chapter: chapter,
          hasComment: _withComment.contains(entry.id),
          onTap: () {},
        ));
      }
    });
    rows.add(const TimelineTodayCap());

    final theme = AppTheme.light;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Poppins'),
      ),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: RepaintBoundary(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/timeline_espinha.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/timeline_espinha.png');
  });
}
