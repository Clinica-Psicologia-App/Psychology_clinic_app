import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_bootstrap.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';
import 'package:terapia_esquema/features/genogram/presentation/genogram_bootstrap_page.dart';
import 'package:terapia_esquema/features/genogram/providers/genogram_providers.dart';

void main() {
  testWidgets('lista as propostas e o botão confirma o total', (tester) async {
    const data = GBootstrapData(
      [
        GEdgeProposal(
            GEdge('Fa', 'Mo', GEdgeType.spouse), 'João e Carla — casal'),
        GEdgeProposal(
            GEdge('Fa', 'P', GEdgeType.parentChild), 'Bruno é filho de João'),
      ],
      'clinic',
      'pat',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          genogramBootstrapProvider('pat').overrideWith((ref) async => data),
        ],
        child: const MaterialApp(
          home: GenogramBootstrapPage(patientId: 'pat'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('João e Carla — casal'), findsOneWidget);
    expect(find.text('Bruno é filho de João'), findsOneWidget);
    // Ambas marcadas por padrão → total 2
    expect(find.text('Confirmar (2)'), findsOneWidget);

    // Desmarcar uma reduz o total
    await tester.tap(find.text('João e Carla — casal'));
    await tester.pump();
    expect(find.text('Confirmar (1)'), findsOneWidget);
  });

  testWidgets('estado vazio quando não há propostas', (tester) async {
    const data = GBootstrapData([], 'clinic', 'pat');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          genogramBootstrapProvider('pat').overrideWith((ref) async => data),
        ],
        child: const MaterialApp(
          home: GenogramBootstrapPage(patientId: 'pat'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Nada a sugerir'), findsOneWidget);
  });
}
