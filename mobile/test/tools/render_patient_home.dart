// Captura a home do paciente em PNG para inspeção visual — não é um teste
// de verdade (não faz assert de conteúdo, só grava a imagem).
//
//   flutter test test/tools/render_patient_home.dart
//
// Saída: build/patient_home.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/auth/presentation/role_home_shell.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/patient_check_in.dart';
import 'package:terapia_esquema/features/patient_check_ins/providers/patient_check_ins_providers.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_patient_status.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/questionnaire_response_status.dart';
import 'package:terapia_esquema/features/results/providers/results_providers.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal_status.dart';
import 'package:terapia_esquema/features/therapy_goals/providers/therapy_goals_providers.dart';

const _patientCtx = QuestionnaireListContext(role: ProfileRole.patient);
const _patientId = 'pac-1';

void main() {
  testWidgets('captura a home do paciente', (tester) async {
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final now = DateTime.now();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _FakeAuthController(
              const UserProfile(
                id: _patientId,
                clinicId: 'clinic-1',
                role: ProfileRole.patient,
                fullName: 'Roberto Paciente',
                email: 'roberto@example.com',
                isActive: true,
                avatarType: AvatarType.custom,
                avatarConfig: AvatarConfig(
                  skinTone: AvatarSkinTone.tan,
                  hairStyle: AvatarHairStyle.short,
                  hairColor: AvatarHairColor.darkBrown,
                  outfitColor: AvatarPaletteColor.blue,
                  backgroundColor: AvatarPaletteColor.turquoise,
                ),
              ),
            ),
          ),
          currentClinicEntitlementsProvider.overrideWith(
            (ref) async => ClinicFeatureEntitlements.empty,
          ),
          questionnairePatientIdProvider(_patientCtx)
              .overrideWith((ref) async => _patientId),
          questionnairesListProvider(_patientCtx)
              .overrideWith((ref) async => const <Questionnaire>[]),
          questionnairePatientStatusProvider(_patientId).overrideWith(
            (ref) async => const <String, QuestionnairePatientStatus>{},
          ),
          todayCheckInProvider.overrideWith((ref) async => null),
          myTherapyGoalsProvider.overrideWith(() => _FakeGoals()),
          myPatientCheckInsProvider.overrideWith(() => _FakeCheckIns(now)),
          patientResultsListProvider.overrideWith(() => _FakeResults()),
        ],
        child: const MaterialApp(
          home: RoleHomeShell(
            title: 'EsquemaCore',
            subtitle: 'Sua jornada terapêutica',
            role: ProfileRole.patient,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final image = await captureImage(
      find.byType(RoleHomeShell),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final out = File('build/patient_home.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('Gerado em ${out.absolute.path}');
  });
}

Future<ui.Image> captureImage(Finder finder) async {
  final element = finder.evaluate().single;
  final renderObject = element.renderObject!;
  // A tela inteira já é maior que o viewport; envolvemos numa
  // RepaintBoundary implícita via toImage do próprio RenderRepaintBoundary
  // mais próximo (o MaterialApp/Scaffold já fornece uma).
  RenderRepaintBoundary boundary;
  RenderObject current = renderObject;
  while (current is! RenderRepaintBoundary) {
    current = current.parent!;
  }
  boundary = current;
  return boundary.toImage(pixelRatio: 1.0);
}

class _FakeGoals extends MyTherapyGoalsNotifier {
  @override
  Future<List<TherapyGoal>> build() async {
    final now = DateTime.now();
    return [
      TherapyGoal(
        id: 'g1',
        clinicId: 'clinic-1',
        patientId: _patientId,
        title: 'Meta ativa',
        status: TherapyGoalStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

class _FakeCheckIns extends MyPatientCheckInsNotifier {
  _FakeCheckIns(this._now);
  final DateTime _now;

  @override
  Future<List<PatientCheckIn>> build() async => [
        PatientCheckIn(
          id: 'ci1',
          clinicId: 'clinic-1',
          patientId: _patientId,
          checkedInAt: _now.subtract(const Duration(days: 1)),
          createdAt: _now,
          updatedAt: _now,
        ),
      ];
}

class _FakeResults extends PatientResultsListNotifier {
  @override
  Future<List<PatientResponseSummary>> build(
    PatientResultsContext arg,
  ) async =>
      const [
        PatientResponseSummary(
          id: 'r1',
          questionnaireId: 'q1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          status: QuestionnaireResponseStatus.completed,
          answerCount: 90,
          hasResults: true,
          resultsCount: 1,
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
    return _DummySubscription<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummySubscription<T> implements ProviderSubscription<T> {
  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
