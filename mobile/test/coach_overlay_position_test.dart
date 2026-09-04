import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/coach/domain/coach_step.dart';
import 'package:terapia_esquema/features/coach/domain/coach_tour.dart';
import 'package:terapia_esquema/features/coach/presentation/widgets/coach_overlay.dart';

void main() {
  // Alvo bem no rodapé + texto longo (o caso que cortava). O balão deve
  // ficar INTEIRO dentro da área segura da tela (não vazar por baixo).
  testWidgets('balão do coach nunca corta no rodapé', (tester) async {
    // Ignora falhas de decodificação das imagens do mascote no ambiente de
    // teste (não afetam o layout, que tem tamanho fixo).
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.library == 'image resource service') return;
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    const bottomInset = 24.0;
    final targetKey = GlobalKey();
    const longText =
        'Aqui ficam questionários, resultados e recursos terapêuticos para '
        'apoiar suas decisões clínicas ao longo do acompanhamento do paciente.';

    final tour = CoachTour(
      id: 'psychologist-home',
      steps: [
        const CoachStep(id: 's1', text: 'Passo 1', pose: MascotPose.wave),
        const CoachStep(id: 's2', text: 'Passo 2', pose: MascotPose.point),
        CoachStep(
            id: 's3',
            text: longText,
            pose: MascotPose.explain,
            targetKey: targetKey),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(375, 812),
            padding: EdgeInsets.only(bottom: bottomInset),
          ),
          child: Stack(
            textDirection: TextDirection.ltr,
            children: [
              // Alvo colado no rodapé.
              Positioned(
                left: 20,
                bottom: 40,
                child: Container(key: targetKey, width: 220, height: 56),
              ),
              CoachOverlay(
                tour: tour,
                index: 2,
                onNext: () {},
                onSkip: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    // Rect do balão (contém o texto do passo).
    final bubble = find.text(longText);
    expect(bubble, findsOneWidget);
    final panelRect = tester.getRect(
      find.ancestor(of: bubble, matching: find.byType(Material)).first,
    );

    const screenHeight = 812.0;
    final safeBottom = screenHeight - bottomInset;

    // O fundo do balão não pode ultrapassar a área segura (com folga de 1px).
    expect(panelRect.bottom, lessThanOrEqualTo(safeBottom + 1),
        reason:
            'balão vaza o rodapé: bottom=${panelRect.bottom} > $safeBottom');
    // E o topo tem de estar visível (não acima da tela).
    expect(panelRect.top, greaterThanOrEqualTo(-1));
  });
}
