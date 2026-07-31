import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_option.dart';
import 'package:terapia_esquema/features/patients/presentation/edit_patient_page.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

Widget _wrap(Patient patient) {
  return ProviderScope(
    overrides: [
      psychologistsOptionsProvider.overrideWith(
        (ref) async => const <PsychologistOption>[],
      ),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      home: EditPatientPage(
        patient: patient,
        role: ProfileRole.psychologist,
      ),
    ),
  );
}

void main() {
  testWidgets(
      'abre com valores em português salvos sem lançar exceção de dropdown',
      (tester) async {
    const patient = Patient(
      id: 'p1',
      fullName: 'Maria Silva',
      gender: 'Feminino',
      relationshipStatus: 'Solteiro(a)',
      educationLevel: 'Ensino médio completo',
      sexualOrientation: 'Heterossexual',
      hasChildren: false,
    );

    await tester.pumpWidget(_wrap(patient));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Editar paciente'), findsOneWidget);
    // Valor em português é exibido no dropdown (antes quebrava aqui).
    expect(find.text('Feminino'), findsWidgets);
  });

  testWidgets('tolera valor legado fora da lista de opções', (tester) async {
    const patient = Patient(
      id: 'p2',
      fullName: 'João Souza',
      gender: 'valor_legado_desconhecido',
      educationLevel: 'formato antigo qualquer',
    );

    await tester.pumpWidget(_wrap(patient));
    await tester.pump();

    // Não pode quebrar mesmo com valor que não existe entre as opções.
    expect(tester.takeException(), isNull);
    expect(find.text('valor_legado_desconhecido'), findsWidgets);
  });
}
