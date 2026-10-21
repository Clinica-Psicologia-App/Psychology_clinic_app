import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/coping_card.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/coping_cards_page.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/practice_library_links.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/psychoeducation_journey_page.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/psychoeducation_routes.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/coping_cards_provider.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/psychoeducation_providers.dart';
import 'package:terapia_esquema/features/daily_monitors/providers/daily_monitors_providers.dart';

void main() {
  testWidgets('cards show empty state after retrying a load error',
      (tester) async {
    var attempts = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      myPatientIdProvider.overrideWith((ref) async => 'patient'),
      myCopingCardsProvider.overrideWith((ref) async {
        if (attempts++ == 0) throw Exception('offline');
        return [];
      }),
    ], child: const MaterialApp(home: CopingCardsPage())));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.textContaining('Ainda não há resultados YCI ou YRAI'),
        findsOneWidget);
  });
  for (final label in ['Diários', 'Cartões de enfrentamento']) {
    testWidgets('Praticar opens $label and returns to library', (tester) async {
      final router =
          GoRouter(initialLocation: '/patient/psychoeducation', routes: [
        GoRoute(
            path: '/patient',
            builder: (_, __) => const SizedBox(),
            routes: [
              ...psychoeducationPatientRoutes(),
              GoRoute(
                  path: 'daily-monitors',
                  builder: (_, __) =>
                      const Scaffold(body: Text('Diário aberto')),
                  routes: [
                    GoRoute(
                        path: 'new',
                        builder: (_, __) =>
                            const Scaffold(body: Text('Novo diário')))
                  ]),
            ]),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(overrides: [
        psychoeducationJourneyProvider.overrideWith((ref) async => []),
        myCopingCardsProvider.overrideWith((ref) async => [
              const CopingCard(
                  topic: 'Tema sintético',
                  source: 'YCI',
                  responseId: 'synthetic'),
            ]),
      ], child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      expect(find.text('Praticar'), findsOneWidget);
      expect(find.byType(PracticeLibraryLinks), findsOneWidget);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      if (label == 'Diários') {
        expect(find.text('Diário aberto'), findsOneWidget);
      } else {
        expect(find.byType(CopingCardsPage), findsOneWidget);
        expect(find.text('Tema sintético'), findsOneWidget);
        await tester.tap(find.text('Registrar no Diário'));
        await tester.pumpAndSettle();
        expect(find.text('Novo diário'), findsOneWidget);
        router.pop();
        await tester.pumpAndSettle();
      }
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(PsychoeducationJourneyPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('staff library does not show patient diary/cards shortcuts',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          psychoeducationJourneyProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
            home: PsychoeducationJourneyPage(
                moduleRouteBuilder: PsychoeducationRoutes.psychologistModule,
                staffView: true))));
    await tester.pumpAndSettle();
    expect(find.byType(PracticeLibraryLinks), findsNothing);
  });
}
