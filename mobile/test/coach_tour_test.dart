import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/coach/data/coach_store.dart';
import 'package:terapia_esquema/features/coach/domain/coach_step.dart';
import 'package:terapia_esquema/features/coach/domain/coach_tour.dart';
import 'package:terapia_esquema/features/coach/providers/coach_providers.dart';

void main() {
  testWidgets('startTour abre, avanca e marca como visto ao concluir',
      (tester) async {
    final store = _FakeCoachStore();
    final tour = _tour();

    await tester.pumpWidget(_TestApp(store: store, tour: tour));
    await tester.tap(find.text('Iniciar'));
    await tester.pump();

    expect(find.text('Primeiro passo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('coach_next_button')));
    await tester.pump();

    expect(find.text('Segundo passo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('coach_next_button')));
    await tester.pump();

    expect(find.text('Segundo passo'), findsNothing);
    expect(store.markSeenCount, 1);
    expect(store.seen, isTrue);
  });

  testWidgets('startTour nao abre quando ja foi visto e force=false',
      (tester) async {
    final store = _FakeCoachStore(seen: true);

    await tester.pumpWidget(_TestApp(store: store, tour: _tour()));
    await tester.tap(find.text('Iniciar'));
    await tester.pump();

    expect(find.text('Primeiro passo'), findsNothing);
    expect(store.markSeenCount, 0);
  });
}

CoachTour _tour() {
  return const CoachTour(
    id: 'tour_teste',
    steps: [
      CoachStep(
        id: 'primeiro',
        text: 'Primeiro passo',
        pose: MascotPose.wave,
      ),
      CoachStep(
        id: 'segundo',
        text: 'Segundo passo',
        pose: MascotPose.celebrate,
      ),
    ],
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.store,
    required this.tour,
  });

  final _FakeCoachStore store;
  final CoachTour tour;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [coachStoreProvider.overrideWithValue(store)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Consumer(
                builder: (context, ref, _) {
                  return Center(
                    child: FilledButton(
                      onPressed: () => ref
                          .read(coachControllerProvider.notifier)
                          .startTour(context, tour),
                      child: const Text('Iniciar'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FakeCoachStore extends CoachStore {
  _FakeCoachStore({this.seen = false});

  bool seen;
  int markSeenCount = 0;

  @override
  Future<bool> hasSeen(String tourId) async => seen;

  @override
  Future<void> markSeen(String tourId) async {
    markSeenCount++;
    seen = true;
  }

  @override
  Future<void> reset(String tourId) async {
    seen = false;
  }
}
