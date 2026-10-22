import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_clinical_core.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_score_highlight.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_formulation_widgets.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/psychoeducation_module.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/psychoeducation_providers.dart';

void main() {
  const core = MentalMapClinicalCore(topSchemas: [],
    topModes: [MentalMapScoreHighlight(name: 'Modo sintético', code: 'test', kind: 'category', score: 2)],
    topProblemsByIntensity: [], attachmentStyles: [], copingStyles: []);
  for (final role in [ProfileRole.psychologist, ProfileRole.patient]) {
    testWidgets('Modos link uses published module 9; role=${role.name}', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => Scaffold(body: SingleChildScrollView(
          child: MentalMapClinicalCoreSection(core: core, role: role, patientId: 'test')))),
        GoRoute(path: '/psychologist/psychoeducation/:moduleId',
          builder: (_, state) => Text('Destino ${state.pathParameters['moduleId']}')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        psychoeducationJourneyProvider.overrideWith((ref) async => [
          const PsychoeducationModule(id: 'wrong-module', number: 8, stage: 'Transformar', title: 'Outro'),
          const PsychoeducationModule(id: 'correct-module', number: 9, stage: 'Transformar', title: 'Biblioteca 9'),
        ]),
      ], child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      final link = find.text('Ver Biblioteca Transformar');
      if (role == ProfileRole.patient) {
        expect(link, findsNothing);
      } else {
        expect(link, findsOneWidget);
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(find.text('Destino correct-module'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('unpublished/missing module 9 does not create broken link', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      psychoeducationJourneyProvider.overrideWith((ref) async => []),
    ], child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: MentalMapClinicalCoreSection(core: core, role: ProfileRole.psychologist, patientId: 'test'))))));
    await tester.pumpAndSettle();
    expect(find.text('Ver Biblioteca Transformar'), findsNothing);
  });

  for (final role in [ProfileRole.psychologist, ProfileRole.patient]) {
    testWidgets('Esquemas link uses published module 8; role=${role.name}', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => Scaffold(body: SingleChildScrollView(
          child: MentalMapClinicalCoreSection(core: core, role: role, patientId: 'test')))),
        GoRoute(path: '/psychologist/psychoeducation/:moduleId',
          builder: (_, state) => Text('Destino ${state.pathParameters['moduleId']}')),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        psychoeducationJourneyProvider.overrideWith((ref) async => [
          const PsychoeducationModule(id: 'compreender-module', number: 8, stage: 'Compreender', title: 'Biblioteca 8'),
          const PsychoeducationModule(id: 'transformar-module', number: 9, stage: 'Transformar', title: 'Biblioteca 9'),
        ]),
      ], child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      final link = find.text('Ver Biblioteca Compreender');
      if (role == ProfileRole.patient) {
        expect(link, findsNothing);
      } else {
        expect(link, findsOneWidget);
        await tester.tap(link);
        await tester.pumpAndSettle();
        expect(find.text('Destino compreender-module'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('unpublished module 8 does not create broken Esquemas link', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      psychoeducationJourneyProvider.overrideWith((ref) async => [
        const PsychoeducationModule(id: 'm9', number: 9, stage: 'Transformar', title: 'Biblioteca 9'),
      ]),
    ], child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(
      child: MentalMapClinicalCoreSection(core: core, role: ProfileRole.psychologist, patientId: 'test'))))));
    await tester.pumpAndSettle();
    expect(find.text('Ver Biblioteca Compreender'), findsNothing);
    expect(find.text('Ver Biblioteca Transformar'), findsOneWidget);
  });
}
