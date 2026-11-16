import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/consolidated_schema_row.dart';
import 'package:terapia_esquema/features/clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';
import 'package:terapia_esquema/features/results/data/results_repository.dart';
import 'package:terapia_esquema/features/results/providers/results_providers.dart';

class _FakeRepo implements ResultsRepository {
  final deleted = <String>[];
  bool fail = false;

  @override
  Future<void> deleteSchemaActivation({
    required String responseId,
    required String schemaCode,
  }) async {
    if (fail) throw Exception('falha simulada');
    deleted.add('$responseId/$schemaCode');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ConsolidatedSchemaRow _row({required double score, required bool psi}) =>
    ConsolidatedSchemaRow(
      name: 'Esquema Teste',
      code: 'SCH_TEST',
      score: score,
      responseId: 'resp-1',
      isAutoActivated: score >= 4.0,
      isPsiActivated: psi && score < 4.0,
    );

Future<_FakeRepo> _pump(WidgetTester tester, ConsolidatedSchemaRow row,
    {VoidCallback? onChanged, bool fail = false}) async {
  final repo = _FakeRepo()..fail = fail;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [resultsRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConsolidatedActivationSheet(
                schema: row, onChanged: onChanged),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('ativação manual (◎): remove após confirmar', (tester) async {
    var changed = 0;
    final repo = await _pump(tester, _row(score: 2.5, psi: true),
        onChanged: () => changed++);
    expect(find.text('Remover ativação'), findsOneWidget);

    await tester.tap(find.text('Remover ativação'));
    await tester.pumpAndSettle();
    expect(
      find.text('Remover a ativação manual deste esquema? '
          'As respostas dos questionários não são apagadas.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(repo.deleted, ['resp-1/SCH_TEST']);
    expect(changed, 1);
  });

  testWidgets('cancelar na confirmação não remove', (tester) async {
    final repo = await _pump(tester, _row(score: 2.5, psi: true));
    await tester.tap(find.text('Remover ativação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(repo.deleted, isEmpty);
  });

  testWidgets('esquema ● (pontuação) e não ativado não têm remover',
      (tester) async {
    await _pump(tester, _row(score: 5.0, psi: false));
    expect(find.text('Remover ativação'), findsNothing);
    await _pump(tester, _row(score: 2.0, psi: false));
    expect(find.text('Remover ativação'), findsNothing);
  });

  testWidgets('erro ao remover: mostra mensagem no sheet e não fecha',
      (tester) async {
    var changed = 0;
    final repo = await _pump(tester, _row(score: 2.5, psi: true),
        onChanged: () => changed++, fail: true);
    await tester.tap(find.text('Remover ativação'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remover'));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível remover a ativação. Tente novamente.'),
        findsOneWidget);
    expect(find.text('Remover ativação'), findsOneWidget);
    expect(repo.deleted, isEmpty);
    expect(changed, 0);
  });
}
