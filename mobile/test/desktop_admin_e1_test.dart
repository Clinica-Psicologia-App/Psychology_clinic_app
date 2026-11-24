// Admin E1 (casca + Início + Usuários): layout ≥768 px vs celular e fluxos.
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
import 'package:terapia_esquema/features/platform_admin/presentation/platform_admin_home_page.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/user_management/domain/clinic_user.dart';
import 'package:terapia_esquema/features/user_management/presentation/user_management_page.dart';
import 'package:terapia_esquema/features/user_management/providers/user_management_providers.dart';
import 'package:terapia_esquema/shared/widgets/app_nav_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';

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


Future<void> _pump(WidgetTester tester, Size size, String location) async {
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
              GoRoute(path: 'clinics', builder: (_, __) => const Scaffold()),
              GoRoute(
                  path: 'patient-overview',
                  builder: (_, __) => const Scaffold()),
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

  group('Início', () {
    testWidgets('≥768 usa a casca de desktop', (tester) async {
      await _pump(tester, desk, '/platform');
      expect(find.text('Recolher menu'), findsOneWidget);
      expect(find.text('Atendimento'), findsOneWidget);
      expect(find.text('Estrutura da plataforma'), findsOneWidget);
      expect(find.text('Planos e permissões'), findsWidgets);
      expect(find.text('PLATAFORMA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('celular mantém a tela de hoje (sem casca)', (tester) async {
      await _pump(tester, phone, '/platform');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Administrador da plataforma'), findsOneWidget);
      expect(find.text('Atendimento'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet: trilho sem rótulo longo, sem overflow',
        (tester) async {
      await _pump(tester, tablet, '/platform');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Início'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('recolher menu esconde os rótulos e volta', (tester) async {
      await _pump(tester, desk, '/platform');
      await tester.tap(find.text('Recolher menu'));
      await _settle(tester);
      expect(desktopAdminMenuCollapsed.value, isTrue);
      expect(find.text('PLATAFORMA'), findsNothing);
      desktopAdminMenuCollapsed.value = false;
      await _settle(tester);
      expect(find.text('PLATAFORMA'), findsOneWidget);
    });
  });

  group('Usuários', () {
    testWidgets('≥768: tabela, busca e filtros; celular sem eles',
        (tester) async {
      await _pump(tester, desk, '/platform/users');
      expect(find.text('Nome'), findsOneWidget);
      expect(find.text('Buscar por nome ou e-mail'), findsOneWidget);
      expect(find.text('Dr. Paulo Modelo'), findsOneWidget);
      expect(find.text('Clínica Exemplo'), findsWidgets);
      expect(tester.takeException(), isNull);

      await _pump(tester, phone, '/platform/users');
      expect(find.text('Buscar por nome ou e-mail'), findsNothing);
      expect(find.text('Separação por vínculo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('busca filtra por nome e mostra "Nenhum resultado"',
        (tester) async {
      await _pump(tester, desk, '/platform/users');
      await tester.enterText(find.byType(TextField), 'paulo');
      await _settle(tester, 2);
      expect(find.text('Dr. Paulo Modelo'), findsOneWidget);
      expect(find.text('Dra. Beatriz Teste'), findsNothing);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await _settle(tester, 2);
      expect(find.text('Nenhum resultado'), findsOneWidget);
    });

    testWidgets('segmentado Admins mostra só administradores', (tester) async {
      await _pump(tester, desk, '/platform/users');
      await tester.tap(find.text('Admins'));
      await _settle(tester, 3);
      expect(find.text('Dr. Lucas Amostra'), findsOneWidget);
      expect(find.text('Dr. Paulo Modelo'), findsNothing);
    });

    testWidgets('menu "⋯" traz as ações do app', (tester) async {
      await _pump(tester, desk, '/platform/users');
      // 4º usuário da tabela = Dr. Paulo (psicólogo).
      await tester.tap(find.byTooltip('Mais ações').at(3));
      await _settle(tester, 3);
      expect(find.text('Inativar'), findsOneWidget);
      expect(find.text('Configurar acessos'), findsOneWidget);
      expect(find.text('Promover a administrador'), findsOneWidget);
      expect(find.text('Excluir'), findsOneWidget);
    });

    testWidgets('linha abre o painel de detalhe e fecha', (tester) async {
      await _pump(tester, desk, '/platform/users');
      await tester.tap(find.text('Dr. Paulo Modelo'));
      await _settle(tester);
      expect(find.text('Detalhe do usuário'), findsOneWidget);
      expect(find.text('Configurar acessos'), findsOneWidget);
      await tester.tap(find.byTooltip('Fechar'));
      await _settle(tester);
      expect(find.text('Detalhe do usuário'), findsNothing);
    });

    testWidgets('"Novo acesso" abre o formulário no painel lateral',
        (tester) async {
      await _pump(tester, desk, '/platform/users');
      await tester.tap(find.text('Novo acesso'));
      await _settle(tester);
      expect(find.text('Novo usuário'), findsOneWidget);
      expect(find.text('Criar usuário'), findsOneWidget);
      expect(find.text('Nome completo'), findsOneWidget);
    });

    testWidgets('switch pede a mesma confirmação do app', (tester) async {
      await _pump(tester, desk, '/platform/users');
      await tester.tap(find.byType(AnimatedAlign).first);
      await _settle(tester);
      expect(find.text('Inativar usuário'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('ação pelo menu "⋯" e pelo painel abrem a mesma confirmação',
        (tester) async {
      await _pump(tester, desk, '/platform/users');
      // Pelo menu: Dr. Paulo (4º da tabela) é psicólogo ativo.
      await tester.tap(find.byTooltip('Mais ações').at(3));
      await _settle(tester, 3);
      await tester.tap(find.text('Inativar'));
      await _settle(tester);
      expect(find.text('Inativar usuário'), findsOneWidget);
      expect(find.textContaining('Dr. Paulo Modelo?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(find.text('Inativar usuário'), findsNothing);

      // Pelo painel de detalhe: mesmo diálogo.
      await tester.tap(find.text('Dr. Paulo Modelo'));
      await _settle(tester);
      await tester.tap(find.text('Inativar'));
      await _settle(tester);
      expect(find.text('Inativar usuário'), findsOneWidget);
      expect(find.textContaining('Dr. Paulo Modelo?'), findsOneWidget);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/users');
      expect(find.text('Dr. Paulo Modelo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
