import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/consolidated_schema_row.dart';
import 'package:terapia_esquema/features/clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';

ClinicalDashboardData _dataWith(List<ConsolidatedSchemaRow> schemas) {
  return ClinicalDashboardData(
    patientName: 'Roberto',
    caseSummary: ClinicalCaseSummary.empty,
    callouts: const [],
    history: const [],
    consolidatedSchemas: schemas,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required ClinicalDashboardData data,
  required bool isStaff,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: ConsolidatedSchemaProfileCard(
                data: data,
                isStaff: isStaff,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const activatedAuto = ConsolidatedSchemaRow(
    name: 'Desconfiança/Abuso',
    code: 'DESCONFIANCA',
    score: 5.0,
    responseId: 'resp-ysq',
    isAutoActivated: true,
    instrumentName: 'YSQ',
    instrumentCode: 'YSQ_FOUNDATION_V1',
    scaleMax: 6,
  );

  const activatedPsi = ConsolidatedSchemaRow(
    name: 'Subjugação',
    code: 'SUBJUGACAO',
    score: 2.5,
    responseId: 'resp-ysq',
    isAutoActivated: false,
    isPsiActivated: true,
    psiObservation: 'Relevante apesar da média baixa.',
    instrumentName: 'YSQ',
    instrumentCode: 'YSQ_FOUNDATION_V1',
    scaleMax: 6,
  );

  const nonActivated = ConsolidatedSchemaRow(
    name: 'Autossacrifício',
    code: 'AUTOSSACRIFICIO',
    score: 2.0,
    responseId: 'resp-ysq',
    isAutoActivated: false,
    instrumentName: 'YSQ',
    instrumentCode: 'YSQ_FOUNDATION_V1',
    scaleMax: 6,
  );

  testWidgets('separa esquemas ativados e não ativados nas duas colunas',
      (tester) async {
    await _pump(
      tester,
      data: _dataWith(const [activatedAuto, activatedPsi, nonActivated]),
      isStaff: true,
    );

    // Cabeçalho e títulos das colunas.
    expect(find.text('Perfil Esquemático Consolidado'), findsOneWidget);
    expect(find.text('Ativados'), findsOneWidget);
    expect(find.text('Não ativados'), findsOneWidget);

    // Esquemas em suas respectivas colunas.
    expect(find.text('Desconfiança/Abuso'), findsOneWidget);
    expect(find.text('Subjugação'), findsOneWidget);
    expect(find.text('Autossacrifício'), findsOneWidget);

    // Contadores: 2 ativos, 1 não ativado.
    expect(find.text('2 ativos'), findsOneWidget);
    expect(find.text('1 n/a'), findsOneWidget);
  });

  testWidgets('mostra legenda de símbolos apenas para o paciente',
      (tester) async {
    await _pump(
      tester,
      data: _dataWith(const [activatedAuto, nonActivated]),
      isStaff: false,
    );

    expect(find.text('Ativado pelo sistema'), findsOneWidget);
    expect(find.text('Ativado pelo profissional'), findsOneWidget);
  });

  testWidgets('não renderiza nada sem esquemas consolidados', (tester) async {
    await _pump(tester, data: _dataWith(const []), isStaff: true);

    expect(find.text('Perfil Esquemático Consolidado'), findsNothing);
    expect(find.byType(ConsolidatedSchemaProfileCard), findsOneWidget);
  });

  testWidgets('mostra "Nenhum" quando uma das colunas está vazia',
      (tester) async {
    // Só ativados → coluna "Não ativados" mostra "Nenhum".
    await _pump(
      tester,
      data: _dataWith(const [activatedAuto]),
      isStaff: true,
    );

    expect(find.text('Nenhum'), findsOneWidget);
    expect(find.text('1 ativos'), findsOneWidget);
    expect(find.text('0 n/a'), findsOneWidget);
  });
}
