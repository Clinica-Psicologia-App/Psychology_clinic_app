// Renderiza as telas do questionário que mudaram na revisão de telas 1:
// apresentação, tela de resposta (escala com significado) e confirmação.
//
//   flutter test test/tools/render_questionnaire_screens.dart
//
// Saída: build/q_intro.png, q_answer.png, q_success.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/questionnaires/domain/finish_questionnaire_result.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_session.dart';
import 'package:terapia_esquema/features/questionnaires/domain/reference_period.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_answer_page.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_intro_page.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_success_page.dart';

const _yami = Questionnaire(
  id: 'q-yami',
  code: 'YAMI_MODES_FOUNDATION_V1',
  name: 'YAMI — Inventário de Modos Esquemáticos de Young',
  description:
      'Este questionário ajuda a identificar diferentes estados emocionais e '
      'maneiras de pensar e agir que podem surgir em determinadas situações.',
  isActive: true,
  referencePeriod: ReferencePeriod.lastMonth,
  patientContent: PatientContent(
    intro: 'Antes de começar, leia as orientações com atenção. Suas respostas '
        'ajudarão você e seu psicólogo a compreender melhor suas experiências '
        'emocionais e seus padrões de comportamento.',
    howToRespond:
        'Leia cada afirmação com atenção e considere com que frequência você '
        'acreditou ou sentiu o que está descrito durante o último mês. '
        'Escolha uma das seis opções da escala, selecionando aquela que melhor '
        'corresponde à sua experiência.',
    referencePeriodText:
        'Responda considerando suas experiências, emoções e comportamentos '
        'durante o último mês.',
    fixedQuestion: 'Com que frequência você sentiu isso no último mês?',
    scaleLabels: [
      'Nunca ou quase nunca',
      'Raramente',
      'Às vezes',
      'Muitas vezes',
      'Grande parte do tempo',
      'Quase o tempo todo',
    ],
    followUp:
        'Suas respostas ficarão disponíveis para seu psicólogo e poderão '
        'contribuir para a compreensão dos seus padrões emocionais e de '
        'enfrentamento ao longo do processo terapêutico.',
  ),
);

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir/materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf'
    ]) {
      await ui.loadFontFromList(
        File('$dir/$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
    // Fonte do tema do app (sem ela o texto sai em blocos).
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      await ui.loadFontFromList(
        File('assets/fonts/$f').readAsBytesSync(),
        fontFamily: 'Poppins',
      );
    }
  });

  Future<void> shot(WidgetTester tester, String name, Widget page,
      {Future<void> Function()? after, int waitMs = 1500}) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: RepaintBoundary(key: const Key('cap'), child: page),
        ),
      ),
    );
    for (var i = 0; i < waitMs ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (after != null) {
      await after();
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/$name.png');
  }

  testWidgets('apresentação', (tester) async {
    await shot(
      tester,
      'q_intro',
      const QuestionnaireIntroPage(
        questionnaire: _yami,
        patientId: 'p1',
        role: ProfileRole.patient,
      ),
    );
  });

  testWidgets('tela de resposta com o significado da opção', (tester) async {
    final questions = [
      for (var i = 0; i < 12; i++)
        QuestionnaireQuestion(
          id: 'q$i',
          code: 'YAMI_${i + 1}',
          text: i == 0
              ? 'Sinto que ninguém me compreende de verdade.'
              : 'Afirmação de exemplo ${i + 1}.',
          orderIndex: i,
          answerType: QuestionAnswerType.fromString('likert_scale'),
          scaleMin: 1,
          scaleMax: 6,
        ),
    ];
    await shot(
      tester,
      'q_answer',
      QuestionnaireAnswerPage(
        session: QuestionnaireSession(
          responseId: 'r1',
          patientId: 'p1',
          questionnaire: _yami,
          questions: questions,
        ),
        role: ProfileRole.patient,
        previewMode: true,
      ),
      after: () async {
        final three = find.text('3');
        if (three.evaluate().isNotEmpty) {
          await tester.tap(three.first);
        }
      },
    );
  });

  testWidgets('confirmação de envio', (tester) async {
    await shot(
      tester,
      'q_success',
      QuestionnaireSuccessPage(
        result: FinishQuestionnaireResult(
          responseId: 'r1',
          questionnaireName: 'YAMI — Inventário de Modos Esquemáticos de Young',
          completedAt: DateTime(2026, 11, 2, 14, 30),
          resultsCount: 1,
          followUpText: _yami.patientContent.followUp,
        ),
        role: ProfileRole.patient,
      ),
      waitMs: 2500,
    );
  });
}
