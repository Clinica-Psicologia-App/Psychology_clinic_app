// Preview do infográfico com POUCOS dados (só cabeçalho + linha do tempo) —
// valida os placeholders "a preencher" das seções ainda vazias.
//
//   flutter test test/tools/render_infographic_sparse.dart
//
// Saída: build/infographic_sparse.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_data.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/widgets/patient_infographic_poster.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  testWidgets('preview esparso do infográfico (placeholders)', (tester) async {
    final data = PatientInfographicData(
      header: InfographicHeader(
        name: 'Maria',
        avatarInitials: 'M',
        avatarType: AvatarType.custom,
        avatarConfig: AvatarConfig.fromJson(const {}),
        facts: const [
          InfographicFact(Icons.person_outline, '30 anos'),
          InfographicFact(Icons.work_outline, 'Recursos Humanos'),
          InfographicFact(Icons.school_outlined, 'Ensino superior completo'),
          InfographicFact(Icons.favorite_border, 'Casado(a)'),
        ],
      ),
      // Só a linha do tempo tem dados — o resto deve virar placeholder.
      timeline: const [
        InfographicTimelineEntry(
            periodLabel: 'Data não informada',
            description: 'não posso contar com ninguém',
            icon: Icons.event_note_outlined),
        InfographicTimelineEntry(
            periodLabel: 'Data não informada',
            description: 'estudar e aprender a tomar decisões difíceis',
            icon: Icons.event_note_outlined),
        InfographicTimelineEntry(
            periodLabel: 'Data não informada',
            description: 'Cresci com meus amigos na rua',
            icon: Icons.event_note_outlined),
      ],
      generatedOn: DateTime(2026, 9, 3),
      closingLine:
          'Um retrato de apoio à formulação do caso — sempre sob leitura clínica do profissional.',
    );

    tester.view.physicalSize = const Size(1060, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('cap'),
              child: PatientInfographicPoster(data: data),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/infographic_sparse.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/infographic_sparse.png');
  });
}
