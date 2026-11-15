import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/presentation/initial_assessment_patient_page.dart';
import 'package:terapia_esquema/features/initial_assessment/presentation/initial_assessment_routes.dart';
import 'package:terapia_esquema/features/initial_assessment/providers/initial_assessment_providers.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

class _Gate {
  Completer<void>? gate;
  bool failNext = false;
  int basicsCalls = 0;
}

class _FakeMutation extends InitialAssessmentMutationNotifier {
  _FakeMutation(this.g);
  final _Gate g;

  @override
  Future<void> savePatientBasics({
    String? preferredName,
    DateTime? birthDate,
    String? occupation,
    String? livesWith,
    bool? hasChildren,
    bool? usesMedication,
    String? medicationNotes,
    bool? psychiatricFollowup,
    String? psychiatristNotes,
    String? importantToKnow,
  }) async {
    g.basicsCalls++;
    await g.gate?.future;
    if (g.failNext) throw Exception('falha');
  }

  @override
  Future<void> saveIntake({
    String? reasonForSeeking,
    String? problemDuration,
    String? mainDiscomfort,
    String? expectations,
    String? relatedEvent,
    bool markCompleted = false,
  }) async {}

  @override
  Future<void> saveLifeAreas(List<LifeAreaAssessment> areas) async {}
}

void main() {
  const ctx =
      InitialAssessmentContext(role: ProfileRole.patient, patientId: 'p1');

  Future<GoRouter> pump(WidgetTester tester, _Gate g) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('ListTile background color')) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(routes: [
      GoRoute(
          path: '/', builder: (_, __) => const Scaffold(body: Text('HOME'))),
      GoRoute(
        path: '/assess',
        builder: (_, __) => const InitialAssessmentPatientPage(
            role: ProfileRole.patient, patientId: 'p1'),
      ),
      GoRoute(
        path: InitialAssessmentRoutes.patientHistory,
        builder: (_, __) => const Scaffold(body: Text('HISTORIA')),
      ),
    ], initialLocation: '/');
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        initialAssessmentProvider(ctx).overrideWith(
            (ref) async => const InitialAssessment(patientId: 'p1')),
        patientDetailProvider('p1').overrideWith((ref) async => null),
        initialAssessmentMutationProvider.overrideWith(() => _FakeMutation(g)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/assess');
    await tester.pumpAndSettle();
    return router;
  }

  Finder pageScrollable() => find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;

  Future<void> edit(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'Ana');
    await tester.pump();
  }

  Future<void> tryPop(WidgetTester tester, {bool settle = true}) async {
    Navigator.of(tester.element(find.byType(InitialAssessmentPatientPage)))
        .maybePop();
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> jumpToEnd(WidgetTester tester) async {
    final pos = tester.state<ScrollableState>(pageScrollable()).position;
    for (var i = 0; i < 3; i++) {
      pos.jumpTo(pos.maxScrollExtent);
      await tester.pump();
    }
  }

  Future<void> tapHistory(WidgetTester tester) async {
    final tile = find.text('Minha História');
    await tester.scrollUntilVisible(tile, 300, scrollable: pageScrollable());
    await tester.tap(tile);
    await tester.pump();
  }

  testWidgets('sem alteração sai direto, sem diálogo e sem gravar',
      (tester) async {
    final g = _Gate();
    await pump(tester, g);
    await tryPop(tester);
    expect(find.text('HOME'), findsOneWidget);
    expect(g.basicsCalls, 0);
  });

  testWidgets('sair com alteração mostra o diálogo; continuar editando fica',
      (tester) async {
    final g = _Gate();
    await pump(tester, g);
    await edit(tester);
    await tryPop(tester);
    expect(find.text('Salvar e sair'), findsOneWidget);
    expect(find.text('Sair sem salvar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exit_continue')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsNothing);
    expect(find.byType(InitialAssessmentPatientPage), findsOneWidget);
    expect(g.basicsCalls, 0);
  });

  testWidgets('Sair sem salvar sai sem gravar', (tester) async {
    final g = _Gate();
    await pump(tester, g);
    await edit(tester);
    await tryPop(tester);
    await tester.tap(find.byKey(const Key('exit_discard')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(g.basicsCalls, 0);
  });

  testWidgets('Salvar e sair grava e só então sai', (tester) async {
    final g = _Gate()..gate = Completer<void>();
    await pump(tester, g);
    await edit(tester);
    await tryPop(tester);
    await tester.tap(find.byKey(const Key('exit_save')));
    await tester.pump();
    expect(find.text('HOME'), findsNothing, reason: 'aguarda o save');
    g.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(g.basicsCalls, 1);
  });

  testWidgets('Salvar e sair com erro fica na tela e continua pendente',
      (tester) async {
    final g = _Gate()..failNext = true;
    await pump(tester, g);
    await edit(tester);
    await tryPop(tester);
    await tester.tap(find.byKey(const Key('exit_save')));
    await tester.pumpAndSettle();
    expect(find.byType(InitialAssessmentPatientPage), findsOneWidget);
    expect(find.textContaining('continua nesta tela'), findsOneWidget);
    // Continua pendente: sair de novo pergunta outra vez.
    await tryPop(tester);
    expect(find.text('Salvar e sair'), findsOneWidget);
    // Depois de corrigir, tentar de novo funciona.
    g.failNext = false;
    await tester.tap(find.byKey(const Key('exit_save')));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(g.basicsCalls, 2);
  });

  Future<void> startSave(WidgetTester tester) async {
    await tester.tap(find.text('Salvar informações'));
    await tester.pump();
  }

  testWidgets('durante o save a tela fica travada (campos, botões, indicador)',
      (tester) async {
    final g = _Gate()..gate = Completer<void>();
    await pump(tester, g);
    await edit(tester);
    await startSave(tester);
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
    expect(find.text('Salvando...'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    // Campo não recebe toque nem foco.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.byType(TextField).at(1), warnIfMissed: false);
    await tester.pump();
    expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>(),
        isNull);
    // Minha História não navega.
    await jumpToEnd(tester);
    await tester.tap(find.text('Minha História', skipOffstage: false),
        warnIfMissed: false);
    await tester.pump();
    expect(find.text('HISTORIA'), findsNothing);
    expect(g.basicsCalls, 1);
    g.gate!.complete();
    await tester.pumpAndSettle();
    expect(g.basicsCalls, 1);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('sair durante o save não sai nem abre diálogo', (tester) async {
    final g = _Gate()..gate = Completer<void>();
    await pump(tester, g);
    await edit(tester);
    await startSave(tester);
    await tryPop(tester, settle: false);
    expect(find.text('Aguarde, salvando…'), findsOneWidget);
    expect(find.text('Sair sem salvar'), findsNothing);
    expect(find.text('HOME'), findsNothing);
    expect(find.byType(InitialAssessmentPatientPage), findsOneWidget);
    g.gate!.complete();
    await tester.pumpAndSettle();
    // Gravou: nada pendente, sai direto.
    await tryPop(tester);
    expect(find.text('HOME'), findsOneWidget);
    expect(g.basicsCalls, 1);
  });

  testWidgets('após erro os campos voltam a ser editáveis e segue pendente',
      (tester) async {
    final g = _Gate()
      ..gate = Completer<void>()
      ..failNext = true;
    await pump(tester, g);
    await edit(tester);
    await startSave(tester);
    g.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    final ignoring = tester
        .widgetList<IgnorePointer>(find.ancestor(
            of: find.byType(ListView), matching: find.byType(IgnorePointer)))
        .any((w) => w.ignoring);
    expect(ignoring, isFalse);
    await tester.tap(find.byType(TextField).at(1));
    await tester.pump();
    expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<EditableText>(),
        isNotNull);
    await tryPop(tester);
    expect(find.text('Salvar e sair'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exit_continue')));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
  });

  testWidgets('abrir Minha História com alteração aguarda o save',
      (tester) async {
    final g = _Gate()..gate = Completer<void>();
    await pump(tester, g);
    await edit(tester);
    await tapHistory(tester);
    expect(find.text('HISTORIA'), findsNothing, reason: 'aguarda o save');
    g.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('HISTORIA'), findsOneWidget);
    expect(g.basicsCalls, 1);
  });

  testWidgets('falha ao gravar não navega e mantém pendente', (tester) async {
    final g = _Gate()..failNext = true;
    await pump(tester, g);
    await edit(tester);
    await tapHistory(tester);
    await tester.pumpAndSettle();
    expect(find.text('HISTORIA'), findsNothing);
    expect(find.textContaining('Não foi possível salvar'), findsOneWidget);
    await tryPop(tester);
    expect(find.text('Salvar e sair'), findsOneWidget,
        reason: 'segue pendente');
  });

  testWidgets('indicador de etapas destaca a etapa conforme a rolagem',
      (tester) async {
    await pump(tester, _Gate());
    Color bar(int i) => (tester
            .widget<AnimatedContainer>(find.byKey(Key('step_bar_$i')))
            .decoration as BoxDecoration)
        .color!;
    expect(tester.getSize(find.byKey(const Key('step_bar_0'))).height, 6,
        reason: 'etapa 1 atual no topo');
    await tester.drag(pageScrollable(), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('step_bar_2'))).height, 6);
    expect(tester.getSize(find.byKey(const Key('step_bar_0'))).height, 4);
    expect(bar(0).a, lessThan(bar(2).a), reason: 'concluída mais suave');
  });
}
