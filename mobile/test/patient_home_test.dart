import 'package:flutter/material.dart';
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
import 'package:terapia_esquema/features/profile/presentation/widgets/avatar_artwork.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_patient_status.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/questionnaire_response_status.dart';
import 'package:terapia_esquema/features/results/providers/results_providers.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal_status.dart';
import 'package:terapia_esquema/features/therapy_goals/providers/therapy_goals_providers.dart';

/// A home do psicólogo já quebrou por inteiro por um erro de layout que os
/// testes não pegaram na hora (ver psychologist_home_test.dart). Este arquivo
/// existe para a home do paciente ter a mesma rede de segurança: ela ganhou
/// avatar na saudação, um resumo de progresso e atalhos de exploração nesta
/// sessão, e nenhum desses três tinha cobertura nenhuma antes.
const _patientCtx = QuestionnaireListContext(role: ProfileRole.patient);

void main() {
  testWidgets('home do paciente renderiza sem erro de layout', (tester) async {
    await _pumpHome(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Seu progresso'), findsOneWidget);
    expect(find.text('Explorar'), findsOneWidget);
  });

  testWidgets('resumo mostra metas, check-ins e resultados reais',
      (tester) async {
    await _pumpHome(tester);

    // 1 meta ativa (a segunda está concluída e não deve contar), 1 check-in
    // dos dois últimos 7 dias (o outro é de 20 dias atrás) e 2 resultados.
    expect(find.text('1'), findsNWidgets(2)); // metas ativas + check-ins
    expect(find.text('2'), findsOneWidget); // resultados
    expect(find.text('Metas ativas'), findsOneWidget);
    expect(find.text('Check-ins na semana'), findsOneWidget);
    expect(find.text('Resultados'), findsOneWidget);
  });

  testWidgets('atalhos de exploração levam aos módulos certos', (tester) async {
    await _pumpHome(tester);

    expect(find.text('Mapa mental'), findsOneWidget);
    expect(find.text('Biblioteca terapêutica'), findsOneWidget);
    expect(find.text('Monitor diário'), findsOneWidget);
  });

  // A saudação nunca mostrou a foto nem o avatar geométrico do paciente —
  // só o card institucional do profissional recebia esse tratamento.
  testWidgets('saudação exibe o avatar escolhido pelo paciente',
      (tester) async {
    await _pumpHome(tester, avatarConfig: const AvatarConfig());

    expect(find.byType(AvatarArtwork), findsWidgets);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  AvatarConfig? avatarConfig,
}) async {
  // Altura generosa: a home do paciente ganhou resumo + atalhos nesta
  // sessão e passou a ser mais alta que o viewport padrão. find.text só
  // enxerga Elements construídos, e a sliver list do ListView não constrói
  // o que está fora da área visível + cache — sem isto, as seções de baixo
  // (Explorar, Sua continuidade) simplesmente não existem na árvore ainda.
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  const patientId = 'pac-1';
  final now = DateTime.now();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(
            UserProfile(
              id: patientId,
              clinicId: 'clinic-1',
              role: ProfileRole.patient,
              fullName: 'Roberto Paciente',
              email: 'roberto@example.com',
              isActive: true,
              avatarType: avatarConfig == null
                  ? AvatarType.initials
                  : AvatarType.custom,
              avatarConfig: avatarConfig,
            ),
          ),
        ),
        currentClinicEntitlementsProvider.overrideWith(
          (ref) async => ClinicFeatureEntitlements.empty,
        ),
        // _PatientNextStep e _PatientProgressSummary resolvem o próprio
        // patientId por este mesmo provider.
        questionnairePatientIdProvider(_patientCtx).overrideWith(
          (ref) async => patientId,
        ),
        questionnairesListProvider(_patientCtx).overrideWith(
          (ref) async => const <Questionnaire>[],
        ),
        questionnairePatientStatusProvider(patientId).overrideWith(
          (ref) async => const <String, QuestionnairePatientStatus>{},
        ),
        todayCheckInProvider.overrideWith((ref) async => null),
        myTherapyGoalsProvider.overrideWith(_FakeTherapyGoalsNotifier.new),
        myPatientCheckInsProvider.overrideWith(
          () => _FakeCheckInsNotifier(now),
        ),
        patientResultsListProvider.overrideWith(_FakeResultsNotifier.new),
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
}

class _FakeTherapyGoalsNotifier extends MyTherapyGoalsNotifier {
  @override
  Future<List<TherapyGoal>> build() async {
    final now = DateTime.now();
    return [
      TherapyGoal(
        id: 'goal-1',
        clinicId: 'clinic-1',
        patientId: 'pac-1',
        title: 'Meta ativa',
        status: TherapyGoalStatus.active,
        createdAt: now,
        updatedAt: now,
      ),
      TherapyGoal(
        id: 'goal-2',
        clinicId: 'clinic-1',
        patientId: 'pac-1',
        title: 'Meta concluída',
        status: TherapyGoalStatus.completed,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}

class _FakeCheckInsNotifier extends MyPatientCheckInsNotifier {
  _FakeCheckInsNotifier(this._now);

  final DateTime _now;

  @override
  Future<List<PatientCheckIn>> build() async {
    return [
      PatientCheckIn(
        id: 'ci-1',
        clinicId: 'clinic-1',
        patientId: 'pac-1',
        checkedInAt: _now.subtract(const Duration(days: 2)),
        createdAt: _now,
        updatedAt: _now,
      ),
      PatientCheckIn(
        id: 'ci-2',
        clinicId: 'clinic-1',
        patientId: 'pac-1',
        checkedInAt: _now.subtract(const Duration(days: 20)),
        createdAt: _now,
        updatedAt: _now,
      ),
    ];
  }
}

class _FakeResultsNotifier extends PatientResultsListNotifier {
  @override
  Future<List<PatientResponseSummary>> build(PatientResultsContext arg) async {
    return [
      const PatientResponseSummary(
        id: 'resp-1',
        questionnaireId: 'q-1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        answerCount: 90,
        hasResults: true,
        resultsCount: 1,
      ),
      const PatientResponseSummary(
        id: 'resp-2',
        questionnaireId: 'q-2',
        questionnaireCode: 'YAMI_MODES_FOUNDATION_V1',
        questionnaireName: 'YAMI',
        status: QuestionnaireResponseStatus.completed,
        answerCount: 40,
        hasResults: true,
        resultsCount: 1,
      ),
    ];
  }
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
