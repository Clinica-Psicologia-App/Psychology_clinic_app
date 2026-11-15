import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/patient_basics.dart';
import 'package:terapia_esquema/features/initial_assessment/presentation/initial_assessment_patient_page.dart';
import 'package:terapia_esquema/features/initial_assessment/providers/initial_assessment_providers.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

class _Saved {
  int calls = 0;
  bool? hasChildren;
  String? childrenNotes;
}

class _FakeMutation extends InitialAssessmentMutationNotifier {
  _FakeMutation(this.s);
  final _Saved s;

  @override
  Future<void> savePatientBasics({
    String? preferredName,
    DateTime? birthDate,
    String? occupation,
    String? livesWith,
    bool? hasChildren,
    String? childrenNotes,
    bool? usesMedication,
    String? medicationNotes,
    bool? psychiatricFollowup,
    String? psychiatristNotes,
    String? importantToKnow,
  }) async {
    s.calls++;
    s.hasChildren = hasChildren;
    s.childrenNotes = childrenNotes;
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
  const notesKey = Key('children_notes_field');

  test('PatientBasics.fromJson lê children_notes', () {
    final b = PatientBasics.fromJson({
      'has_children': true,
      'children_notes': 'Ana, 7 anos',
    });
    expect(b.childrenNotes, 'Ana, 7 anos');
    expect(PatientBasics.fromJson({}).childrenNotes, isNull);
    expect(
        PatientBasics.fromJson({'has_children': false, 'children_notes': null})
            .childrenNotes,
        isNull);
  });

  Future<void> pump(WidgetTester tester, _Saved s,
      {PatientBasics? basics}) async {
    final original = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('ListTile background color')) return;
      original?.call(d);
    };
    addTearDown(() => FlutterError.onError = original);
    tester.view.physicalSize = const Size(400, 1400);
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
    ], initialLocation: '/');
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        initialAssessmentProvider(ctx).overrideWith((ref) async =>
            InitialAssessment(patientId: 'p1', basics: basics)),
        patientDetailProvider('p1').overrideWith((ref) async => null),
        initialAssessmentMutationProvider.overrideWith(() => _FakeMutation(s)),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    router.push('/assess');
    await tester.pumpAndSettle();
  }

  Finder childrenSwitch() => find.widgetWithText(SwitchListTile, 'Tem filhos?');

  testWidgets('campo aparece ao marcar e some ao desmarcar, limpando o texto',
      (tester) async {
    await pump(tester, _Saved());
    expect(find.byKey(notesKey), findsNothing);
    await tester.tap(childrenSwitch());
    await tester.pumpAndSettle();
    expect(find.byKey(notesKey), findsOneWidget);
    expect(find.text('Conte sobre seus filhos (nomes e idades)'),
        findsOneWidget);
    await tester.enterText(find.byKey(notesKey), 'Ana, 7 anos');
    await tester.pump();
    await tester.tap(childrenSwitch());
    await tester.pumpAndSettle();
    expect(find.byKey(notesKey), findsNothing);
    await tester.tap(childrenSwitch());
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(notesKey)).controller!.text,
        isEmpty);
  });

  testWidgets('limite de 1000 caracteres com contador visível',
      (tester) async {
    await pump(tester, _Saved());
    await tester.tap(childrenSwitch());
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(notesKey)).maxLength, 1000);
    await tester.enterText(find.byKey(notesKey), 'a' * 1200);
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(notesKey)).controller!.text,
        hasLength(1000));
    expect(find.text('1000/1000'), findsOneWidget);
  });

  testWidgets('valor salvo aparece e o snapshot considera o campo',
      (tester) async {
    final s = _Saved();
    await pump(tester, s,
        basics: const PatientBasics(
            hasChildren: true, childrenNotes: 'Ana, 7 anos'));
    expect(tester.widget<TextField>(find.byKey(notesKey)).controller!.text,
        'Ana, 7 anos');
    // Sem alteração: sair não pergunta.
    Navigator.of(tester.element(find.byType(InitialAssessmentPatientPage)))
        .maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Salvar e sair'), findsNothing);
  });

  testWidgets('editar só o campo de filhos marca pendência e grava o texto',
      (tester) async {
    final s = _Saved();
    await pump(tester, s,
        basics: const PatientBasics(hasChildren: true, childrenNotes: 'Ana'));
    await tester.enterText(find.byKey(notesKey), 'Ana, 7 anos');
    await tester.pump();
    Navigator.of(tester.element(find.byType(InitialAssessmentPatientPage)))
        .maybePop();
    await tester.pumpAndSettle();
    expect(find.text('Salvar e sair'), findsOneWidget);
    await tester.tap(find.byKey(const Key('exit_save')));
    await tester.pumpAndSettle();
    expect(s.calls, 1);
    expect(s.hasChildren, true);
    expect(s.childrenNotes, 'Ana, 7 anos');
  });

  testWidgets('desmarcar envia has_children false e children_notes nulo',
      (tester) async {
    final s = _Saved();
    await pump(tester, s,
        basics: const PatientBasics(hasChildren: true, childrenNotes: 'Ana'));
    await tester.tap(childrenSwitch());
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(InitialAssessmentPatientPage)))
        .maybePop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exit_save')));
    await tester.pumpAndSettle();
    expect(s.hasChildren, false);
    expect(s.childrenNotes, isNull);
  });
}
