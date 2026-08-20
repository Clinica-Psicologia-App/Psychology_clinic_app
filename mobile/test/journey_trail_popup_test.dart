// Cobre a correção de um bug real: o balão de detalhe de um nó abria sempre
// para cima, então o primeiro nó da trilha (perto do topo da tela, logo
// abaixo do cabeçalho) mostrava um balão parcialmente fora da viewport — o
// botão de ação ficava inacessível, e o toque parecia não fazer nada.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/presentation/widgets/journey_trail.dart';

void main() {
  Future<void> pumpTrail(
    WidgetTester tester, {
    required double height,
  }) async {
    tester.view.physicalSize = Size(390, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final steps = buildPatientJourneySteps(null);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: JourneyTrail(steps: steps, onStepTap: (_) {}),
        ),
      ),
    );
    // Sem pumpAndSettle: o anel do nó atual e a atmosfera de fundo animam em
    // loop infinito, então nunca "assenta". A entrada usa Future.delayed por
    // item (MotionReveal) — drena com pumps fixos, como no render de teste.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  testWidgets(
    'balão do primeiro nó (perto do topo) abre por baixo, dentro da tela',
    (tester) async {
      await pumpTrail(tester, height: 820);

      // O rótulo abaixo do nó não tem gesture — só a área do círculo com o
      // ícone responde ao toque (o ícone aparece duas vezes por nó, ícone
      // principal + cópia clara para o efeito de relevo).
      await tester.tap(
        find.byIcon(Icons.assignment_ind_outlined).first,
        warnIfMissed: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bubbleTop = tester.getTopLeft(find.text('Começar')).dy;
      expect(
        bubbleTop,
        greaterThanOrEqualTo(0),
        reason: 'O botão de ação do balão não pode renderizar acima do '
            'topo da tela (dy negativo = fora da viewport, inacessível).',
      );
    },
  );

  testWidgets(
    'balão de um nó com espaço acima continua abrindo por cima',
    (tester) async {
      // Viewport bem alta garante espaço de sobra acima de qualquer nó
      // intermediário — comportamento original preservado quando cabe.
      await pumpTrail(tester, height: 2400);

      final questionnaireIcon = find.byIcon(Icons.assignment_outlined).first;
      await tester.dragUntilVisible(
        questionnaireIcon,
        find.byType(JourneyTrail),
        const Offset(0, -200),
      );
      // Posição do nó capturada antes do toque — depois que o balão abre, o
      // título "Questionários" passa a existir duas vezes na árvore (rótulo
      // do nó + título do balão), o que ambiguaria find.text.
      final nodeTop = tester.getTopLeft(questionnaireIcon).dy;

      await tester.tap(questionnaireIcon, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bubbleBottom = tester.getBottomLeft(find.text('Começar')).dy;
      expect(
        bubbleBottom,
        lessThanOrEqualTo(nodeTop),
        reason: 'Com espaço de sobra acima, o balão deve continuar abrindo '
            'por cima do nó, como sempre foi.',
      );
    },
  );
}
