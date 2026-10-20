import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/widgets/question_input_widget.dart';

void main() {
  for (final instrument in ['YSQ_FOUNDATION_V1', 'YAMI_PM2']) {
    testWidgets('$instrument mostra os extremos completos em tela estreita',
        (tester) async {
      tester.view.physicalSize = const Size(360, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      int? answer;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: QuestionInputWidget(
              questionnaireCode: instrument,
              question: const QuestionnaireQuestion(
                id: 'q', code: 'q1', text: 'Questão', orderIndex: 1,
                answerType: QuestionAnswerType.likertScale,
                scaleMin: 1, scaleMax: 6,
              ),
              value: null,
              onChanged: (value) => answer = value,
            ),
          ),
        ),
      ));
      expect(find.text(instrument.startsWith('YSQ')
          ? '1 = Completamente falso' : '1 = Nunca ou quase nunca'), findsOneWidget);
      expect(find.text(instrument.startsWith('YSQ')
          ? '6 = Descreve-me perfeitamente' : '6 = Quase o tempo todo'), findsOneWidget);
      await tester.tap(find.text('6'));
      await tester.pumpAndSettle();
      expect(answer, 6);
      expect(tester.takeException(), isNull);
    });
  }
}
