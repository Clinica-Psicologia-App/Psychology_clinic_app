import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/daily_monitors/providers/daily_monitors_providers.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';
import 'package:terapia_esquema/features/patient_timeline/presentation/patient_timeline_page.dart';
import 'package:terapia_esquema/features/patient_timeline/presentation/patient_timeline_routes.dart';
import 'package:terapia_esquema/features/patient_timeline/providers/patient_timeline_providers.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

class _FakeMine extends MyPatientTimelineNotifier {
  _FakeMine(this.items);
  final List<PatientTimelineEvent> items;

  @override
  Future<List<PatientTimelineEvent>> build() async => items;
}

PatientTimelineEvent _event() => PatientTimelineEvent(
      id: 'e1',
      clinicId: 'c1',
      patientId: 'p1',
      title: 'Evento de exemplo',
      isSensitive: false,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

const _ctx =
    StaffPatientTimelineContext(role: ProfileRole.psychologist, patientId: 'p1');

Future<List<String>> _pump(
  WidgetTester tester, {
  required Widget page,
  required List<PatientTimelineEvent> items,
}) async {
  tester.view.physicalSize = const Size(1100, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final pushed = <String>[];
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => page),
      for (final r in [
        PatientTimelineRoutes.patientCreate,
        PatientTimelineRoutes.staffCreate(
            role: ProfileRole.psychologist, patientId: 'p1'),
      ])
        GoRoute(
          path: r,
          builder: (_, __) {
            pushed.add(r);
            return const Scaffold(body: Text('NOVO'));
          },
        ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      myPatientTimelineProvider.overrideWith(() => _FakeMine(items)),
      staffPatientTimelineProvider(_ctx).overrideWith((ref) async => items),
      myPatientIdProvider.overrideWith((ref) async => 'p1'),
      patientDetailProvider('p1').overrideWith((ref) async => null),
    ],
    child: MaterialApp.router(routerConfig: router),
  ));
  await tester.pumpAndSettle();
  return pushed;
}

void main() {
  testWidgets('paciente: lista vazia mostra "Novo evento" e abre a criação',
      (tester) async {
    final pushed =
        await _pump(tester, page: const PatientTimelinePage(), items: []);
    expect(find.text('Novo evento'), findsOneWidget);
    expect(find.text('0 acontecimentos registrados'), findsOneWidget);
    expect(
        find.textContaining('Nenhum evento na linha do tempo'), findsOneWidget);
    await tester.tap(find.text('Novo evento'));
    await tester.pumpAndSettle();
    expect(pushed, [PatientTimelineRoutes.patientCreate]);
  });

  testWidgets('psicólogo: lista vazia mostra "Novo evento" e abre a criação',
      (tester) async {
    final pushed = await _pump(
      tester,
      page: const StaffPatientTimelinePage(
          role: ProfileRole.psychologist, patientId: 'p1'),
      items: [],
    );
    expect(find.text('Novo evento'), findsOneWidget);
    expect(find.text('0 acontecimentos registrados'), findsOneWidget);
    expect(find.text('Nenhum evento registrado para este paciente.'),
        findsOneWidget);
    await tester.tap(find.text('Novo evento'));
    await tester.pumpAndSettle();
    expect(pushed, [
      PatientTimelineRoutes.staffCreate(
          role: ProfileRole.psychologist, patientId: 'p1')
    ]);
  });

  testWidgets('com 1 evento segue "1 acontecimento registrado" e o botão',
      (tester) async {
    await _pump(tester, page: const PatientTimelinePage(), items: [_event()]);
    expect(find.text('1 acontecimento registrado'), findsOneWidget);
    expect(find.text('Novo evento'), findsOneWidget);
    await _pump(
      tester,
      page: const StaffPatientTimelinePage(
          role: ProfileRole.psychologist, patientId: 'p1'),
      items: [_event()],
    );
    expect(find.text('1 acontecimento registrado'), findsOneWidget);
    expect(find.text('Novo evento'), findsOneWidget);
  });
}
