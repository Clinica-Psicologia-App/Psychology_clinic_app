// Renderiza a seção de módulos clínicos do paciente (cores por grupo).
//
//   flutter test test/tools/render_modules_section.dart
//
// Saída: build/modules_section.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/future_modules_section.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir/materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf'
    ]) {
      await ui.loadFontFromList(
        File('$dir/$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  testWidgets('seção de módulos', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentClinicEntitlementsProvider
              .overrideWith((ref) async => ClinicFeatureEntitlements.empty),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: RepaintBoundary(
            key: const Key('cap'),
            child: Scaffold(
              backgroundColor: const Color(0xFFEFF2FA),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: FutureModulesSection(
                  role: ProfileRole.psychologist,
                  patientId: 'p1',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.6);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/modules_section.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/modules_section.png');
  });
}
