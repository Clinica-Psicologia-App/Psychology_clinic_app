import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_edit_page.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 30000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseConceptualizationProvider('p1')
              .overrideWith((ref) async => CaseConceptualization.empty()),
        ],
        child: const MaterialApp(
          home: CaseConceptualizationEditPage(
            role: ProfileRole.psychologist,
            patientId: 'p1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Editar conceitualização mostra os itens na ordem do documento',
      (tester) async {
    await pump(tester);
    const prefixes = [
      '2, 3 e 4 ·', '5 ·', '6 ·', '7.1 ·', '7.2 ·', '7.3 ·', '7.4 ·',
      '8.1 ·', '8.2 ·', '9.1 ·', '9.2 ·', '9.3 ·', '9.4 ·', '10 ·', '11 ·',
      '12 ·', '13 ·',
    ];
    final ys = <double>[];
    for (final p in prefixes) {
      final f = find.textContaining(p);
      expect(f, findsOneWidget, reason: p);
      ys.add(tester.getTopLeft(f).dy);
    }
    for (var i = 1; i < ys.length; i++) {
      expect(ys[i], greaterThan(ys[i - 1]),
          reason: '${prefixes[i]} deveria vir depois de ${prefixes[i - 1]}');
    }
  });

  testWidgets('7.2 repete a legenda da escala abaixo de cada necessidade',
      (tester) async {
    await pump(tester);
    const legend =
        '0 = quase nada, 1 = muito limitado, 3 = moderado, 5 = grande medida';
    // 1 no subtítulo do cartão (termina com ponto) + 1 por necessidade.
    final perNeed = find.text(legend);
    expect(perNeed, findsWidgets);
    expect(tester.widgetList(perNeed).length, greaterThanOrEqualTo(9));
  });

  testWidgets('cartões 5, 6, 7.3 e 8 abrem as telas do mesmo paciente',
      (tester) async {
    tester.view.physicalSize = const Size(800, 30000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const base = '/psychologist/patients/p1';
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const CaseConceptualizationEditPage(
            role: ProfileRole.psychologist, patientId: 'p1'),
      ),
      for (final r in [
        '$base/initial-assessment/context',
        '$base/problems',
        '$base/personality',
        '$base/questionnaires',
      ])
        GoRoute(path: r, builder: (_, __) => Scaffold(body: Text('DEST $r'))),
    ]);
    addTearDown(router.dispose);
    final container = ProviderContainer(overrides: [
      caseConceptualizationProvider('p1')
          .overrideWith((ref) async => CaseConceptualization.empty()),
    ]);
    addTearDown(container.dispose);

    Future<void> openAndBack(String key, String dest) async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
      expect(find.text('DEST $dest'), findsOneWidget, reason: key);
      router.go('/');
      await tester.pumpAndSettle();
    }

    await openAndBack('edit_open_context', '$base/initial-assessment/context');
    await openAndBack('edit_open_problems', '$base/problems');
    await openAndBack('edit_open_personality', '$base/personality');
    await openAndBack('edit_open_questionnaires_81', '$base/questionnaires');
    await openAndBack('edit_open_questionnaires_82', '$base/questionnaires');
  });
}
