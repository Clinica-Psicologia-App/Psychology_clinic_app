import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/auth/presentation/role_home_shell.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_status.dart';
import 'package:terapia_esquema/features/patient_invitations/providers/patient_invitations_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/profile/presentation/widgets/avatar_artwork.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';

/// A home do profissional já quebrou por inteiro por um erro de layout
/// (`CrossAxisAlignment.stretch` num Row de altura ilimitada dentro do
/// ListView), deixando a tela em branco. Estes testes renderizam a tela de
/// verdade para que uma falha dessas apareça aqui, e não no aparelho.
void main() {
  testWidgets('home do psicólogo renderiza sem erro de layout', (tester) async {
    await _pumpHome(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Central de trabalho'), findsOneWidget);
    expect(find.text('Carteira de pacientes'), findsOneWidget);
  });

  testWidgets('resumo mostra as três métricas em uma linha', (tester) async {
    await _pumpHome(tester);

    // "Pacientes" e "Convites" aparecem duas vezes cada: como rótulo da
    // métrica e como título do card de módulo. O resumo vem antes na lista,
    // então a primeira ocorrência é sempre a do painel.
    final pacientes = tester.getCenter(find.text('Pacientes').first);
    final convites = tester.getCenter(find.text('Convites').first);
    final questionarios = tester.getCenter(find.text('Questionários').first);

    // Colunas de largura igual e na mesma linha: o layout anterior (Wrap)
    // deixava a terceira métrica órfã numa segunda linha.
    expect(pacientes.dy, convites.dy);
    expect(convites.dy, questionarios.dy);

    // E espaçadas por igual — cada coluna ocupa um terço da largura.
    expect(
      convites.dx - pacientes.dx,
      closeTo(questionarios.dx - convites.dx, 1.0),
    );
  });

  testWidgets('saudação usa o primeiro nome do profissional', (tester) async {
    await _pumpHome(tester);

    expect(find.textContaining('Bruno'), findsWidgets);
    // O cartão institucional antigo expunha o e-mail sem necessidade.
    expect(find.textContaining('psicologo@example.com'), findsNothing);
  });

  // O cabeçalho já desenhou um círculo com a inicial na mão, e por isso
  // ignorava a foto e o avatar geométrico que o usuário tinha escolhido.
  testWidgets('cabeçalho exibe o avatar escolhido, não a inicial',
      (tester) async {
    await _pumpHome(tester, avatarConfig: const AvatarConfig());

    expect(find.byType(AvatarArtwork), findsWidgets);
  });
}

Future<void> _pumpHome(
  WidgetTester tester, {
  AvatarConfig? avatarConfig,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(
            UserProfile(
              id: 'psi-1',
              clinicId: 'clinic-1',
              role: ProfileRole.psychologist,
              fullName: 'Bruno Psicólogo',
              email: 'psicologo@example.com',
              isActive: true,
              avatarType: avatarConfig == null
                  ? AvatarType.initials
                  : AvatarType.custom,
              avatarConfig: avatarConfig,
            ),
          ),
        ),
        patientsListProvider.overrideWith(_FakePatientsNotifier.new),
        patientInvitationsListProvider.overrideWith(
          _FakeInvitationsNotifier.new,
        ),
        psychologistQuestionnairesProvider.overrideWith(
          (ref) async => const <Questionnaire>[],
        ),
        currentClinicEntitlementsProvider.overrideWith(
          (ref) async => ClinicFeatureEntitlements.empty,
        ),
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

class _FakeInvitationsNotifier extends PatientInvitationsListNotifier {
  @override
  Future<List<PatientInvitation>> build() async => [
        PatientInvitation(
          id: 'inv-1',
          email: 'novo@example.com',
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
