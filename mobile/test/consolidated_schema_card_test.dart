import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/consolidated_schema_row.dart';
import 'package:terapia_esquema/features/clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';
import 'package:terapia_esquema/features/results/domain/ysq_taxonomy.dart';

/// Monta a linha já resolvida pela taxonomia, como faz o builder.
ConsolidatedSchemaRow _schema(
  String code,
  double score, {
  bool psiActivated = false,
}) {
  final t = ysqSchemaByCode(code)!;
  final d = ysqDomainByCode(t.domainCode)!;
  return ConsolidatedSchemaRow(
    name: t.name,
    code: code,
    score: score,
    responseId: 'resp-ysq',
    isAutoActivated: score >= 4.0,
    isPsiActivated: psiActivated && score < 4.0,
    instrumentName: 'YSQ',
    instrumentCode: 'YSQ_FOUNDATION_V1',
    scaleMax: 6,
    domainCode: t.domainCode,
    domainOrder: d.order,
    schemaOrder: t.order,
    unmetNeed: t.unmetNeed,
  );
}

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
  final mistrust = _schema('YSQ_SCHEMA_MISTRUST_ABUSE', 5.0);
  final subjugation =
      _schema('YSQ_SCHEMA_SUBJUGATION', 2.5, psiActivated: true);
  final selfSacrifice = _schema('YSQ_SCHEMA_SELF_SACRIFICE', 2.0);

  testWidgets('agrupa os esquemas por domínio, com a necessidade central',
      (tester) async {
    await _pump(
      tester,
      data: _dataWith([mistrust, subjugation, selfSacrifice]),
      isStaff: true,
    );

    expect(find.text('Perfil Esquemático Consolidado'), findsOneWidget);

    // Cabeçalhos de domínio, com numeral e necessidade central.
    expect(find.text('I · Desconexão e rejeição'), findsOneWidget);
    expect(find.text('Vínculos seguros'), findsOneWidget);

    expect(find.text('IV · Orientação para o outro'), findsOneWidget);
    expect(find.text('Liberdade de expressão'), findsOneWidget);

    // Domínios sem esquema no snapshot não aparecem.
    expect(find.text('Limites prejudicados'), findsNothing);

    // Todos os esquemas aparecem — ativados e não ativados juntos, dentro
    // do seu domínio. Não há mais separação em colunas.
    expect(find.text('Desconfiança/Abuso'), findsOneWidget);
    expect(find.text('Subjugação'), findsOneWidget);
    expect(find.text('Autossacrifício'), findsOneWidget);
  });

  testWidgets('conta ativados sobre o total de cada domínio', (tester) async {
    await _pump(
      tester,
      data: _dataWith([mistrust, subjugation, selfSacrifice]),
      isStaff: true,
    );

    // Domínio I: só Desconfiança, ativada.
    expect(find.text('1 de 1 ativados'), findsOneWidget);
    // Domínio IV: Subjugação (psi) ativada, Autossacrifício não.
    expect(find.text('1 de 2 ativados'), findsOneWidget);
    // Badge global no cabeçalho.
    expect(find.text('2 ativos'), findsOneWidget);
  });

  testWidgets('mantém a ordem canônica dentro do domínio, não a de score',
      (tester) async {
    // Isolamento (ordem 4) tem score maior que Abandono (ordem 0).
    await _pump(
      tester,
      data: _dataWith([
        _schema('YSQ_SCHEMA_SOCIAL_ISOLATION', 5.0),
        _schema('YSQ_SCHEMA_ABANDONMENT_INSTABILITY', 4.2),
      ]),
      isStaff: true,
    );

    final abandono =
        tester.getTopLeft(find.text('Abandono/Instabilidade')).dy;
    final isolamento =
        tester.getTopLeft(find.text('Isolamento social/Alienação')).dy;
    expect(abandono, lessThan(isolamento));
  });

  testWidgets('mostra legenda de símbolos apenas para o paciente',
      (tester) async {
    await _pump(
      tester,
      data: _dataWith([mistrust, selfSacrifice]),
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

  testWidgets('modos do YAMI ficam num bloco fora dos domínios',
      (tester) async {
    const mode = ConsolidatedSchemaRow(
      name: 'Protetor Desligado',
      code: 'YAMI_MODE_DETACHED_PROTECTOR',
      score: 4.9,
      responseId: 'resp-yami',
      isAutoActivated: true,
      instrumentName: 'YAMI',
      instrumentCode: 'YAMI_FOUNDATION_V1',
      scaleMax: 6,
    );

    await _pump(
      tester,
      data: _dataWith([mistrust, mode]),
      isStaff: true,
    );

    expect(find.text('Modos esquemáticos'), findsOneWidget);
    expect(find.text('Protetor Desligado'), findsOneWidget);
    expect(find.text('1 de 1 ativados'), findsWidgets);
  });
}
