// Renderiza a tela inicial do psicólogo: menus fechados e com um aberto.
//
//   flutter test test/tools/render_psychologist_home.dart
//
// Saída: build/psy_home_closed.png, build/psy_home_patients.png,
// build/psy_home_assessment.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/auth/presentation/role_home_shell.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_status.dart';
import 'package:terapia_esquema/features/patient_invitations/providers/patient_invitations_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_alert.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';

void main() {
  setUpAll(() async {
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

  Future<void> shot(
    WidgetTester tester,
    String name, {
    String? tapText,
    bool fresh = true,
  }) async {
    if (fresh) {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(
              (ref) => _FakeAuthController(
                const UserProfile(
                  id: 'psi-1',
                  clinicId: 'clinic-1',
                  role: ProfileRole.psychologist,
                  fullName: 'Bruno Soares',
                  email: 'psicologo@example.com',
                  isActive: true,
                ),
              ),
            ),
            patientsListProvider.overrideWith(_PatientsNotifier.new),
            patientInvitationsListProvider.overrideWith(_InvitesNotifier.new),
            psychologistQuestionnairesProvider.overrideWith(
              (ref) async => [
                for (var i = 0; i < 6; i++)
                  Questionnaire(
                    id: 'q$i',
                    code: 'Q$i',
                    name: 'Instrumento $i',
                    isActive: true,
                  ),
              ],
            ),
            currentClinicEntitlementsProvider
                .overrideWith((ref) async => ClinicFeatureEntitlements.empty),
            psychologistAlertsProvider.overrideWith(
              (ref) async => const [
                PsychologistAlert(
                  kind: PsychologistAlertKind.staleQuestionnaire,
                  patientName: 'Guilherme',
                  daysCount: 41,
                  patientId: 'p1',
                ),
                PsychologistAlert(
                  kind: PsychologistAlertKind.missingCheckin,
                  patientName: 'Juliano',
                  daysCount: 40,
                  patientId: 'p2',
                ),
                PsychologistAlert(
                  kind: PsychologistAlertKind.recentCheckin,
                  patientName: 'Guilherme',
                  daysCount: 3,
                  patientId: 'p1',
                ),
                PsychologistAlert(
                  kind: PsychologistAlertKind.expiringInvitation,
                  patientName: 'Maria',
                  daysCount: 2,
                  invitationId: 'inv-1',
                ),
              ],
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            supportedLocales: const [Locale('pt', 'BR')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: const RepaintBoundary(
              key: Key('cap'),
              child: RoleHomeShell(
                title: 'EsquemaCore',
                subtitle: 'Área do profissional',
                role: ProfileRole.psychologist,
              ),
            ),
          ),
        ),
      );
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }
    if (tapText != null) {
      await tester.tap(find.text(tapText));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
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

  testWidgets('menus fechados', (tester) async {
    await shot(tester, 'psy_home_closed');
  });

  testWidgets('Meus pacientes aberto', (tester) async {
    await shot(tester, 'psy_home_patients', tapText: 'Meus pacientes');
  });

  testWidgets('Avaliação e recursos aberto', (tester) async {
    await shot(tester, 'psy_home_assessment', tapText: 'Avaliação e recursos');
  });
}

class _PatientsNotifier extends PatientsListNotifier {
  @override
  Future<List<Patient>> build() async => const [
        Patient(id: 'p-1', fullName: 'Guilherme Souza'),
        Patient(id: 'p-2', fullName: 'Juliano Alves'),
      ];
}

class _InvitesNotifier extends PatientInvitationsListNotifier {
  @override
  Future<List<PatientInvitation>> build() async => [
        PatientInvitation(
          id: 'inv-1',
          email: 'maria@example.com',
          status: PatientInvitationStatus.pending,
          expiresAt: DateTime(2030, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          invitedById: 'psi-1',
          responsiblePsychologistId: 'psi-1',
        ),
      ];
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(UserProfile profile) : super(_DummyRef()) {
    _profile = profile;
    state = AsyncValue.data(profile);
  }

  late final UserProfile _profile;

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(_profile);
  }
}

class _DummyRef implements Ref {
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool? fireImmediately,
  }) {
    return _DummyProviderSubscription<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyProviderSubscription<T> implements ProviderSubscription<T> {
  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
