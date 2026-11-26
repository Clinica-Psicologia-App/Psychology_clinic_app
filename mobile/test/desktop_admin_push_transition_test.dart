// Reproduz a tela inteira deslizando ao abrir sub-rota /platform via context.push
// em desktop admin (≥768 px).
//
// Causa: _isDesktopAdminRoute usava settings.key; rotas declarativas têm
// pageKey = ValueKey('/platform/...'), mas context.push gera pageKey aleatório
// (ImperativeRouteMatch._getUniqueValueKey) → check falha → transição genérica
// (slide + fade) é aplicada à página inteira, incluindo o menu lateral.
//
// FALHA com o código anterior; PASSA após a correção em app_theme.dart.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/platform_admin/presentation/platform_admin_home_page.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
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

/// Stub do editor da Biblioteca: inclui a própria casca, como o app real.
class _LibraryEditorStub extends StatelessWidget {
  const _LibraryEditorStub({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 768) {
      return Scaffold(body: Center(child: Text('Editor $id')));
    }
    return DesktopAdminShell(
      nav: DesktopAdminNav.home,
      title: 'Editor de Trabalho',
      body: Center(child: Text('Trabalho $id')),
    );
  }
}

/// Página não-admin para testar que a rota de saída mantém a animação.
class _OtherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Outra tela')));
  }
}

const _dest = [
  AppNavDestination(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/platform',
      exactMatch: true),
];

late GoRouter _router;

Future<void> _pump(WidgetTester tester, Size size, String location) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  final router = _router = GoRouter(
    initialLocation: location,
    routes: [
      // Rota não-admin: sem name começando com /platform.
      GoRoute(path: '/other', builder: (_, __) => _OtherPage()),
      ShellRoute(
        builder: (_, __, child) =>
            AppNavShell(destinations: _dest, child: child),
        routes: [
          GoRoute(
            path: '/platform',
            name: '/platform',
            builder: (_, __) => const PlatformAdminHomePage(),
            routes: [
              GoRoute(
                path: 'library/:id',
                name: '/platform/library/:id',
                builder: (_, state) =>
                    _LibraryEditorStub(id: state.pathParameters['id']!),
              ),
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
        await ui.loadFontFromList(file.readAsBytesSync(), fontFamily: 'Poppins');
      }
    }
  });

  const desk = Size(1366, 768);

  testWidgets(
    'menu não desliza ao abrir sub-rota /platform via push imperativo (1366 px)',
    (tester) async {
      await _pump(tester, desk, '/platform');

      expect(find.text('Recolher menu'), findsOneWidget,
          reason: 'menu visível na tela inicial');
      final before = tester.getTopLeft(find.text('Recolher menu'));

      // Push imperativo: go_router gera pageKey aleatório (não '/platform/...').
      _router.push('/platform/library/w1');
      await tester.pump(); // inicia transição
      await tester.pump(const Duration(milliseconds: 50)); // meio da animação (150 ms)

      // Com o bug: nova tela desliza da direita (offset 8% = ~109 px em 1366);
      // 'Recolher menu' da nova casca estaria ~74 px à direita de before.
      // Com a correção: sem deslize; posição idêntica a before em todos os frames.
      final menuFinder = find.text('Recolher menu');
      final count = menuFinder.evaluate().length;
      Offset rightmost = tester.getTopLeft(menuFinder.first);
      for (var i = 1; i < count; i++) {
        final pos = tester.getTopLeft(menuFinder.at(i));
        if (pos.dx > rightmost.dx) rightmost = pos;
      }
      expect(rightmost.dx, closeTo(before.dx, 2.0),
          reason: 'menu não pode deslizar durante a transição imperativa');

      // Deixa a animação terminar e confere estado final.
      await _settle(tester, 15);
      expect(find.text('Trabalho w1'), findsOneWidget,
          reason: 'editor deve estar visível após a transição');
      expect(find.text('Recolher menu'), findsOneWidget,
          reason: 'menu deve estar visível após a transição');
      expect(tester.getTopLeft(find.text('Recolher menu')).dx,
          closeTo(before.dx, 2.0),
          reason: 'menu na posição correta após transição completa');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'página não-admin mantém animação de saída ao empurrar /platform (1366 px)',
    (tester) async {
      await _pump(tester, desk, '/other');

      expect(find.text('Outra tela'), findsOneWidget);
      final otherBefore = tester.getTopLeft(find.text('Outra tela'));

      // Push de /platform sobre a rota não-admin.
      // Com o bug antigo (URI global): GoRouter.state.uri = '/platform' →
      // _isDesktopAdminRoute retorna true para a rota de baixo → sem animação de saída.
      // Com a correção (name): settings.name do /other = null → chave '/other' →
      // _isDesktopAdminRoute retorna false → animação de saída (slide para esquerda).
      _router.push('/platform');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 75)); // t ≈ 50 % da animação

      // A rota de baixo deve ter deslizado para a esquerda (secondary animation).
      final otherAfter = tester.getTopLeft(find.text('Outra tela'));
      expect(
        otherAfter.dx,
        lessThan(otherBefore.dx - 1.0),
        reason: 'rota não-admin deve deslizar para esquerda na saída',
      );

      await _settle(tester, 15); // drena timers pendentes (_MotionRevealState etc.)
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'menu não desliza ao voltar da sub-rota /platform via pop (1366 px)',
    (tester) async {
      // Começa já no editor para poder fazer pop.
      await _pump(tester, desk, '/platform/library/w1');

      expect(find.text('Recolher menu'), findsOneWidget,
          reason: 'menu visível no editor');
      final before = tester.getTopLeft(find.text('Recolher menu'));

      _router.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50)); // meio da transição

      // Após o pop, o menu da tela que re-entra (catalog) deve estar na mesma posição.
      final menuFinder = find.text('Recolher menu');
      final count = menuFinder.evaluate().length;
      Offset leftmost = tester.getTopLeft(menuFinder.first);
      for (var i = 1; i < count; i++) {
        final pos = tester.getTopLeft(menuFinder.at(i));
        if (pos.dx < leftmost.dx) leftmost = pos;
      }
      expect(leftmost.dx, closeTo(before.dx, 2.0),
          reason: 'menu não pode deslizar durante o pop de sub-rota admin');

      await _settle(tester, 15);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'saída do admin para rota não-admin via go não apresenta exceção (1366 px)',
    (tester) async {
      await _pump(tester, desk, '/platform');
      expect(find.text('Recolher menu'), findsOneWidget);

      _router.go('/other');
      await _settle(tester, 15);

      expect(find.text('Outra tela'), findsOneWidget,
          reason: 'tela não-admin deve aparecer após o go');
      expect(find.text('Recolher menu'), findsNothing,
          reason: 'menu admin não deve aparecer na tela não-admin');
      expect(tester.takeException(), isNull);
    },
  );
}
