import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/mental_map/data/case_conceptualization_repository.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/demands_text_history.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem_status.dart';
import 'package:terapia_esquema/features/patient_problems/providers/patient_problems_providers.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/therapy_demands/presentation/therapy_demands_page.dart';

class _FakeRepo implements CaseConceptualizationRepository {
  _FakeRepo(this.doc);

  CaseConceptualization doc;
  final List<String> calls = [];
  Map<String, Object?> reasons = {};
  GeneralImpressions? impressions;
  Diagnosis? diagnosis;
  Diagnosis? diagnosisPrevious;
  String? author;

  @override
  Future<CaseConceptualization> load(String patientId) async => doc;

  @override
  Future<DemandsTextHistory> loadDemandsHistory(String patientId) async =>
      DemandsTextHistory.empty;

  @override
  Future<void> save(String patientId, CaseConceptualization data) async {
    calls.add('synthesis');
  }

  @override
  Future<void> saveReasons(
    String patientId, {
    required String? initial,
    required String? current,
    String? previousInitial,
    String? previousCurrent,
    String? authorName,
  }) async {
    calls.add('reasons');
    author = authorName;
    reasons = {
      'initial': initial,
      'current': current,
      'previousInitial': previousInitial,
      'previousCurrent': previousCurrent,
    };
  }

  @override
  Future<void> saveImpressions(
    String patientId,
    GeneralImpressions value, {
    GeneralImpressions previous = const GeneralImpressions(),
    String? authorName,
  }) async {
    calls.add('impressions');
    impressions = value;
  }

  @override
  Future<Diagnosis> saveDiagnosis(
    String patientId,
    Diagnosis next, {
    required Diagnosis previous,
    String? authorName,
    DateTime? now,
  }) async {
    calls.add('diagnosis');
    diagnosis = next;
    diagnosisPrevious = previous;
    return next.withRevisions(
        previous: previous, now: DateTime.utc(2026, 10, 22), authorName: authorName);
  }
}

CaseConceptualization _doc() => CaseConceptualization(
      unmetNeeds: const [],
      modeSequences: const [],
      relationship: const TherapeuticRelationship(),
      motivoInitial: 'motivo inicial salvo',
      motivoCurrent: 'motivo atual salvo',
      generalImpressions: const GeneralImpressions(
          initial: 'impressão inicial salva', current: 'impressão atual salva'),
      updatedAt: DateTime(2026, 10, 22, 10, 30),
    );

PatientProblem _problem() => PatientProblem(
      id: 'pr1',
      clinicId: 'c1',
      patientId: 'p1',
      title: 'Insônia',
      description: 'acorda de madrugada',
      status: PatientProblemStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Future<GoRouter> _pump(
  WidgetTester tester,
  _FakeRepo repo, {
  List<PatientProblem> problems = const [],
  Size size = const Size(900, 2000),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const Scaffold(body: Text('HOME'))),
    GoRoute(
      path: '/d',
      builder: (_, __) => const TherapyDemandsPage(
          role: ProfileRole.psychologist, patientId: 'p1'),
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      caseConceptualizationRepositoryProvider.overrideWithValue(repo),
      patientDetailProvider.overrideWith((ref, id) async => null),
      staffPatientProblemsProvider.overrideWith((ref, ctx) async => problems),
      therapyDemandsAuthorNameProvider.overrideWithValue('Dra. Teste'),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  router.push('/d');
  await tester.pumpAndSettle();
  return router;
}

Finder _tab(String label) => find.descendant(
    of: find.byType(TabBar), matching: find.text(label));

TextEditingController _ctrl(WidgetTester tester, Key key) =>
    tester.widget<TextField>(find.byKey(key)).controller!;

void main() {
  testWidgets('abre em Motivos da terapia, com 3 abas e dados salvos',
      (tester) async {
    await _pump(tester, _FakeRepo(_doc()));

    expect(_tab('Motivos da terapia'), findsOneWidget);
    expect(_tab('Impressões clínicas'), findsOneWidget);
    expect(_tab('Perspectiva diagnóstica'), findsOneWidget);
    expect(_ctrl(tester, const Key('demands_reasons_initial')).text,
        'motivo inicial salvo');
    expect(_ctrl(tester, const Key('demands_reasons_current')).text,
        'motivo atual salvo');
    expect(find.text('Última atualização: 22/10/2026 10:30'), findsOneWidget);
    // Nada de objetivos/intervenções/evolução nesta tela.
    expect(find.textContaining('Objetivo'), findsNothing);
  });

  testWidgets('salvar motivos grava só os motivos, com autoria e base anterior',
      (tester) async {
    final repo = _FakeRepo(_doc());
    await _pump(tester, repo);

    await tester.enterText(
        find.byKey(const Key('demands_reasons_initial')), 'motivo corrigido');
    await tester.pump();
    await tester.tap(find.byKey(const Key('demands_save_reasons')));
    await tester.pumpAndSettle();

    expect(repo.calls, ['reasons']);
    expect(repo.reasons['initial'], 'motivo corrigido');
    expect(repo.reasons['current'], 'motivo atual salvo');
    expect(repo.reasons['previousInitial'], 'motivo inicial salvo');
    expect(repo.author, 'Dra. Teste');
    expect(find.text('Motivos da terapia salvos.'), findsOneWidget);
    // Depois de salvar não há mais alteração pendente.
    expect(find.text('Sem alterações para salvar'), findsOneWidget);
  });

  testWidgets('cada aba salva sozinha: impressões não mexem nos motivos',
      (tester) async {
    final repo = _FakeRepo(_doc());
    await _pump(tester, repo);

    await tester.tap(_tab('Impressões clínicas'));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('demands_impressions_current')), 'mais aberta');
    await tester.pump();
    await tester.tap(find.byKey(const Key('demands_save_impressions')));
    await tester.pumpAndSettle();

    expect(repo.calls, ['impressions']);
    expect(repo.impressions!.initial, 'impressão inicial salva');
    expect(repo.impressions!.current, 'mais aberta');
  });

  testWidgets('perspectiva diagnóstica valida sistema e situação antes de salvar',
      (tester) async {
    final repo = _FakeRepo(_doc());
    await _pump(tester, repo);

    await tester.tap(_tab('Perspectiva diagnóstica'));
    await tester.pumpAndSettle();
    expect(find.text('Aba ainda não avaliada.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('demands_add_dx')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('demands_dx_name_0')), 'Hipótese de TAG');
    await tester.pump();
    await tester.tap(find.byKey(const Key('demands_save_dx')));
    await tester.pumpAndSettle();

    expect(repo.calls, isEmpty);
    expect(find.byKey(const Key('demands_dx_error')), findsOneWidget);
    expect(find.textContaining('Selecione o sistema'), findsWidgets);

    await tester.tap(find.widgetWithText(ChoiceChip, 'CID-11'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Em investigação'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('demands_save_dx')));
    await tester.pumpAndSettle();

    expect(repo.calls, ['diagnosis']);
    final item = repo.diagnosis!.items.single;
    expect(item.name, 'Hipótese de TAG');
    expect(item.system, 'CID-11');
    expect(item.status, DiagnosisStatus.investigating);
    expect(item.reviewedOn, isNotNull);
  });

  testWidgets('"sem diagnóstico" não convive com diagnóstico estabelecido',
      (tester) async {
    final repo = _FakeRepo(_doc());
    await _pump(tester, repo);

    await tester.tap(_tab('Perspectiva diagnóstica'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demands_no_dx')));
    await tester.pump();
    expect(find.text('Marcado: sem diagnóstico estabelecido no momento.'),
        findsOneWidget);

    await tester.tap(find.byKey(const Key('demands_add_dx')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('demands_dx_name_0')), 'TAG');
    await tester.tap(find.widgetWithText(ChoiceChip, 'CID-11'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Diagnóstico estabelecido'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('demands_save_dx')));
    await tester.pumpAndSettle();

    expect(repo.calls, isEmpty);
    expect(find.textContaining('Remova a marcação'), findsWidgets);
  });

  testWidgets('sair com alterações pede confirmação e preserva o texto',
      (tester) async {
    final repo = _FakeRepo(_doc());
    await _pump(tester, repo);

    await tester.enterText(
        find.byKey(const Key('demands_reasons_initial')), 'texto novo');
    await tester.pump();
    // A aba com alterações é sinalizada.
    expect(find.byIcon(Icons.circle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Sair sem salvar?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('demands_keep_editing')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsNothing);
    expect(_ctrl(tester, const Key('demands_reasons_initial')).text,
        'texto novo');

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('demands_discard')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(repo.calls, isEmpty);
  });

  testWidgets('sem alterações volta direto, sem diálogo', (tester) async {
    await _pump(tester, _FakeRepo(_doc()));
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Sair sem salvar?'), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('registros anteriores: recolhidos, consultáveis e sem cópia automática',
      (tester) async {
    final repo = _FakeRepo(_doc());
    await _pump(tester, repo, problems: [_problem()]);

    expect(find.text('Registros anteriores'), findsOneWidget);
    expect(find.text('Insônia'), findsNothing); // recolhido

    await tester.ensureVisible(find.byKey(const Key('demands_legacy_section')));
    await tester.tap(find.text('Registros anteriores'));
    await tester.pumpAndSettle();
    expect(find.text('Insônia'), findsOneWidget);
    // Nada foi copiado sozinho para os campos.
    expect(_ctrl(tester, const Key('demands_reasons_initial')).text,
        'motivo inicial salvo');

    await tester.tap(find.text('Usar no registro inicial'));
    await tester.pump();
    expect(_ctrl(tester, const Key('demands_reasons_initial')).text,
        'motivo inicial salvo\nInsônia: acorda de madrugada');
    expect(_ctrl(tester, const Key('demands_reasons_current')).text,
        'motivo atual salvo');
  });

  testWidgets('trocar de aba não perde o que foi digitado', (tester) async {
    await _pump(tester, _FakeRepo(_doc()));

    await tester.enterText(
        find.byKey(const Key('demands_reasons_current')), 'rascunho');
    await tester.pump();
    await tester.tap(_tab('Impressões clínicas'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Motivos da terapia'));
    await tester.pumpAndSettle();

    expect(_ctrl(tester, const Key('demands_reasons_current')).text, 'rascunho');
    expect(find.byIcon(Icons.circle), findsOneWidget);
  });

  testWidgets('cabe em celular pequeno (360x640) sem estourar', (tester) async {
    await _pump(tester, _FakeRepo(_doc()), size: const Size(360, 640));
    expect(tester.takeException(), isNull);

    // Abas roláveis: a terceira entra na tela por rolagem, com o rótulo inteiro.
    await tester.ensureVisible(_tab('Perspectiva diagnóstica'));
    await tester.pumpAndSettle();
    await tester.tap(_tab('Perspectiva diagnóstica'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // O salvar fica sempre visível; o conteúdo rola.
    expect(find.byKey(const Key('demands_save_dx')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('demands_add_dx')),
      200,
      scrollable: find
          .descendant(
            of: find.byType(TabBarView),
            matching: find.byWidgetPredicate((w) =>
                w is Scrollable && w.axisDirection == AxisDirection.down),
          )
          .last,
    );
    expect(find.byKey(const Key('demands_add_dx')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
