// Preview do visual novo da escala Likert (trilho com gradiente).
//   flutter test test/tools/render_question_scale.dart
// Saída: build/question_scale.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/widgets/question_input_widget.dart';

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  testWidgets('preview escala Likert', (tester) async {
    final question = QuestionnaireQuestion(
      id: 'q1',
      code: 'YSQ_01',
      text: 'Pergunta de exemplo',
      orderIndex: 0,
      answerType: QuestionAnswerType.fromString('likert_scale'),
      scaleMin: 1,
      scaleMax: 6,
    );

    Widget block(String title, int? value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF718096))),
              const SizedBox(height: 14),
              QuestionInputWidget(
                question: question,
                value: value,
                onChanged: (_) {},
              ),
            ],
          ),
        );

    tester.view.physicalSize = const Size(760, 620);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Scaffold(
          backgroundColor: const Color(0xFFEDF1F7),
          body: Center(
            child: RepaintBoundary(
              key: const Key('cap'),
              child: Container(
                width: 720,
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    block('Sem resposta', null),
                    const Divider(),
                    block('Resposta = 4 (selecionado)', 4),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/question_scale.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/question_scale.png');
  });
}
