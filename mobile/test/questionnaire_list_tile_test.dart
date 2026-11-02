import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/widgets/questionnaire_list_tile.dart';

void main() {
  testWidgets('nome longo e descrição completa quebram linha sem cortar',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const description =
        'Este questionário ajuda a identificar maneiras de reagir a situações difíceis, especialmente quando você tenta se proteger de sentimentos de vulnerabilidade.';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: QuestionnaireListTile(
              questionnaire: const Questionnaire(
                id: '1',
                code: 'YCI_FOUNDATION_V1',
                name: 'YCI — Inventário de Compensação de Young',
                description: description,
                isActive: true,
              ),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('YCI — Inventário de Compensação de Young'),
        findsOneWidget);
    final desc = tester.widget<Text>(find.text(description));
    expect(desc.maxLines, isNull);
    expect(desc.overflow, isNot(TextOverflow.ellipsis));
  });
}
