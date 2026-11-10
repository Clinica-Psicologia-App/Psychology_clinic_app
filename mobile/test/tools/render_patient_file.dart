// Renderiza a ficha do paciente (psicólogo) e a página "Dados cadastrais".
//
//   flutter test test/tools/render_patient_file.dart
//
// Saída: build/patient_file.png, build/patient_registration.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/patient_vitals.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_details_page.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_registration_page.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir/materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      await ui.loadFontFromList(
        File('assets/fonts/$f').readAsBytesSync(),
        fontFamily: 'Poppins',
      );
    }
  });

  final patient = Patient(
    id: 'p1',
    fullName: 'Guilherme Souza',
    email: 'guilherme.paciente@gmail.com',
    phone: '51999998888',
    cpf: '12345678901',
    birthDate: DateTime(2002, 2, 28),
    gender: 'male',
    relationshipStatus: 'married',
    educationLevel: 'higher_education',
    occupation: 'Analista',
    countryBirth: 'Brasil',
    stateBirth: 'RS',
    hasChildren: false,
    isActive: true,
    responsiblePsychologistName: 'Bruno Soares',
    accessStatus: PatientAccessStatus.active,
  );

  Future<void> shot(WidgetTester tester, String name, Widget page,
      {double height = 1900}) async {
    tester.view.physicalSize = Size(420, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientDetailProvider.overrideWith((ref, id) => patient),
          patientVitalsProvider.overrideWith((ref, id) => const PatientVitals(
                lastCheckinDays: 9,
                activeGoals: 2,
                pendingQuestionnaires: 1,
              )),
          currentClinicEntitlementsProvider
              .overrideWith((ref) async => ClinicFeatureEntitlements.empty),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: RepaintBoundary(key: const Key('cap'), child: page),
        ),
      ),
    );
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/$name.png');
  }

  testWidgets('ficha do paciente', (tester) async {
    await shot(
      tester,
      'patient_file',
      const PatientDetailsPage(patientId: 'p1', role: ProfileRole.psychologist),
    );
  });

  testWidgets('dados cadastrais', (tester) async {
    await shot(
      tester,
      'patient_registration',
      const PatientRegistrationPage(
          patientId: 'p1', role: ProfileRole.psychologist),
      height: 1500,
    );
  });
}
