// Renderiza a AdminPlansPage (liberação de módulos por clínica).
//
//   flutter test test/tools/render_admin_plans.dart
//
// Saída: build/admin_plans.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinic_entitlements/presentation/admin_plans_page.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/admin_entitlements_providers.dart';
import 'package:terapia_esquema/features/clinics/domain/clinic_summary.dart';
import 'package:terapia_esquema/features/clinics/providers/clinics_providers.dart';

class _FakeClinics extends ClinicsNotifier {
  @override
  Future<List<ClinicSummary>> build() async => const [
        ClinicSummary(
          id: 'c1',
          name: 'Clínica Teste MVP',
          clinicType: 'clinic',
          isActive: true,
          createdAt: null,
          userCount: 2,
          patientCount: 8,
        ),
        ClinicSummary(
          id: 'c2',
          name: 'Consultório Individual',
          clinicType: 'personal',
          isActive: true,
          createdAt: null,
          userCount: 1,
          patientCount: 3,
        ),
      ];
}

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf'
    ]) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  testWidgets('planos e permissões', (tester) async {
    tester.view.physicalSize = const Size(440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clinicsProvider.overrideWith(_FakeClinics.new),
          clinicEntitlementsAdminProvider('c1').overrideWith(
              (ref) async => {'resources': false, 'reports': true}),
          clinicEntitlementsAdminProvider('c2').overrideWith((ref) async => {}),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(key: Key('cap'), child: AdminPlansPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Expande a primeira clínica para mostrar os toggles.
    await tester.tap(find.text('Clínica Teste MVP'));
    await tester.pumpAndSettle();

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/admin_plans.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/admin_plans.png');
  });
}
