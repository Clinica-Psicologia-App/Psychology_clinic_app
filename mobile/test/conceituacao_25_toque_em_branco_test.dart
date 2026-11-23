import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/providers/initial_assessment_providers.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_edit_page.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_page.dart';
import 'package:terapia_esquema/features/mental_map/presentation/mental_map_routes.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/mental_map/providers/mental_map_providers.dart';
import 'package:terapia_esquema/features/patient_problems/presentation/patient_problem_routes.dart';
import 'package:terapia_esquema/features/personality_assessment/providers/personality_assessment_providers.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_routes.dart';
import 'package:terapia_esquema/features/therapy_goals/presentation/therapy_goal_routes.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/therapy_demands/presentation/therapy_demands_routes.dart';

// #25 — na síntese, tocar num item em branco leva ao campo dele. Dados fictícios.

const _role = ProfileRole.psychologist;

void main() {
  CaseConceptualization concept({String? comments, CaseOrigins? origins}) {
    final e = CaseConceptualization.empty();
    return CaseConceptualization(
      unmetNeeds: e.unmetNeeds,
      modeSequences: e.modeSequences,
      relationship: e.relationship,
      centralSchemas: e.centralSchemas,
      therapyObjectives: e.therapyObjectives,
      origins: origins ?? const CaseOrigins(),
      additionalComments: comments,
    );
  }

  Future<GoRouter> pump(WidgetTester tester, CaseConceptualization c) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation:
          MentalMapRoutes.staffCaseConceptualization(role: _role, patientId: 'p1'),
      routes: [
        GoRoute(
          path: MentalMapRoutes.staffCaseConceptualization(
              role: _role, patientId: 'p1'),
          builder: (_, __) =>
              const CaseConceptualizationPage(role: _role, patientId: 'p1'),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) => CaseConceptualizationEditPage(
                role: _role,
                patientId: 'p1',
                focus: state.uri.queryParameters['focus'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: TherapyDemandsRoutes.staff(role: _role, patientId: 'p1'),
          builder: (_, __) => const Scaffold(body: Text('TELA-DEMANDAS')),
        ),
        GoRoute(
          path: PatientProblemRoutes.staffList(role: _role, patientId: 'p1'),
          builder: (_, __) => const Scaffold(body: Text('TELA-PROBLEMAS')),
        ),
        GoRoute(
          path: QuestionnaireRoutes.list(role: _role, patientId: 'p1'),
          builder: (_, __) => const Scaffold(body: Text('TELA-QUESTIONARIOS')),
        ),
        GoRoute(
          path: TherapyGoalRoutes.staffList(role: _role, patientId: 'p1'),
          builder: (_, __) => const Scaffold(body: Text('TELA-OBJETIVOS')),
        ),
      ],
    );
    const ctx = StaffMentalMapContext(role: _role, patientId: 'p1');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        staffMentalMapProvider(ctx).overrideWith((ref) async =>
            MentalMapData.empty),
        caseConceptualizationProvider('p1').overrideWith((ref) async => c),
        initialAssessmentProvider(
                const InitialAssessmentContext(role: _role, patientId: 'p1'))
            .overrideWith((ref) async => const InitialAssessment(patientId: 'p1')),
        personalityIntegrationsProvider('p1').overrideWith((ref) async => []),
        personalityAssessmentsProvider('p1').overrideWith((ref) async => []),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tapFill(WidgetTester t, String section) async {
    final f = find.byKey(Key('fill_$section'));
    await t.scrollUntilVisible(f, 300,
        scrollable: find.byType(Scrollable).last);
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  /// O cartão do item aparece no alto da tela do editor.
  void expectEditorAt(WidgetTester t, String titlePrefix) {
    expect(find.text('Editar conceitualização'), findsOneWidget);
    final f = find.textContaining(titlePrefix);
    expect(f, findsOneWidget, reason: titlePrefix);
    final dy = t.getTopLeft(f).dy;
    // No alto da tela; os últimos cartões não passam do fim da rolagem, mas
    // ficam à vista (a tela tem 1400 de altura).
    expect(dy, greaterThan(0), reason: titlePrefix);
    expect(dy, lessThan(1300), reason: '$titlePrefix deveria estar à vista');
    expect(find.textContaining('1 · Identificação'), findsNothing,
        reason: 'o editor deveria ter rolado até o item');
  }

  const editorTargets = {
    '5': '5 · Nível de funcionamento',
    '7.1': '7.1 ·',
    '7.2': '7.2 ·',
    '7.3': '7.3 ·',
    '7.4': '7.4 ·',
    '8.1': '8.1 ·',
    '10': '10 · Sequência de modos',
    '11': '11 · Relação terapêutica',
    '13': '13 · Comentários adicionais',
  };

  for (final e in editorTargets.entries) {
    testWidgets('item ${e.key} em branco abre o editor no cartão dele',
        (tester) async {
      await pump(tester, concept());
      await tapFill(tester, e.key);
      expectEditorAt(tester, e.value);
    });
  }

  for (final s in ['2', '3', '4']) {
    testWidgets('item $s em branco abre Demandas Terapêuticas',
        (tester) async {
      await pump(tester, concept());
      await tapFill(tester, s);
      expect(find.text('TELA-DEMANDAS'), findsOneWidget);
    });
  }

  testWidgets('item preenchido não é tocável e não navega', (tester) async {
    await pump(
        tester,
        concept(
          comments: 'Nota extra da psicóloga.',
          origins: const CaseOrigins(earlyHistory: 'Infância com mudanças.'),
        ));
    expect(find.byKey(const Key('fill_13')), findsNothing);
    expect(find.byKey(const Key('fill_7.1')), findsNothing);
    // 7.2 continua em branco, então segue tocável.
    expect(find.byKey(const Key('fill_7.2')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Nota extra da psicóloga.'), 300,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('Nota extra da psicóloga.'));
    await tester.pumpAndSettle();
    expect(find.text('Editar conceitualização'), findsNothing);
    expect(find.text('TELA-DEMANDAS'), findsNothing);
  });

  const externalTargets = {
    '6': 'TELA-PROBLEMAS',
    '8.2': 'TELA-QUESTIONARIOS',
    '9': 'TELA-QUESTIONARIOS',
    '12': 'TELA-OBJETIVOS',
  };
  for (final e in externalTargets.entries) {
    testWidgets('item ${e.key} em branco abre ${e.value}', (tester) async {
      await pump(tester, concept());
      await tapFill(tester, e.key);
      expect(find.text(e.value), findsOneWidget);
    });
  }

  testWidgets('item 1 (dados básicos) continua sem toque', (tester) async {
    await pump(tester, concept());
    expect(find.byKey(const Key('fill_1')), findsNothing);
    expect(find.text('Dados do paciente ainda não disponíveis.'),
        findsOneWidget);
  });

  testWidgets('voltar do editor mantém a síntese', (tester) async {
    final router = await pump(tester, concept());
    await tapFill(tester, '13');
    router.pop();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fill_13')), findsOneWidget);
  });
}
