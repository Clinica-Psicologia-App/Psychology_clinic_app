// Menu lateral do admin desktop (marinho, Gestão e Conteúdo).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/core/theme/app_branding_assets.dart';
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
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_menu.dart';
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

ClinicUser _u(String id, ProfileRole role, bool active, int assigned) =>
    ClinicUser(
      id: id,
      clinicId: 'c1',
      clinicName: 'Clínica Exemplo',
      clinicType: 'clinic',
      clinicIsActive: true,
      fullName: 'Pessoa Fictícia $id',
      email: 'u$id@example.com',
      role: role,
      isActive: active,
      assignedPatientsCount: assigned,
    );

/// 5 usuários (4 ativos) e 7 pacientes atribuídos a psicólogos.
final _users = [
  _u('1', ProfileRole.platformAdmin, true, 0),
  _u('2', ProfileRole.psychologist, true, 3),
  _u('3', ProfileRole.psychologist, true, 4),
  _u('4', ProfileRole.psychologist, false, 0),
  _u('5', ProfileRole.psychologist, true, 0),
];

int _userLoads = 0;
int _clinicLoads = 0;

class _FakeUsers extends ClinicUsersNotifier {
  @override
  Future<List<ClinicUser>> build() async {
    _userLoads++;
    return _users;
  }
}

class _FakeClinics extends ClinicsNotifier {
  @override
  Future<List<ClinicSummary>> build() async {
    _clinicLoads++;
    return [
      for (var i = 1; i <= 3; i++)
        ClinicSummary(
            id: 'c$i',
            name: 'Clínica Fictícia $i',
            clinicType: 'clinic',
            isActive: i != 3,
            createdAt: DateTime(2026, 1, 1),
            userCount: 1,
            patientCount: 1),
    ];
  }
}

late GoRouter _router;

/// Telas que o menu abre e que não interessam aqui: só a casca.
Widget _stub(DesktopAdminNav nav, String title) => Builder(
      builder: (context) => MediaQuery.sizeOf(context).width < 768
          ? const Scaffold()
          : DesktopAdminShell(
              nav: nav, title: title, body: const SizedBox.expand()),
    );

Future<void> _pump(WidgetTester tester, Size size, String location,
    {bool dark = false}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  addTearDown(() => desktopAdminMenuCollapsed.value = false);
  _userLoads = 0;
  _clinicLoads = 0;
  GoRoute stub(String path, DesktopAdminNav nav) =>
      GoRoute(path: path, builder: (_, __) => _stub(nav, 'Tela $path'));
  _router = GoRouter(
    initialLocation: location,
    routes: [
      ShellRoute(
        builder: (_, __, child) =>
            AppNavShell(destinations: const [], child: child),
        routes: [
          GoRoute(
            path: '/platform',
            builder: (_, __) => const PlatformAdminHomePage(),
            routes: [
              GoRoute(
                  path: 'users',
                  builder: (_, __) => const UserManagementPage()),
              stub('clinics', DesktopAdminNav.clinics),
              stub('patient-overview', DesktopAdminNav.patients),
              stub('plans', DesktopAdminNav.home),
              stub('questionnaires', DesktopAdminNav.home),
              stub('questionnaire-catalog', DesktopAdminNav.home),
              stub('library', DesktopAdminNav.home),
              stub('psychoeducation', DesktopAdminNav.home),
            ],
          ),
        ],
      ),
    ],
  );
  final theme = dark ? AppTheme.dark : AppTheme.light;
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      authControllerProvider.overrideWith((ref) => _FakeAuth()),
      clinicUsersProvider.overrideWith(_FakeUsers.new),
      clinicsProvider.overrideWith(_FakeClinics.new),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
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

final _menu = find.byType(DesktopAdminMenu);

Finder _inMenu(Finder f) => find.descendant(of: _menu, matching: f);
Finder _label(String text) => _inMenu(find.text(text));
Finder _asset(String name) => _inMenu(find.byWidgetPredicate((w) =>
    w is Image &&
    w.image is AssetImage &&
    (w.image as AssetImage).assetName == name));

bool? _selected(WidgetTester tester, String label) => tester
    .widget<Semantics>(find
        .ancestor(of: _label(label), matching: find.byType(Semantics))
        .first)
    .properties
    .selected;

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

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
  const wide = Size(1920, 1080);
  const tablet = Size(834, 1112);
  const phone = Size(390, 844);
  const navyBases = [Color(0xFF0D1B3D), Color(0xFF0A1530)];

  testWidgets('grupos, contadores, rodapé e versão em 1366 e 1920',
      (tester) async {
    for (final size in [desk, wide]) {
      await _pump(tester, size, '/platform/clinics');
      expect(_menu, findsOneWidget);
      expect(_label('GESTÃO'), findsOneWidget);
      expect(_label('CONTEÚDO'), findsOneWidget);
      for (final label in ['Questionários', 'Biblioteca', 'Psicoeducação']) {
        expect(_label(label), findsOneWidget);
      }
      for (final (label, count) in [
        ('Clínicas', '3'),
        ('Usuários', '5'),
        ('Pacientes', '7'),
      ]) {
        expect(
            (tester.getCenter(_label(count)).dy -
                    tester.getCenter(_label(label)).dy)
                .abs(),
            lessThan(8),
            reason: '$label $count');
        final item = find
            .ancestor(
                of: _label(label), matching: find.byType(AnimatedContainer))
            .first;
        expect(tester.getSize(item).height, greaterThanOrEqualTo(44));
      }
      expect(_label('Novo acesso'), findsOneWidget);
      expect(_inMenu(find.textContaining('Versão')), findsOneWidget);
      expect(_label('Administrador da plataforma'), findsOneWidget);
      expect(_selected(tester, 'Clínicas'), isTrue);
      expect(_selected(tester, 'Início'), isFalse);
      // Nada do menu anterior nem da variação descartada.
      expect(_label('PLATAFORMA'), findsNothing);
      expect(_inMenu(find.textContaining('ativ')), findsNothing);
      expect(tester.takeException(), isNull, reason: '${size.width}');
    }
  });

  testWidgets('marca: ícone grande e nome, sem logo horizontal nem mascote',
      (tester) async {
    await _pump(tester, desk, '/platform');
    final icon = _asset(AppBrandingAssets.icon);
    expect(icon, findsOneWidget);
    expect(tester.getSize(icon).width, greaterThan(48));
    expect(_inMenu(find.textContaining('EsquemaCore')), findsOneWidget);
    expect(_label('raciocínio clínico em mapa'), findsOneWidget);
    expect(_asset(AppBrandingAssets.logoHorizontal), findsNothing);
    expect(
        _inMenu(find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName.contains('mascote'))),
        findsNothing);
  });

  testWidgets('contadores sem consulta nova', (tester) async {
    await _pump(tester, desk, '/platform/library');
    expect((_userLoads, _clinicLoads), (1, 1));
    await tester.tap(_label('Usuários'));
    await _settle(tester, 8);
    await tester.tap(_label('Clínicas'));
    await _settle(tester, 8);
    expect((_userLoads, _clinicLoads), (1, 1));
  });

  testWidgets('navega pelos itens de gestão', (tester) async {
    await _pump(tester, desk, '/platform');
    for (final (label, rota) in [
      ('Clínicas', '/platform/clinics'),
      ('Pacientes', '/platform/patient-overview'),
      ('Usuários', '/platform/users'),
      ('Início', '/platform'),
    ]) {
      await tester.tap(_label(label));
      await _settle(tester, 8);
      expect(_location(), rota);
      expect(_selected(tester, label), isTrue);
    }
  });

  testWidgets('itens de conteúdo marcam a tela aberta', (tester) async {
    await _pump(tester, desk, '/platform');
    for (final (label, rota) in [
      ('Biblioteca', '/platform/library'),
      ('Psicoeducação', '/platform/psychoeducation'),
      ('Questionários', '/platform/questionnaire-catalog'),
    ]) {
      await tester.tap(_label(label));
      await _settle(tester, 8);
      expect(_location(), rota);
      expect(_selected(tester, label), isTrue);
      expect(_selected(tester, 'Início'), isFalse);
    }
    // A aba Permissões faz parte de Questionários e volta ao catálogo.
    _router.go('/platform/questionnaires');
    await _settle(tester, 8);
    expect(_selected(tester, 'Questionários'), isTrue);
    await tester.tap(_label('Questionários'));
    await _settle(tester, 8);
    expect(_location(), '/platform/questionnaire-catalog');
    // Tela sem item próprio: Início marcado, e o clique volta a ele.
    _router.go('/platform/plans');
    await _settle(tester, 8);
    expect(_selected(tester, 'Início'), isTrue);
    await tester.tap(_label('Início'));
    await _settle(tester, 8);
    expect(_location(), '/platform');
  });

  testWidgets('"Novo acesso" do menu abre o mesmo formulário',
      (tester) async {
    await _pump(tester, desk, '/platform/clinics');
    await tester.tap(_label('Novo acesso'));
    await _settle(tester);
    expect(find.text('Novo usuário'), findsOneWidget);
    expect(find.text('Criar usuário'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text('Criar usuário'), findsNothing);
    expect(_location(), '/platform/clinics');
  });

  testWidgets('recolhe, expande e vira trilho', (tester) async {
    await _pump(tester, desk, '/platform/users');
    expect(tester.getSize(_menu).width, 232);
    await tester.tap(_label('Recolher menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(_menu).width, inExclusiveRange(64.0, 232.0));
    await _settle(tester);
    expect(tester.getSize(_menu).width, 64);
    expect(_label('Clínicas'), findsNothing);
    expect(_label('GESTÃO'), findsNothing);
    expect(_inMenu(find.textContaining('Versão')), findsNothing);
    expect(_inMenu(find.byTooltip('Clínicas · 3')), findsOneWidget);
    expect(_inMenu(find.byTooltip('Biblioteca')), findsOneWidget);
    expect(_inMenu(find.byTooltip('Novo acesso')), findsOneWidget);
    expect(tester.takeException(), isNull);
    // Recolhido continua recolhido ao trocar de tela, e navega.
    await tester.tap(_inMenu(find.byTooltip('Biblioteca')));
    await _settle(tester, 8);
    expect(_location(), '/platform/library');
    expect(tester.getSize(_menu).width, 64);
    await tester.tap(_inMenu(find.byTooltip('Expandir menu')));
    await _settle(tester);
    expect(tester.getSize(_menu).width, 232);
  });

  testWidgets('disableAnimations recolhe na hora', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester, desk, '/platform/users');
    await tester.tap(_label('Recolher menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getSize(_menu).width, 64);
  });

  testWidgets('tablet (trilho) e janela baixa sem overflow', (tester) async {
    for (final size in const [tablet, Size(768, 1024), Size(1366, 560)]) {
      await _pump(tester, size, '/platform/users');
      expect(_label('Clínicas'), findsOneWidget);
      expect(_label('Psicoeducação'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      if (size.width < 1024) {
        expect(tester.getSize(_menu).width, 76);
        expect(_label('Recolher menu'), findsNothing);
        expect(_label('GESTÃO'), findsNothing);
        expect(_inMenu(find.textContaining('Versão')), findsNothing);
        expect(_inMenu(find.byTooltip('Novo acesso')), findsOneWidget);
        await tester.tap(_label('Biblioteca'));
        await _settle(tester, 8);
        expect(_location(), '/platform/library');
      }
    }
  });

  testWidgets('tema escuro: mesmo menu marinho, sem overflow',
      (tester) async {
    for (final size in [desk, tablet]) {
      await _pump(tester, size, '/platform/users', dark: true);
      expect(_label('Clínicas'), findsOneWidget);
      final box = tester.widget<AnimatedContainer>(find
          .descendant(of: _menu, matching: find.byType(AnimatedContainer))
          .first);
      expect(
          ((box.decoration! as BoxDecoration).gradient! as LinearGradient)
              .colors
              .first,
          const Color(0xFF0D1B3D));
      expect(tester.takeException(), isNull);
      await expectSmoothRowHover(tester, _label('Clínicas'),
          bases: navyBases);
    }
  });

  testWidgets('hover sem piscada: item, trilho, recolher e Novo acesso',
      (tester) async {
    await _pump(tester, desk, '/platform/users');
    await expectSmoothRowHover(tester, _label('Clínicas'), bases: navyBases);
    await expectSmoothRowHover(tester, _label('Biblioteca'), bases: navyBases);
    await expectSmoothRowHover(tester, _label('Recolher menu'),
        bases: navyBases);
    // O véu do botão fica sobre o degradê dele.
    await expectSmoothRowHover(tester, _label('Novo acesso'),
        bases: const [Color(0xFF00A39B), Color(0xFF2F6FE4)]);
    await _pump(tester, tablet, '/platform/users');
    await expectSmoothRowHover(tester, _label('Clínicas'), bases: navyBases);
  });

  testWidgets('hover com disableAnimations é instantâneo', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester, desk, '/platform/users');
    await expectSmoothRowHover(tester, _label('Clínicas'),
        reduced: true, bases: navyBases);
  });

  testWidgets('celular não muda', (tester) async {
    await _pump(tester, phone, '/platform/users');
    expect(_menu, findsNothing);
    expect(find.text('Separação por vínculo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
