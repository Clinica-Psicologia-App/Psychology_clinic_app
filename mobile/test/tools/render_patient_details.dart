// Renderiza a tela de detalhe do paciente (com avatar no header e a seção
// "Dados do paciente" redesenhada), para conferência visual.
//
//   flutter test test/tools/render_patient_details.dart
//
// Saída: build/patient_details.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_details_page.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  setUpAll(() async {
    final fontBytes = File(
      r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ).readAsBytesSync();
    await ui.loadFontFromList(fontBytes, fontFamily: 'MaterialIcons');
  });

  testWidgets('renderiza detalhe do paciente', (tester) async {
    final patient = Patient(
      id: 'p1',
      fullName: 'Roberto Silva',
      email: 'roberto.paciente@gmail.com',
      phone: '11999999999',
      cpf: '12345678901',
      birthDate: DateTime(1996, 8, 15),
      gender: 'male',
      occupation: 'Engenheiro Civil',
      hasChildren: false,
      isActive: true,
      responsiblePsychologistName: 'Bruno Psicólogo',
      accessStatus: PatientAccessStatus.active,
    );

    tester.view.physicalSize = const Size(460, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientDetailProvider.overrideWith((ref, id) => patient),
        ],
        child: const MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: Key('cap'),
            // Papel admin evita a FutureModulesSection (que exige Supabase).
            child: PatientDetailsPage(
              patientId: 'p1',
              role: ProfileRole.platformAdmin,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/patient_details.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/patient_details.png');
  });
}
