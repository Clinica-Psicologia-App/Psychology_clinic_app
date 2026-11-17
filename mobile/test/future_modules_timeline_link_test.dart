import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/initial_assessment/presentation/initial_assessment_routes.dart';
import 'package:terapia_esquema/features/patient_timeline/presentation/patient_timeline_routes.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/future_modules_section.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  testWidgets('"Linha do Tempo" da ficha abre a linha do tempo, não a História',
      (tester) async {
    tester.view.physicalSize = const Size(600, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final timeline = PatientTimelineRoutes.staffList(
        role: ProfileRole.psychologist, patientId: 'p1');
    final history = InitialAssessmentRoutes.staffHistory(
        role: ProfileRole.psychologist, patientId: 'p1');
    final pushed = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: SingleChildScrollView(
              child: FutureModulesSection(
                  role: ProfileRole.psychologist, patientId: 'p1'),
            ),
          ),
        ),
        for (final r in {timeline, history})
          GoRoute(
            path: r,
            builder: (_, __) {
              pushed.add(r);
              return const Scaffold(body: Text('DESTINO'));
            },
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        currentClinicEntitlementsProvider
            .overrideWith((ref) async => ClinicFeatureEntitlements.empty),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    final card = find.text('Linha do Tempo');
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(pushed, [timeline]);
  });
}
