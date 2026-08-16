// Renderiza o HomeGreetingHeader real nos três acentos (psicólogo, paciente,
// admin) para conferir a consistência.
//
//   flutter test test/tools/render_role_home_header.dart
//
// Saída: build/role_home_header.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/shared/widgets/home_greeting_header.dart';

UserProfile _p(String name, ProfileRole role) => UserProfile(
      id: 'u',
      clinicId: 'c',
      role: role,
      fullName: name,
      email: 'x@y.z',
      isActive: true,
    );

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

  testWidgets('três cabeçalhos consistentes', (tester) async {
    tester.view.physicalSize = const Size(440, 760);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: const Key('cap'),
              child: Column(
                children: [
                  HomeGreetingHeader(
                    profile:
                        _p('Bruno Fagundes Soares', ProfileRole.psychologist),
                    accent: AppColors.turquoise,
                    name: 'Bruno',
                    contextLine:
                        '3 pacientes na sua carteira. Tudo em dia por aqui.',
                    watermarkIcon: Icons.psychology_alt_outlined,
                  ),
                  const SizedBox(height: 16),
                  HomeGreetingHeader(
                    profile: _p('Maria Clara', ProfileRole.patient),
                    accent: AppColors.blue,
                    name: 'Maria',
                    contextLine:
                        'Que bom te ver por aqui. Este é o seu espaço de cuidado.',
                    watermarkIcon: Icons.spa_outlined,
                  ),
                  const SizedBox(height: 16),
                  HomeGreetingHeader(
                    profile: _p('Ana Admin', ProfileRole.platformAdmin),
                    accent: AppColors.purple,
                    name: 'Ana',
                    contextLine: 'Visão geral da plataforma e da operação.',
                    watermarkIcon: Icons.admin_panel_settings_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> capture(String file) async {
      final boundary = tester
          .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
      late final Uint8List png;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        png = bytes!.buffer.asUint8List();
      });
      File('build/$file')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(png);
      // ignore: avoid_print
      print('Gerado build/$file');
    }

    await tester.pump(); // dispara o post-frame callback (inicia a coreografia)
    await tester.pump(const Duration(milliseconds: 250)); // meio da entrada
    await capture('role_home_header_mid.png');
    await tester.pump(const Duration(milliseconds: 900)); // estado final
    await capture('role_home_header.png');
  });
}
