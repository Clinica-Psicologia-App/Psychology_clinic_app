// Reproduz a piscada escura do cartão Sim/Não ao selecionar:
// AnimatedContainer anima de scheme.surface (alpha=1.0) para
// scheme.primary.withValues(alpha:0.10) — o alpha cai durante a interpolação,
// tornando o cartão semi-transparente e revelando o fundo.
//
// Este teste FALHA com o código anterior (surface → semi-transparente)
// e PASSA após a correção (primary.alpha=0 → primary.alpha=0.10).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/widgets/question_input_widget.dart';

const _question = QuestionnaireQuestion(
  id: 'q1',
  code: 'Q1',
  text: 'Pergunta sim/não',
  orderIndex: 0,
  answerType: QuestionAnswerType.singleChoice,
  scaleMin: 0,
  scaleMax: 1,
);

void main() {
  testWidgets(
    'cartão Sim/Não sem piscada escura ao selecionar (alpha quadro a quadro)',
    (tester) async {
      int? value;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (context, setState) => QuestionInputWidget(
                    question: _question,
                    value: value,
                    onChanged: (v) => setState(() => value = v),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Localiza o AnimatedContainer ancestral do texto 'Sim' e o DecoratedBox
      // interno que carrega a cor animada quadro a quadro.
      final simText = find.text('Sim');
      final animContainer = find
          .ancestor(of: simText, matching: find.byType(AnimatedContainer))
          .first;
      final decoratedBox = find
          .descendant(of: animContainer, matching: find.byType(DecoratedBox))
          .first;

      Color fill() =>
          (tester.widget<DecoratedBox>(decoratedBox).decoration
              as BoxDecoration)
              .color!;

      final theme = Theme.of(tester.element(simText));
      final bgColor = theme.scaffoldBackgroundColor;
      final scheme = theme.colorScheme;
      final expectedSelected = Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.10), scheme.surface);
      final rest = fill();

      // Repouso deve ser opaco (scheme.surface).
      expect(rest.alpha, equals(255),
          reason: 'repouso deve ser opaco (scheme.surface)');

      // Toca em 'Sim' — inicia a animação de 150 ms (AppAnimations.fast).
      await tester.tap(simText);
      await tester.pump(); // processa o setState e inicia a animação

      // onChanged deve ter recebido 1 (Sim).
      expect(value, equals(1), reason: 'onChanged deve receber 1 ao tocar em Sim');

      // Coleta 10 amostras a 20 ms cada (200 ms > 150 ms de duração).
      final samples = <Color>[];
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        samples.add(fill());
      }

      final selected = samples.last;

      // Selecionado deve ser opaco e igual ao alphaBlend esperado.
      expect(selected.alpha, equals(255),
          reason: 'selecionado deve ser opaco (composto sobre scheme.surface)');
      expect(selected, equals(expectedSelected),
          reason: 'cor final deve ser alphaBlend(primary 10%, surface)');

      // Cada amostra composta sobre o fundo deve ficar no intervalo
      // [repouso, selecionado] em R, G e B — sair é a piscada escura ou clara.
      final a = Color.alphaBlend(rest, bgColor);
      final b = Color.alphaBlend(selected, bgColor);

      for (final s in samples) {
        final c = Color.alphaBlend(s, bgColor);
        for (final (v, x, y) in [
          (c.r, a.r, b.r),
          (c.g, a.g, b.g),
          (c.b, a.b, b.b),
        ]) {
          const tol = 2.0 / 255;
          expect(
            v,
            greaterThanOrEqualTo((x < y ? x : y) - tol),
            reason: 'piscada escura (s=$s, rest=$rest, sel=$selected)',
          );
          expect(
            v,
            lessThanOrEqualTo((x > y ? x : y) + tol),
            reason: 'piscada clara (s=$s, rest=$rest, sel=$selected)',
          );
        }
      }
    },
  );
}
