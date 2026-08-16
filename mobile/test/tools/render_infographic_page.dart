// Renderiza a PatientInfographicPage real (com override do provider composto),
// para validar página + pôster + barra de export juntos.
//
//   flutter test test/tools/render_infographic_page.dart
//
// Saída: build/infographic_page.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_data.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/patient_infographic_page.dart';
import 'package:terapia_esquema/features/patient_infographic/providers/patient_infographic_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

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
      'roboto-bold.ttf'
    ]) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  testWidgets('renderiza a página do infográfico', (tester) async {
    const data = PatientInfographicData(
      header: InfographicHeader(
        name: 'Roberto Silva',
        avatarInitials: 'RS',
        facts: [
          InfographicFact(Icons.person_outline, '39 anos'),
          InfographicFact(Icons.work_outline, 'Engenheiro Civil'),
          InfographicFact(Icons.favorite_border, 'Casado'),
        ],
      ),
      timeline: [
        InfographicTimelineEntry(
            periodLabel: '2010', description: 'Mudou-se de cidade.'),
        InfographicTimelineEntry(
            periodLabel: '2021', description: 'Perda familiar significativa.'),
      ],
      schemas: [
        InfographicItem(
            title: 'Padrões rígidos',
            description: 'Autocobrança elevada.',
            icon: Icons.psychology_outlined),
        InfographicItem(
            title: 'Autossacrifício',
            description: 'Necessidades dos outros à frente das suas.',
            icon: Icons.psychology_outlined),
      ],
      resources: [
        InfographicItem(title: 'Resiliente', icon: Icons.star_outline),
        InfographicItem(title: 'Comprometido', icon: Icons.star_outline),
      ],
      closingLine: 'Material de apoio à formulação do caso.',
    );

    tester.view.physicalSize = const Size(420, 1500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientInfographicProvider.overrideWith((ref, ctx) => data),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: const RepaintBoundary(
            key: Key('cap'),
            child: PatientInfographicPage(
              role: ProfileRole.psychologist,
              patientId: 'p1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/infographic_page.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/infographic_page.png');
  });
}
