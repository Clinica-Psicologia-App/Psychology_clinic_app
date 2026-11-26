// Dados fictícios e app de teste das rotas da psicóloga (casca de desktop).
// As rotas repetem as do app_router: ShellRoute + AppNavShell.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/auth/presentation/psychologist_home_page.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_status.dart';
import 'package:terapia_esquema/features/patient_invitations/presentation/patient_invitations_page.dart';
import 'package:terapia_esquema/features/patient_invitations/providers/patient_invitations_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/patient_data_completion.dart';
import 'package:terapia_esquema/features/patients/domain/patient_vitals.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_alert.dart';
import 'package:terapia_esquema/features/patients/presentation/patients_page.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/psychologist_questionnaires_page.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';
import 'package:terapia_esquema/shared/widgets/app_nav_shell.dart';

const psiProfile = UserProfile(
  id: 'psi-1',
  clinicId: 'c1',
  role: ProfileRole.psychologist,
  fullName: 'Dra. Helena Exemplo',
  email: 'usuario0@example.com',
  isActive: true,
);

const psiAlerts = [
  PsychologistAlert(
    kind: PsychologistAlertKind.staleQuestionnaire,
    patientName: 'Rafael Modelo',
    daysCount: 41,
    patientId: 'p4',
  ),
  PsychologistAlert(
    kind: PsychologistAlertKind.missingCheckin,
    patientName: 'Clara Teste',
    daysCount: 40,
    patientId: 'p2',
  ),
  PsychologistAlert(
    kind: PsychologistAlertKind.recentCheckin,
    patientName: 'Marina Exemplo',
    daysCount: 3,
    patientId: 'p3',
  ),
];

/// Contagem de cargas de cada fonte (para provar que não há consulta nova).
class PsiLoads {
  int patients = 0;
  int invitations = 0;
  int questionnaires = 0;
  int alerts = 0;
}

class _FakeAuth extends AuthController {
  _FakeAuth(UserProfile profile) : super(_DummyRef()) {
    state = AsyncValue<UserProfile?>.data(profile);
  }

  @override
  Future<void> loadProfile() async {}
}

class _DummyRef implements Ref {
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool? fireImmediately,
  }) =>
      _DummySub<T>();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummySub<T> implements ProviderSubscription<T> {
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Patient _p(String id, String name, {bool active = true}) => Patient(
      id: id,
      fullName: name,
      email: 'usuario${id.substring(1)}@example.com',
      responsiblePsychologistName: 'Dra. Helena Exemplo',
      isActive: active,
    );

/// As seis pessoas fictícias (a última, inativa).
final psiPatients = [
  _p('p1', 'Beatriz Amostra'),
  _p('p2', 'Clara Teste'),
  _p('p3', 'Marina Exemplo'),
  _p('p4', 'Rafael Modelo'),
  _p('p5', 'Tiago Fictício'),
  _p('p6', 'Sofia Simulada', active: false),
];

PatientDataCompletion _c(String id, int filled) => PatientDataCompletion(
      patientId: id,
      perfil: filled > 0,
      queixa: filled > 1,
      areas: filled > 2,
      historia: filled > 3,
      familia: filled > 4,
      questionarios: filled > 5,
    );

/// Preenchimento fictício: 83%, 17%, 100%, 50% e 33%.
final psiCompletion = {
  'p1': _c('p1', 5),
  'p2': _c('p2', 1),
  'p3': _c('p3', 6),
  'p4': _c('p4', 3),
  'p5': _c('p5', 2),
};

class _FakePatients extends PatientsListNotifier {
  _FakePatients(this.loads, this.source);
  final PsiLoads loads;
  final Future<List<Patient>> Function()? source;

  @override
  Future<List<Patient>> build() {
    loads.patients++;
    return source == null ? Future.value(psiPatients) : source!();
  }

  @override
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }
}

class _FakeInvitations extends PatientInvitationsListNotifier {
  _FakeInvitations(this.loads);
  final PsiLoads loads;

  @override
  Future<List<PatientInvitation>> build() async {
    loads.invitations++;
    return [
      PatientInvitation(
        id: 'inv-1',
        email: 'usuario7@example.com',
        fullName: 'Convidada Fictícia',
        status: PatientInvitationStatus.pending,
        expiresAt: DateTime(2030, 1, 1),
        createdAt: DateTime(2026, 1, 1),
        invitedById: 'psi-1',
        responsiblePsychologistId: 'psi-1',
      ),
    ];
  }
}

/// A paciente fictícia da ficha.
Patient psiMarina({
  bool active = true,
  PatientAccessStatus? access = PatientAccessStatus.active,
  String? relationship,
  String occupation = 'Designer',
  String name = 'Marina Exemplo',
}) =>
    Patient(
      id: 'p3',
      fullName: name,
      email: 'usuario3@example.com',
      birthDate: DateTime(1992, 4, 12),
      occupation: occupation,
      relationshipStatus: relationship,
      responsiblePsychologistName: 'Dra. Helena Exemplo',
      accessStatus: access,
      isActive: active,
    );

const psiVitals = PatientVitals(
    lastCheckinDays: 2, activeGoals: 3, pendingQuestionnaires: 1);

/// Plano que bloqueia questionários, relatórios e recursos.
const psiBlocked = ClinicFeatureEntitlements({
  'questionnaires': ClinicFeatureEntitlement(
      featureKey: 'questionnaires',
      featureName: 'Questionários',
      isEnabled: false),
  'reports': ClinicFeatureEntitlement(
      featureKey: 'reports', featureName: 'Relatórios', isEnabled: false),
  'resources': ClinicFeatureEntitlement(
      featureKey: 'resources', featureName: 'Recursos', isEnabled: false),
});

/// Destinos da psicóloga (os do app_router).
const psiDestinations = [
  AppNavDestination(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/psychologist',
      exactMatch: true),
  AppNavDestination(
      label: 'Pacientes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/psychologist/patients'),
  AppNavDestination(
      label: 'Convites',
      icon: Icons.mark_email_unread_outlined,
      selectedIcon: Icons.mark_email_unread,
      route: '/psychologist/patient-invitations'),
  AppNavDestination(
      label: 'Instrumentos',
      icon: Icons.assignment_outlined,
      selectedIcon: Icons.assignment,
      route: '/psychologist/questionnaires'),
];

/// Tela que não interessa aqui: mostra o endereço aberto.
Widget _stub(String text) => Scaffold(body: Center(child: Text(text)));

GoRouter psiRouter(
  String location, {
  GoRouterWidgetBuilder? newPatient,
  GoRouterWidgetBuilder? newInvitation,
  List<RouteBase> patientRoutes = const [],
  GoRouterWidgetBuilder? ficha,
  List<RouteBase> outside = const [],
}) =>
    GoRouter(
      initialLocation: location,
      routes: [
        ShellRoute(
          builder: (_, __, child) =>
              AppNavShell(destinations: psiDestinations, child: child),
          routes: [
            GoRoute(
              path: '/psychologist',
              builder: (_, __) => const PsychologistHomePage(),
              routes: [
                GoRoute(
                  path: 'questionnaires',
                  builder: (_, __) => const PsychologistQuestionnairesPage(),
                ),
                GoRoute(
                  path: 'patient-invitations',
                  builder: (_, __) => const PatientInvitationsPage(
                      role: ProfileRole.psychologist),
                  routes: [
                    GoRoute(
                        path: 'new',
                        builder: newInvitation ??
                            (_, __) => _stub('Convite fictício')),
                  ],
                ),
                GoRoute(
                  path: 'patients',
                  builder: (_, state) => state.extra == null
                      ? const PatientsPage(role: ProfileRole.psychologist)
                      : _stub('Escolher paciente ${state.extra}'),
                  routes: [
                    GoRoute(
                        path: 'new',
                        builder: newPatient ??
                            (_, __) => _stub('Cadastro fictício')),
                    GoRoute(
                      path: ':patientId',
                      builder: ficha ??
                          (_, state) => _stub(
                              'Ficha ${state.pathParameters['patientId']}'),
                      routes: [
                        ...patientRoutes,
                        GoRoute(
                            path: 'questionnaires',
                            builder: (_, state) => _stub(
                                'Questionários ${state.pathParameters['patientId']}')),
                        GoRoute(
                            path: 'check-ins',
                            builder: (_, state) => _stub(
                                'Check-ins ${state.pathParameters['patientId']}')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        GoRoute(path: '/profile', builder: (_, __) => _stub('Perfil fictício')),
        ...outside,
      ],
    );

/// App de teste. [alerts] nulo = as três notificações fictícias.
Widget psiApp(
  GoRouter router, {
  PsiLoads? loads,
  Future<List<PsychologistAlert>> Function()? alerts,
  UserProfile profile = psiProfile,
  bool dark = false,
  Future<List<Patient>> Function()? patients,
  Map<String, PatientDataCompletion> completion = const {},
  Set<String> pendingRelease = const {'p5'},
  Future<ClinicFeatureEntitlements> Function()? entitlements,
  List<Override> overrides = const [],
}) {
  final count = loads ?? PsiLoads();
  final theme = dark ? AppTheme.dark : AppTheme.light;
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      authControllerProvider.overrideWith((ref) => _FakeAuth(profile)),
      patientsListProvider
          .overrideWith(() => _FakePatients(count, patients)),
      patientInvitationsListProvider
          .overrideWith(() => _FakeInvitations(count)),
      psychologistQuestionnairesProvider.overrideWith((ref) async {
        count.questionnaires++;
        return [
          for (var i = 1; i <= 6; i++)
            Questionnaire(
                id: 'q$i',
                code: 'Q$i',
                name: 'Instrumento fictício $i',
                isActive: true),
        ];
      }),
      psychologistAlertsProvider.overrideWith((ref) {
        count.alerts++;
        return alerts == null ? Future.value(psiAlerts) : alerts();
      }),
      patientsPendingResultsReleaseProvider
          .overrideWith((ref) async => pendingRelease),
      patientsDataCompletionProvider.overrideWith((ref) async => completion),
      currentClinicEntitlementsProvider.overrideWith((ref) =>
          entitlements == null
              ? Future.value(ClinicFeatureEntitlements.empty)
              : entitlements()),
      ...overrides,
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Poppins')),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  );
}
