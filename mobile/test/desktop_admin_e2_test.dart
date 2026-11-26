// Admin E2 (Clínicas, Pacientes, Planos): layout ≥768 px vs celular e fluxos.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/clinics/domain/clinic_summary.dart';
import 'package:terapia_esquema/features/clinics/providers/clinics_providers.dart';
import 'package:terapia_esquema/features/clinic_entitlements/presentation/admin_plans_page.dart';
import 'package:terapia_esquema/features/clinic_entitlements/data/admin_entitlements_repository.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/admin_entitlements_providers.dart';
import 'package:terapia_esquema/features/clinics/presentation/clinics_page.dart';
import 'package:terapia_esquema/features/platform_admin/presentation/patient_overview_page.dart';
import 'package:terapia_esquema/features/platform_admin/presentation/platform_admin_home_page.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/user_management/domain/clinic_user.dart';
import 'package:terapia_esquema/features/user_management/presentation/user_management_page.dart';
import 'package:terapia_esquema/features/user_management/providers/user_management_providers.dart';
import 'package:terapia_esquema/shared/widgets/app_nav_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';

import 'desktop_admin_hover_helper.dart';

class _FakeAuth extends AuthController {
  _FakeAuth() : super(_DummyRef()) {
    state = const AsyncValue<UserProfile?>.data(UserProfile(
      id: 'a1',
      clinicId: 'c1',
      role: ProfileRole.platformAdmin,
      fullName: 'Admin Exemplo',
      email: 'admin@example.com',
      isActive: true,
    ));
  }
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

ClinicUser _u(String id, String clinic, String type, String name,
        ProfileRole role, bool active,
        {int assigned = 0}) =>
    ClinicUser(
      id: id,
      clinicId: clinic,
      clinicName: clinic == 'c1' ? 'Clínica Exemplo' : 'Consultório Individual Modelo',
      clinicType: type,
      clinicIsActive: true,
      fullName: name,
      email: 'usuario$id@example.com',
      role: role,
      isActive: active,
      assignedPatientsCount: assigned,
    );

final _users = [
  _u('3', 'c1', 'clinic', 'Dr. Lucas Amostra', ProfileRole.platformAdmin, true),
  _u('6', 'c1', 'clinic', 'Dra. Carla Demonstrativa', ProfileRole.platformAdmin, true),
  _u('0', 'c1', 'clinic', 'Dra. Helena Exemplo', ProfileRole.platformAdmin, false),
  _u('1', 'c1', 'clinic', 'Dr. Paulo Modelo', ProfileRole.psychologist, true),
  _u('5', 'c1', 'clinic', 'Dr. Tiago Simulado', ProfileRole.psychologist, false),
  _u('4', 'c1', 'clinic', 'Dra. Beatriz Teste', ProfileRole.psychologist, true),
  _u('2', 'c1', 'clinic', 'Dra. Renata Fictícia', ProfileRole.psychologist, true),
  _u('9', 'c2', 'personal', 'Dr. Mateus Exemplar', ProfileRole.platformAdmin, true),
  _u('11', 'c2', 'personal', 'Dr. Bruno Protótipo', ProfileRole.psychologist, true),
  _u('7', 'c2', 'personal', 'Dr. Rafael Hipotético', ProfileRole.psychologist, true),
  _u('10', 'c2', 'personal', 'Dra. Ana Clara Sintética', ProfileRole.psychologist, false),
  _u('8', 'c2', 'personal', 'Dra. Juliana Fictícia', ProfileRole.psychologist, true),
];

class _FakeUsers extends ClinicUsersNotifier {
  @override
  Future<List<ClinicUser>> build() async => _users;
}

class _FakeClinics extends ClinicsNotifier {
  @override
  Future<List<ClinicSummary>> build() async => [
        ClinicSummary(
            id: 'c1',
            name: 'Clínica Exemplo',
            clinicType: 'clinic',
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
            userCount: 7,
            patientCount: 8),
        ClinicSummary(
            id: 'c2',
            name: 'Consultório Individual Modelo',
            clinicType: 'personal',
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
            userCount: 1,
            patientCount: 3),
      ];
}

const _dest = [
  AppNavDestination(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/platform',
      exactMatch: true),
  AppNavDestination(
      label: 'Clínicas',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment,
      route: '/platform/clinics'),
  AppNavDestination(
      label: 'Usuários',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      route: '/platform/users'),
  AppNavDestination(
      label: 'Pacientes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/platform/patient-overview'),
];


class _FakeMutation extends EntitlementMutation {
  static final calls = <(String, String, bool)>[];
  static bool fail = false;

  @override
  Future<void> setEnabled({
    required String clinicId,
    required AdminFeatureDef feature,
    required bool enabled,
  }) async {
    calls.add((clinicId, feature.key, enabled));
    if (fail) throw Exception('falha simulada');
  }
}

Future<void> _pump(WidgetTester tester, Size size, String location) async {
  _FakeMutation.calls.clear();
  _FakeMutation.fail = false;
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  final router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (_, __, child) =>
            AppNavShell(destinations: _dest, child: child),
        routes: [
          GoRoute(
            path: '/platform',
            builder: (_, __) => const PlatformAdminHomePage(),
            routes: [
              GoRoute(
                  path: 'users',
                  builder: (_, __) => const UserManagementPage()),
              GoRoute(
                  path: 'clinics', builder: (_, __) => const ClinicsPage()),
              GoRoute(
                  path: 'patient-overview',
                  builder: (_, __) => const PatientOverviewPage()),
              GoRoute(
                  path: 'plans', builder: (_, __) => const AdminPlansPage()),
            ],
          ),
        ],
      ),
    ],
  );
  final theme = AppTheme.light;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authControllerProvider.overrideWith((ref) => _FakeAuth()),
      clinicUsersProvider.overrideWith(_FakeUsers.new),
      clinicsProvider.overrideWith(_FakeClinics.new),
      entitlementMutationProvider.overrideWith(_FakeMutation.new),
      clinicEntitlementsAdminProvider
          .overrideWith((ref, id) async => {'audit': id != 'c2'}),
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
  ));
  await _settle(tester, 15);
}

Future<void> _settle(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUpAll(() async {
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      final file = File('assets/fonts/$f');
      if (file.existsSync()) {
        await ui.loadFontFromList(file.readAsBytesSync(),
            fontFamily: 'Poppins');
      }
    }
  });

  const desk = Size(1366, 768);
  const phone = Size(390, 844);
  const tablet = Size(834, 1112);

  group('Clínicas', () {
    testWidgets('≥768: tabela com casca; celular sem ela', (tester) async {
      await _pump(tester, desk, '/platform/clinics');
      expect(find.text('Recolher menu'), findsOneWidget);
      expect(find.text('Cadastros institucionais'), findsOneWidget);
      expect(find.text('Tipo'), findsOneWidget);
      expect(find.text('Consultório Individual Modelo'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(tester, phone, '/platform/clinics');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Tipo'), findsNothing);
      expect(find.text('Cadastros institucionais'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"⋯" e painel de detalhe: Excluir cadastro', (tester) async {
      await _pump(tester, desk, '/platform/clinics');
      await tester.tap(find.byTooltip('Mais ações').first);
      await _settle(tester, 3);
      await tester.tap(find.text('Excluir cadastro'));
      await _settle(tester);
      // Clínica com vínculos: o app avisa que não dá para excluir.
      expect(find.text('Não é possível excluir'), findsOneWidget);
      await tester.tap(find.text('Entendi'));
      await _settle(tester);

      await tester.tap(find.text('Clínica Exemplo'));
      await _settle(tester);
      expect(find.text('Detalhe da clínica'), findsOneWidget);
      await tester.tap(find.text('Excluir cadastro'));
      await _settle(tester);
      expect(find.text('Não é possível excluir'), findsOneWidget);
    });

    testWidgets('switch pede a confirmação do app', (tester) async {
      await _pump(tester, desk, '/platform/clinics');
      await tester.tap(find.byType(AnimatedAlign).first);
      await _settle(tester);
      expect(find.text('Inativar Clínica'), findsOneWidget);
    });

    testWidgets('"Nova clínica" abre o formulário no painel', (tester) async {
      await _pump(tester, desk, '/platform/clinics');
      await tester.tap(find.text('Nova clínica'));
      await _settle(tester);
      expect(find.text('Criar clínica'), findsOneWidget);
      expect(find.text('Nome *'), findsOneWidget);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/clinics');
      expect(find.text('Clínica Exemplo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Pacientes (só leitura)', () {
    testWidgets('≥768: tabela sem clique; celular sem a casca',
        (tester) async {
      await _pump(tester, desk, '/platform/patient-overview');
      expect(find.text('Psicólogo'), findsOneWidget);
      expect(find.text('Convites pendentes'), findsOneWidget);
      expect(find.text('Dr. Paulo Modelo'), findsOneWidget);
      expect(find.text('Dr. Lucas Amostra'), findsNothing); // admin fora
      await tester.tap(find.text('Dr. Paulo Modelo'));
      await _settle(tester);
      expect(find.textContaining('Detalhe'), findsNothing);
      expect(tester.takeException(), isNull);

      await _pump(tester, phone, '/platform/patient-overview');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Distribuição de Pacientes'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/patient-overview');
      expect(find.text('Dr. Paulo Modelo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Planos', () {
    testWidgets('≥768: lista + módulos; troca de clínica muda o detalhe',
        (tester) async {
      await _pump(tester, desk, '/platform/plans');
      expect(find.text('Clínicas e consultórios'), findsOneWidget);
      expect(find.text('Liberação de módulos'), findsOneWidget);
      expect(find.text('Auditoria'), findsOneWidget);
      expect(find.text('Recursos e Biblioteca'), findsOneWidget);
      await tester.tap(find.text('Consultório Individual Modelo'));
      await _settle(tester, 6);
      // Cabeçalho do detalhe + item da lista.
      expect(find.text('Consultório Individual Modelo'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('switch de módulo grava na hora (como no app) com a chamada certa',
        (tester) async {
      await _pump(tester, desk, '/platform/plans');
      expect(_FakeMutation.calls, isEmpty);
      await tester.tap(find.byType(AnimatedAlign).first); // Pacientes, ligado
      await _settle(tester);
      expect(_FakeMutation.calls, [('c1', 'patients', false)]);
      // Ligar de novo grava o valor oposto.
      await tester.tap(find.byType(AnimatedAlign).first);
      await _settle(tester);
      expect(_FakeMutation.calls.last, ('c1', 'patients', true));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('falha ao gravar desfaz o switch e avisa', (tester) async {
      await _pump(tester, desk, '/platform/plans');
      _FakeMutation.fail = true;
      final before = tester
          .widget<AnimatedAlign>(find.byType(AnimatedAlign).first)
          .alignment;
      await tester.tap(find.byType(AnimatedAlign).first);
      await _settle(tester);
      expect(_FakeMutation.calls, hasLength(1));
      expect(
          tester.widget<AnimatedAlign>(find.byType(AnimatedAlign).first).alignment,
          before);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('celular mantém o acordeão (sem lista lateral)',
        (tester) async {
      await _pump(tester, phone, '/platform/plans');
      expect(find.text('Clínicas e consultórios'), findsNothing);
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Liberação de módulos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/plans');
      expect(find.text('Auditoria'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Hover das linhas', () {
    for (final (nome, rota, linha) in [
      ('Clínicas', '/platform/clinics', 'Clínica Exemplo'),
      ('Planos', '/platform/plans', 'Consultório Individual Modelo'),
    ]) {
      testWidgets('$nome: fade só no fundo, sem piscada', (tester) async {
        await _pump(tester, desk, rota);
        await expectSmoothRowHover(tester, find.text(linha));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
