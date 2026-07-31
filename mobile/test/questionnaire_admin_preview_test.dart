import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_session.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_answer_page.dart';

void main() {
  testWidgets('admin preview finishes without backend persistence',
      (tester) async {
    const session = QuestionnaireSession(
      responseId: 'admin-preview-test',
      patientId: 'admin-preview',
      questionnaire: Questionnaire(
        id: 'questionnaire-id',
        code: 'CUSTOM_TEST',
        name: 'Questionário de teste',
        isActive: true,
        clinicalStatus: QuestionnaireClinicalStatus.approved,
      ),
      questions: [
        QuestionnaireQuestion(
          id: 'question-id',
          code: 'Q1',
          text: 'Pergunta teste',
          orderIndex: 0,
          answerType: QuestionAnswerType.likertScale,
          scaleMin: 1,
          scaleMax: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: QuestionnaireAnswerPage(
            session: session,
            role: ProfileRole.platformAdmin,
            previewMode: true,
          ),
        ),
      ),
    );

    expect(find.textContaining('não serão salvas'), findsOneWidget);

    await tester.tap(find.text('1'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Finalizar'));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pré-visualização concluída'), findsOneWidget);
    expect(find.textContaining('Nenhuma resposta'), findsOneWidget);
  });
}
