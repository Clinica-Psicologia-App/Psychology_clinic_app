import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/auth/presentation/role_home_shell.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/providers/patient_invitations_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_alert.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';

/// O card de alertas nunca tinha sido exercitado em teste: o provider real
/// não era sobrescrito, então caía direto no branch de erro (SizedBox vazio)
/// e nenhuma asserção chegava a tocar o widget. Este arquivo cobre o
/// conteúdo renderizado de verdade, incluindo o redesenho "Notificações"
/// com pílula de prazo e cor por tipo de alerta.
void main() {
  testWidgets('renomeado para Notificações, com prazo em pílula por tipo',
      (tester) async {
    await _pumpHomeWithAlerts(tester, [
      const PsychologistAlert(
        kind: PsychologistAlertKind.expiringInvitation,
        patientName: 'Ana',
        daysCount: 1,
        invitationId: 'inv-1',
      ),
      const PsychologistAlert(
        kind: PsychologistAlertKind.staleQuestionnaire,
        patientName: 'Roberto',
        daysCount: 9,
        patientId: 'p-1',
      ),
      const PsychologistAlert(
        kind: PsychologistAlertKind.missingCheckin,
        patientName: 'Maria',
        daysCount: 999,
        patientId: 'p-2',
      ),
    ]);

    expect(find.text('Notificações'), findsOneWidget);
    expect(find.text('Atenções'), findsNothing);

    // A contagem tem que ser procurada DENTRO do cartão de notificações: a
    // home também mostra a faixa da semana, e o número do dia colide com a
    // contagem sempre que a semana visível contém aquele dia. Um
    // `find.text('3')` solto passava ou falhava conforme a data de hoje.
    final panel = find
        .ancestor(
          of: find.text('Notificações'),
          matching: find.byType(Column),
        )
        .first;
    expect(find.descendant(of: panel, matching: find.text('3')),
        findsOneWidget);

    // Nome e subtítulo separados da pílula de prazo — não é mais uma frase
    // corrida como "Roberto com questionário em andamento há 9 dias".
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Convite'), findsOneWidget);
    expect(find.text('amanhã'), findsOneWidget);

    expect(find.text('Roberto'), findsOneWidget);
    expect(find.text('Questionário em andamento'), findsOneWidget);
    expect(find.text('9 dias'), findsOneWidget);

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Check-in'), findsOneWidget);
    expect(find.text('nunca'), findsOneWidget);
  });

  testWidgets('a frase completa continua disponível para leitor de tela',
      (tester) async {
    await _pumpHomeWithAlerts(tester, [
      const PsychologistAlert(
        kind: PsychologistAlertKind.staleQuestionnaire,
        patientName: 'Roberto',
        daysCount: 9,
        patientId: 'p-1',
      ),
    ]);

    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel('Roberto com questionário em andamento há 9 dias'),
      findsOneWidget,
    );
    handle.dispose();
  });
}

Future<void> _pumpHomeWithAlerts(
  WidgetTester tester,
  List<PsychologistAlert> alerts,
) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
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
              fullName: 'Bruno Psicólogo',
              email: 'psicologo@example.com',
              isActive: true,
            ),
          ),
        ),
        patientsListProvider.overrideWith(_FakePatientsNotifier.new),
        patientInvitationsListProvider.overrideWith(
          _FakeEmptyInvitationsNotifier.new,
        ),
        psychologistQuestionnairesProvider.overrideWith(
          (ref) async => const <Questionnaire>[],
        ),
        currentClinicEntitlementsProvider.overrideWith(
          (ref) async => ClinicFeatureEntitlements.empty,
        ),
        psychologistAlertsProvider.overrideWith((ref) async => alerts),
      ],
      child: const MaterialApp(
        home: RoleHomeShell(
          title: 'EsquemaCore',
          subtitle: 'Área do profissional',
          role: ProfileRole.psychologist,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakePatientsNotifier extends PatientsListNotifier {
  @override
  Future<List<Patient>> build() async => const [
        Patient(id: 'p-1', fullName: 'Roberto Paciente'),
        Patient(id: 'p-2', fullName: 'Maria Paciente'),
      ];
}

class _FakeEmptyInvitationsNotifier extends PatientInvitationsListNotifier {
  @override
  Future<List<PatientInvitation>> build() async => const [];
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
