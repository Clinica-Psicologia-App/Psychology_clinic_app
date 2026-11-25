// Admin E1 (casca + Início + Usuários): layout ≥768 px vs celular e fluxos.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  _FakeUsers([this.list]);
  final List<ClinicUser>? list;
  @override
  Future<List<ClinicUser>> build() async => list ?? _users;
}

ClinicUser _p(
  String id,
  String clinicId,
  String clinicName,
  String name, {
  ProfileRole role = ProfileRole.psychologist,
  bool active = true,
  bool clinicActive = true,
  bool receives = true,
  int assigned = 0,
  int pending = 0,
  int? limit,
}) =>
    ClinicUser(
      id: id,
      clinicId: clinicId,
      clinicName: clinicName,
      clinicType: clinicId.startsWith('p') ? 'personal' : 'clinic',
      clinicIsActive: clinicActive,
      fullName: name,
      email: '$id@example.com',
      role: role,
      isActive: active,
      canReceivePatients: receives,
      patientAssignmentLimit: limit,
      assignedPatientsCount: assigned,
      pendingPatientInvitationsCount: pending,
    );

/// Duas clínicas (uma inativa) e dois consultórios (um inativo).
final _sections = [
  _p('adm', 'c1', 'Clínica Exemplo', 'Dra. Admin Fictícia',
      role: ProfileRole.platformAdmin),
  _p('lim', 'c1', 'Clínica Exemplo', 'Dr. Com Limite',
      assigned: 1, limit: 5),
  _p('off', 'c1', 'Clínica Exemplo', 'Dr. Desligado', active: false),
  _p('blq', 'c3', 'Clínica Modelo Inativa', 'Dra. Bloqueada',
      clinicActive: false, receives: false),
  _p('s1', 'p1', 'Consultório Fictício Um', 'Dra. Solo Um',
      assigned: 2, pending: 1),
  _p('s2', 'p2', 'Consultório Fictício Dois', 'Dr. Solo Dois',
      active: false, clinicActive: false, limit: 2),
];

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

late GoRouter _router;

Future<void> _pump(WidgetTester tester, Size size, String location,
    {List<ClinicUser>? users}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  final router = _router = GoRouter(
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
      clinicUsersProvider.overrideWith(() => _FakeUsers(users)),
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

  group('Troca de tela', () {
    double minOpacityAbove(WidgetTester tester, Finder f) {
      var o = 1.0;
      for (final e in find
          .ancestor(of: f, matching: find.byType(FadeTransition))
          .evaluate()) {
        final v = (e.widget as FadeTransition).opacity.value;
        if (v < o) o = v;
      }
      return o;
    }

    testWidgets('≥768: menu, barra e fio ficam parados na troca de rota',
        (tester) async {
      await _pump(tester, desk, '/platform');
      final menuPos = tester.getTopLeft(find.text('PLATAFORMA'));
      final recolherPos = tester.getTopLeft(find.text('Recolher menu'));
      await tester.tap(find.text('Usuários').first); // item do menu
      // Em pleno meio da transição (a tela antiga ainda existe por baixo):
      // todos os menus no mesmo lugar, opacos e sem slide.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      for (final (f, expected) in [
        (find.text('PLATAFORMA'), menuPos),
        (find.text('Recolher menu'), recolherPos),
      ]) {
        for (final e in f.evaluate()) {
          final box = e.renderObject! as RenderBox;
          expect(box.localToGlobal(Offset.zero), expected);
        }
        expect(minOpacityAbove(tester, f), 1.0);
        for (final e in find
            .ancestor(of: f, matching: find.byType(SlideTransition))
            .evaluate()) {
          expect((e.widget as SlideTransition).position.value, Offset.zero);
        }
      }
      await _settle(tester, 8);
      expect(find.text('Separação por vínculo'), findsOneWidget);
      expect(tester.getTopLeft(find.text('PLATAFORMA')), menuPos);
    });

    // Entrada do conteúdo da tela cujo corpo contém [f].
    Finder entranceOf(Finder f) =>
        find.ancestor(of: f, matching: find.byKey(daContentEntranceKey));
    double opacityOf(WidgetTester tester, Finder f) =>
        tester.widget<FadeTransition>(entranceOf(f)).opacity.value;
    double riseOf(WidgetTester tester, Finder f) => tester
        .widget<Transform>(find
            .descendant(of: entranceOf(f), matching: find.byType(Transform))
            .first)
        .transform
        .getTranslation()
        .y;

    testWidgets('≥768: só o conteúdo entra com fade + subida; barra parada',
        (tester) async {
      final users = find.text('Separação por vínculo');
      for (final size in [desk, tablet]) {
        await tester.pumpWidget(const SizedBox());
        await _pump(tester, size, '/platform');
        await tester.tap(find.text('Usuários').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        expect(opacityOf(tester, users), inExclusiveRange(0.0, 1.0));
        expect(riseOf(tester, users),
            inExclusiveRange(0.0, kDaContentEntranceRise));
        final midContent = tester.getTopLeft(users);
        // Botão da barra superior da tela nova: fora da animação.
        final action = find.text('Novo acesso');
        expect(entranceOf(action), findsNothing);
        final midAction = tester.getTopLeft(action);

        await _settle(tester, 8);
        expect(opacityOf(tester, users), 1.0);
        expect(riseOf(tester, users), 0.0);
        expect(tester.getTopLeft(action), midAction);
        final end = tester.getTopLeft(users);
        expect(midContent.dx, end.dx);
        expect(midContent.dy, greaterThan(end.dy));
        expect(midContent.dy - end.dy, lessThan(kDaContentEntranceRise));
      }
    });

    testWidgets('≥768: dura 220 ms', (tester) async {
      final users = find.text('Separação por vínculo');
      await _pump(tester, desk, '/platform');
      await tester.tap(find.text('Usuários').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacityOf(tester, users), lessThan(1.0));
      await tester.pump(const Duration(milliseconds: 30));
      expect(opacityOf(tester, users), 1.0);
      await _settle(tester, 8);
    });

    testWidgets('≥768: voltar ao Início também entra suave, sem esperar',
        (tester) async {
      final home = find.text('Estrutura da plataforma');
      await _pump(tester, desk, '/platform');
      final menuPos = tester.getTopLeft(find.text('PLATAFORMA'));
      await tester.tap(find.text('Usuários').first);
      await _settle(tester, 8);
      await tester.tap(find.text('Início').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(opacityOf(tester, home), inExclusiveRange(0.0, 1.0));
      expect(riseOf(tester, home),
          inExclusiveRange(0.0, kDaContentEntranceRise));
      // A tela que sai não fica por cima.
      final leaving = find.ancestor(
          of: find.text('Separação por vínculo'),
          matching: find.byType(Opacity));
      expect(
          leaving.evaluate().map((e) => (e.widget as Opacity).opacity),
          contains(0.0));
      for (final e in find.text('PLATAFORMA').evaluate()) {
        final box = e.renderObject! as RenderBox;
        expect(box.localToGlobal(Offset.zero), menuPos);
      }
      await _settle(tester, 8);
      expect(opacityOf(tester, home), 1.0);
      expect(find.text('Separação por vínculo'), findsNothing);
    });

    IgnorePointer guardOf(WidgetTester tester, Finder f) =>
        tester.widget<IgnorePointer>(
            find.ancestor(of: f, matching: find.byKey(daLeavingGuardKey)));
    String location() =>
        _router.routerDelegate.currentConfiguration.last.matchedLocation;

    for (final (nome, voltar) in <(String, Future<void> Function(WidgetTester))>[
      (
        'Navigator.maybePop',
        (tester) async {
          await Navigator.of(
                  tester.element(find.text('Separação por vínculo')))
              .maybePop();
        }
      ),
      (
        'botão voltar do sistema',
        (tester) async {
          await tester.binding.handlePopRoute();
        }
      ),
    ]) {
      testWidgets('≥768: $nome entra suave e trava a tela que sai',
          (tester) async {
        final home = find.text('Estrutura da plataforma');
        final users = find.text('Separação por vínculo');
        await _pump(tester, desk, '/platform');
        await tester.tap(find.text('Usuários').first);
        await _settle(tester, 8);
        expect(guardOf(tester, users).ignoring, isFalse);
        await voltar(tester);
        await tester.pump();
        // Já no primeiro quadro: invisível e sem toque.
        expect(guardOf(tester, users).ignoring, isTrue);
        expect(guardOf(tester, home).ignoring, isFalse);
        // O 1º tique marca o início da animação; o 2º já anda.
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 60));
        expect(opacityOf(tester, home), inExclusiveRange(0.0, 1.0));
        await _settle(tester, 8);
        expect(users, findsNothing);
        expect(opacityOf(tester, home), 1.0);
        expect(guardOf(tester, home).ignoring, isFalse);
        expect(location(), '/platform');
      });
    }

    testWidgets('≥768: toque durante a saída vai para a tela revelada',
        (tester) async {
      final users = find.text('Separação por vínculo');
      for (final espera in [Duration.zero, const Duration(milliseconds: 60)]) {
        await tester.pumpWidget(const SizedBox());
        await _pump(tester, desk, '/platform');
        await tester.tap(find.text('Usuários').first);
        await _settle(tester, 8);
        final novoAcesso = tester.getCenter(find.text('Novo acesso'));
        await Navigator.of(tester.element(users)).maybePop();
        await tester.pump();
        await tester.pump(espera);
        expect(users, findsOneWidget); // a tela que sai ainda existe
        // Onde estava o botão da tela invisível: nada abre.
        await tester.tapAt(novoAcesso);
        await tester.pump();
        expect(find.text('Criar usuário'), findsNothing);
        // Atalho do Início revelado: recebe o toque.
        await tester.tap(find.text('Visualizar, inativar e reativar pacientes.'));
        await tester.pump();
        expect(location(), '/platform/patient-overview');
        await _settle(tester, 8);
        expect(find.text('Criar usuário'), findsNothing);
      }
    });

    testWidgets('≥768: abrir e fechar diálogo não mexe na tela',
        (tester) async {
      final users = find.text('Separação por vínculo');
      await _pump(tester, desk, '/platform/users');

      Future<void> parada() async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 60));
          expect(opacityOf(tester, users), 1.0);
          expect(riseOf(tester, users), 0.0);
          expect(guardOf(tester, users).ignoring, isFalse);
        }
      }

      // Confirmação fechada em "Cancelar".
      await tester.tap(find.byType(AnimatedAlign).first);
      await parada();
      expect(find.text('Inativar usuário'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await parada();
      expect(find.text('Inativar usuário'), findsNothing);

      // Painel lateral fechado pelo voltar do sistema: só ele fecha.
      await tester.tap(find.text('Dr. Paulo Modelo'));
      await parada();
      expect(find.text('Detalhe do usuário'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await parada();
      expect(find.text('Detalhe do usuário'), findsNothing);
      expect(location(), '/platform/users');

      // A tela continua recebendo toque.
      await tester.tap(find.text('Novo acesso'));
      await parada();
      expect(find.text('Criar usuário'), findsOneWidget);
    });

    testWidgets('≥768 com disableAnimations: troca sem animação',
        (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final users = find.text('Separação por vínculo');
      final home = find.text('Estrutura da plataforma');
      await _pump(tester, desk, '/platform');
      await tester.tap(find.text('Usuários').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(opacityOf(tester, users), 1.0);
      expect(riseOf(tester, users), 0.0);
      await _settle(tester, 8);
      await tester.tap(find.text('Início').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(opacityOf(tester, home), 1.0);
      expect(riseOf(tester, home), 0.0);
      await _settle(tester, 8);
    });

    testWidgets('celular não tem a entrada de conteúdo do desktop',
        (tester) async {
      await _pump(tester, phone, '/platform');
      await tester.tap(find.text('Usuários').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byKey(daContentEntranceKey), findsNothing);
      await _settle(tester, 10);
    });

    testWidgets('celular: a transição de página de hoje continua',
        (tester) async {
      await _pump(tester, phone, '/platform');
      await tester.tap(find.text('Usuários').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      // A nova tela ainda está entrando (fade < 1).
      expect(minOpacityAbove(tester, find.text('Separação por vínculo')),
          lessThan(1.0));
      await _settle(tester, 10);
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

  group('Hover das linhas', () {
    testWidgets('Usuários: fade só no fundo, sem piscada', (tester) async {
      await _pump(tester, desk, '/platform/users');
      await expectSmoothRowHover(tester, find.text('Dr. Paulo Modelo'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Usuários no tablet: mesmo comportamento', (tester) async {
      await _pump(tester, tablet, '/platform/users');
      await expectSmoothRowHover(tester, find.text('Dr. Paulo Modelo'));
    });

    testWidgets('botão "⋯" dentro da linha: sem piscada', (tester) async {
      await _pump(tester, desk, '/platform/users');
      await expectSmoothRowHover(tester, find.byIcon(Icons.more_horiz).at(3));
    });

    for (final (nome, size) in [('menu lateral', desk), ('trilho', tablet)]) {
      testWidgets('item do $nome: sem piscada', (tester) async {
        await _pump(tester, size, '/platform/users');
        await expectSmoothRowHover(tester, find.text('Clínicas').first);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('trilha da barra superior: sem piscada', (tester) async {
      await _pump(tester, desk, '/platform/users');
      final crumb = find.text('Início').last;
      expect(tester.getTopLeft(crumb).dx, greaterThan(256)); // fora do menu
      await expectSmoothRowHover(tester, crumb);
    });

    testWidgets('"Recolher menu": sem piscada', (tester) async {
      await _pump(tester, desk, '/platform/users');
      await expectSmoothRowHover(tester, find.text('Recolher menu'));
      expect(desktopAdminMenuCollapsed.value, isFalse);
    });

    testWidgets('menu com disableAnimations: instantâneo', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await _pump(tester, desk, '/platform/users');
      await expectSmoothRowHover(tester, find.text('Clínicas').first,
          reduced: true);
    });

    testWidgets('com disableAnimations o realce é instantâneo', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await _pump(tester, desk, '/platform/users');
      await expectSmoothRowHover(tester, find.text('Dr. Paulo Modelo'),
          reduced: true);
    });
  });

  group('Usuários em duas seções', () {
    const rota = '/platform/users';
    Future<void> abrir(WidgetTester tester, [Size size = desk]) =>
        _pump(tester, size, rota, users: _sections);

    /// [a] e [b] estão na mesma linha da tabela.
    void mesmaLinha(WidgetTester tester, Finder a, Finder b) => expect(
        (tester.getCenter(a).dy - tester.getCenter(b).dy).abs(), lessThan(20));

    double dy(WidgetTester tester, String text) =>
        tester.getTopLeft(find.text(text)).dy;

    double giro(WidgetTester tester, String clinica) => tester
        .widget<AnimatedRotation>(find.descendant(
            of: find
                .ancestor(of: find.text(clinica), matching: find.byType(Row))
                .first,
            matching: find.byType(AnimatedRotation)))
        .turns;

    testWidgets('seções com contagens e cabeçalho de clínica', (tester) async {
      await abrir(tester);
      expect(dy(tester, 'Clínicas (2)'),
          lessThan(dy(tester, 'Consultórios individuais (2)')));
      expect(find.text('2/3 ativos'), findsOneWidget);
      expect(find.text('1/1 ativos'), findsOneWidget);
      // Selo só na clínica inativa; nada de "Ativa", "grupo(s)" ou Status.
      mesmaLinha(tester, find.text('Inativa'),
          find.text('Clínica Modelo Inativa'));
      expect(find.text('Inativa'), findsOneWidget);
      expect(find.text('Ativa'), findsNothing);
      expect(find.textContaining('grupo(s)'), findsNothing);
      expect(find.text('Status'), findsNothing);
      expect(find.text('Limite'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('texto sob "Separação por vínculo": novo só no desktop',
        (tester) async {
      const novo = 'Clínicas aparecem em blocos com seus profissionais; '
          'consultórios individuais, um por linha.';
      await abrir(tester);
      expect(find.text('Separação por vínculo'), findsOneWidget);
      expect(find.text(novo), findsOneWidget);
      expect(find.textContaining('Cada bloco representa'), findsNothing);
      expect(find.textContaining('limite atingido'), findsNothing);

      await abrir(tester, phone);
      expect(find.text(novo), findsNothing);
      expect(find.textContaining('Cada bloco representa'), findsOneWidget);
    });

    testWidgets('consultório individual não tem cabeçalho nem repete o nome',
        (tester) async {
      await abrir(tester);
      expect(find.text('Consultório Fictício Um'), findsNothing);
      expect(find.text('Consultório Fictício Dois'), findsNothing);
      expect(find.text('Dra. Solo Um'), findsOneWidget);
      expect(find.text('Dr. Solo Dois'), findsOneWidget);
      expect(find.text('1/1 ativos'), findsOneWidget); // só a clínica c3
      // Consultório inativo: marcado na própria linha, e só nela.
      expect(find.text('Consultório inativo'), findsOneWidget);
      mesmaLinha(tester, find.text('Consultório inativo'),
          find.text('Dr. Solo Dois'));
    });

    testWidgets('coluna Pacientes junta uso e limite', (tester) async {
      await abrir(tester);
      final coluna = tester.getTopLeft(find.text('Pacientes').last).dx;
      for (final (nome, texto) in [
        ('Dr. Com Limite', '1 de 5'),
        ('Dr. Desligado', '0 · sem limite'),
        ('Dra. Solo Um', '3 · sem limite'),
        ('Dra. Bloqueada', '0 · novos bloqueados'),
        ('Dra. Admin Fictícia', '—'),
      ]) {
        expect(find.text(texto), findsOneWidget);
        mesmaLinha(tester, find.text(texto), find.text(nome));
        expect(tester.getTopLeft(find.text(texto)).dx, coluna);
      }
    });

    testWidgets('"Inativo" aparece ao lado do switch desligado',
        (tester) async {
      await abrir(tester);
      final inativo = find.text('Inativo');
      expect(inativo, findsNWidgets(2));
      mesmaLinha(tester, inativo.first, find.text('Dr. Desligado'));
      mesmaLinha(tester, inativo.last, find.text('Dr. Solo Dois'));
      expect(find.text('Ativo'), findsOneWidget); // só o título da coluna
    });

    testWidgets('bloco abre e fecha com animação de 140 a 200 ms',
        (tester) async {
      await abrir(tester);
      const prox = 'Clínica Modelo Inativa';
      final aberto = dy(tester, prox);
      expect(giro(tester, 'Clínica Exemplo'), 0);

      await tester.tap(find.text('Clínica Exemplo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final meio = dy(tester, prox);
      expect(meio, lessThan(aberto));
      await tester.pump(const Duration(milliseconds: 60)); // 140 ms
      expect(find.text('Dr. Com Limite'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 60)); // 200 ms
      final fechado = dy(tester, prox);
      expect(fechado, lessThan(meio));
      expect(find.text('Dr. Com Limite'), findsNothing);
      expect(giro(tester, 'Clínica Exemplo'), -0.25);
      // Só o bloco clicado fecha.
      expect(find.text('Dra. Bloqueada'), findsOneWidget);
      expect(find.text('Dra. Solo Um'), findsOneWidget);
      expect(find.text('2/3 ativos'), findsOneWidget);

      // O filtro não reabre o bloco.
      await tester.tap(find.text('Admins'));
      await _settle(tester, 3);
      expect(find.text('Clínica Exemplo'), findsOneWidget);
      expect(find.text('Dra. Admin Fictícia'), findsNothing);
      await tester.tap(find.text('Todos'));
      await _settle(tester, 3);

      await tester.tap(find.text('Clínica Exemplo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(dy(tester, prox), inExclusiveRange(fechado, aberto));
      await _settle(tester, 3);
      expect(dy(tester, prox), aberto);
      expect(find.text('Dr. Com Limite'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('com disableAnimations abre e fecha na hora', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await abrir(tester);
      final aberto = dy(tester, 'Clínica Modelo Inativa');
      await tester.tap(find.text('Clínica Exemplo'));
      await tester.pump();
      expect(find.text('Dr. Com Limite'), findsNothing);
      expect(dy(tester, 'Clínica Modelo Inativa'), lessThan(aberto));
      await tester.tap(find.text('Clínica Exemplo'));
      await tester.pump();
      expect(find.text('Dr. Com Limite'), findsOneWidget);
      expect(dy(tester, 'Clínica Modelo Inativa'), aberto);
    });

    testWidgets('filtro e busca valem nas duas seções', (tester) async {
      await abrir(tester);
      await tester.tap(find.text('Psicólogos'));
      await _settle(tester, 3);
      expect(find.text('Dra. Admin Fictícia'), findsNothing);
      expect(find.text('Clínicas (2)'), findsOneWidget);
      expect(find.text('Consultórios individuais (2)'), findsOneWidget);

      await tester.tap(find.text('Admins'));
      await _settle(tester, 3);
      expect(find.text('Clínicas (1)'), findsOneWidget);
      expect(find.textContaining('Consultórios individuais'), findsNothing);
      expect(find.text('Clínica Modelo Inativa'), findsNothing);
      // O "X/Y ativos" continua sendo o da clínica inteira.
      expect(find.text('2/3 ativos'), findsOneWidget);

      await tester.tap(find.text('Todos'));
      await tester.enterText(find.byType(TextField), 'solo');
      await _settle(tester, 3);
      expect(find.textContaining('Clínicas ('), findsNothing);
      expect(find.text('Consultórios individuais (2)'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'limite');
      await _settle(tester, 3);
      expect(find.text('Clínicas (1)'), findsOneWidget);
      expect(find.textContaining('Consultórios individuais'), findsNothing);
      expect(find.text('Dr. Com Limite'), findsOneWidget);
      expect(find.text('Dr. Desligado'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await _settle(tester, 3);
      expect(find.text('Nenhum resultado'), findsOneWidget);
      expect(find.textContaining('Clínicas ('), findsNothing);
    });

    testWidgets('linha individual mantém switch, "⋯" e detalhe',
        (tester) async {
      await abrir(tester);
      // Última linha da tabela: um consultório individual (Solo Um).
      await tester.tap(find.byTooltip('Mais ações').last);
      await _settle(tester, 3);
      expect(find.text('Configurar acessos'), findsOneWidget);
      expect(find.text('Promover a administrador'), findsOneWidget);
      await tester.tapAt(const Offset(5, 5));
      await _settle(tester, 3);

      await tester.tap(find.byType(AnimatedAlign).last);
      await _settle(tester);
      expect(find.text('Inativar usuário'), findsOneWidget);
      expect(find.textContaining('Dra. Solo Um?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);

      await tester.tap(find.text('Dra. Solo Um'));
      await _settle(tester);
      expect(find.text('Detalhe do usuário'), findsOneWidget);
      expect(find.text('Consultório Fictício Um'), findsOneWidget);
    });

    testWidgets('hover sem piscada no cabeçalho e na linha individual',
        (tester) async {
      await abrir(tester);
      await expectSmoothRowHover(
          tester, find.text('Clínica Modelo Inativa'));
      await expectSmoothRowHover(tester, find.text('Dra. Solo Um'));
    });

    testWidgets('768, 834, 1366 e 1920 sem overflow', (tester) async {
      for (final size in const [
        Size(768, 1024),
        Size(834, 1112),
        Size(1366, 768),
        Size(1920, 1080),
      ]) {
        await tester.pumpWidget(const SizedBox());
        await abrir(tester, size);
        expect(find.text('Consultório inativo'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '${size.width}');
      }
    });

    testWidgets('celular continua sem as seções', (tester) async {
      await abrir(tester, phone);
      expect(find.text('Clínicas (2)'), findsNothing);
      expect(find.textContaining('Consultórios individuais ('), findsNothing);
      expect(find.text('Separação por vínculo'), findsOneWidget);
    });
  });
}
