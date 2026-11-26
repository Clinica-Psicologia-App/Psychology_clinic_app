import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/auth/presentation/login_page.dart';
import 'package:terapia_esquema/features/auth/presentation/widgets/desktop_login/desktop_login_background.dart';
import 'package:terapia_esquema/features/auth/presentation/widgets/desktop_login/desktop_login_showcase.dart';
import 'package:terapia_esquema/features/auth/presentation/widgets/desktop_login/desktop_login_title.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';

class _FakeAuth extends AuthController {
  _FakeAuth(this.calls) : super(_DummyRef()) {
    state = const AsyncValue<UserProfile?>.data(null);
  }

  final List<List<String>> calls;

  @override
  Future<void> signIn(String email, String password) async {
    calls.add([email, password]);
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

const _panel = ValueKey('desktop_login_panel');
ValueKey<String> _scene(int i) => ValueKey('desktop_login_scene_$i');

Future<void> _open(
  WidgetTester tester,
  Size size, {
  List<List<String>>? calls,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/terms', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/privacy', builder: (_, __) => const Scaffold()),
    ],
  );
  final theme = AppTheme.light;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider
            .overrideWith((ref) => _FakeAuth(calls ?? <List<String>>[])),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, disableAnimations: disableAnimations),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
          theme: theme.copyWith(
            textTheme: theme.textTheme.apply(fontFamily: 'Poppins'),
          ),
        ),
      ),
    ),
  );
  // entrada escalonada (≈ 1 s) — sem pumpAndSettle (há animações em loop)
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      final file = File('assets/fonts/$f');
      if (file.existsSync()) {
        await ui.loadFontFromList(file.readAsBytesSync(), fontFamily: 'Poppins');
      }
    }
  });

  testWidgets('layout C2 aparece a partir de 768 e não aparece no celular',
      (tester) async {
    await _open(tester, const Size(834, 1112));
    expect(find.byKey(_panel), findsOneWidget);
    expect(find.text('Acesso clínico'), findsOneWidget);
    await _drain(tester);

    await _open(tester, const Size(767, 1000));
    expect(find.byKey(_panel), findsNothing);
    expect(find.text('Acesso clínico'), findsNothing);
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    await _drain(tester);

    await _open(tester, const Size(390, 844));
    expect(find.byKey(_panel), findsNothing);
    expect(find.text('Bem-vindo de volta'), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('mantém textos e campos do login', (tester) async {
    await _open(tester, const Size(1366, 768));
    for (final t in const [
      'Bem-vindo de volta',
      'Entre com seu e-mail e senha para acessar sua área.',
      'E-mail',
      'Senha',
      'Esqueci minha senha',
      'Entrar',
      'Novo acesso?',
      'Termos',
      'Privacidade',
      'Seguro',
      'Profissional',
      'Clínico',
      'FEITO PARA PSICÓLOGOS',
      'Acesso clínico',
      'Entre para continuar seu trabalho com segurança.',
      'Genograma clínico',
      'Questionários validados',
      'Jornada do paciente',
      'Segurança clínica',
    ]) {
      expect(find.text(t), findsWidgets, reason: t);
    }
    await _drain(tester);
  });

  testWidgets('validadores mostram as mensagens do app', (tester) async {
    await _open(tester, const Size(1366, 768));
    await tester.tap(find.text('Entrar'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Informe o e-mail'), findsOneWidget);
    expect(find.text('Informe a senha'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('desktop_login_email')), 'sem-arroba');
    await tester.enterText(find.byKey(const ValueKey('desktop_login_password')), 'x');
    await tester.tap(find.text('Entrar'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('E-mail inválido'), findsOneWidget);
    expect(find.text('Informe a senha'), findsNothing);
    await _drain(tester);
  });

  testWidgets('Enter no campo de senha envia', (tester) async {
    final calls = <List<String>>[];
    await _open(tester, const Size(1366, 768), calls: calls);
    await tester.enterText(
        find.byKey(const ValueKey('desktop_login_email')), 'helena@example.com');
    await tester.enterText(
        find.byKey(const ValueKey('desktop_login_password')), 'exemplo12');
    await tester.tap(find.byKey(const ValueKey('desktop_login_password')));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, [
      ['helena@example.com', 'exemplo12']
    ]);
    await _drain(tester);
  });

  testWidgets('etiqueta "Enter" só em notebook/desktop sem toque',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await _open(tester, const Size(1366, 768));
      expect(find.text('Enter'), findsOneWidget);
      await _drain(tester);
      await _open(tester, const Size(834, 1112));
      expect(find.text('Enter'), findsNothing);
      await _drain(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('carrossel avança com o tempo', (tester) async {
    await _open(tester, const Size(1366, 768));
    expect(find.byKey(_scene(0)), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(_scene(1)), findsOneWidget);
    expect(find.byKey(_scene(0)), findsNothing);
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(_scene(2)), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('com "reduzir movimento" o carrossel não avança', (tester) async {
    await _open(tester, const Size(1366, 768), disableAnimations: true);
    expect(find.byKey(_scene(0)), findsOneWidget);
    await tester.pump(const Duration(seconds: 9));
    expect(find.byKey(_scene(0)), findsOneWidget);
    expect(find.byKey(_scene(1)), findsNothing);
    await _drain(tester);
  });

  testWidgets('clicar na aba troca a cena', (tester) async {
    await _open(tester, const Size(1366, 768));
    await tester.tap(find.byKey(const ValueKey('desktop_login_tab_2')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(_scene(2)), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('desktop_login_tab_3')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(_scene(3)), findsOneWidget);
    await _drain(tester);
  });

  testWidgets('com "reduzir movimento" a aba também troca a cena',
      (tester) async {
    await _open(tester, const Size(1366, 768), disableAnimations: true);
    await tester.tap(find.byKey(const ValueKey('desktop_login_tab_1')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(_scene(1)), findsOneWidget);
    await _drain(tester);
  });

  for (final size in const [
    Size(834, 1112),
    Size(1366, 768),
    Size(1920, 1080),
    Size(1024, 768),
    Size(1280, 720),
  ]) {
    testWidgets('sem overflow em ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
      await _open(tester, size);
      // percorre as 4 cenas
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(ValueKey('desktop_login_tab_$i')));
        await tester.pump(const Duration(seconds: 3));
      }
      expect(tester.takeException(), isNull);
      await _drain(tester);
    });
  }

  testWidgets('sem rolagem em 1366x768 e em 1920x1080', (tester) async {
    for (final size in const [Size(1366, 768), Size(1920, 1080)]) {
      await _open(tester, size);
      for (final e in find.byType(Scrollable).evaluate()) {
        final st = (e as StatefulElement).state as ScrollableState;
        expect(st.position.maxScrollExtent, 0,
            reason: 'rolagem em ${size.width.toInt()}x${size.height.toInt()}');
      }
      await _drain(tester);
    }
  });

  testWidgets('ciclo de vida: em segundo plano para as 3 animações e volta',
      (tester) async {
    await _open(tester, const Size(1366, 768));
    bool all(bool v) =>
        tester
                .state<DesktopLoginBackgroundState>(
                    find.byType(DesktopLoginBackground))
                .isAnimating ==
            v &&
        tester
                .state<DesktopLoginTitleState>(find.byType(DesktopLoginTitle))
                .isAnimating ==
            v &&
        tester
                .state<DesktopLoginShowcaseState>(
                    find.byType(DesktopLoginShowcase))
                .isAnimating ==
            v;
    expect(all(true), isTrue);

    for (final st in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await tester.pump();
    expect(all(false), isTrue);
    // parado de verdade: o carrossel não troca de cena
    await tester.pump(const Duration(seconds: 6));
    expect(find.byKey(_scene(0)), findsOneWidget);

    for (final st in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(st);
    }
    await tester.pump();
    expect(all(true), isTrue);
    await _drain(tester);
  });

  testWidgets('Tab percorre E-mail → Senha → olho → Esqueci → Entrar',
      (tester) async {
    await _open(tester, const Size(1366, 768));
    bool focusIn(Finder f) {
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx == null) return false;
      return find
          .descendant(
              of: f, matching: find.byElementPredicate((e) => identical(e, ctx)))
          .evaluate()
          .isNotEmpty ||
          find
              .ancestor(
                  of: find.byElementPredicate((e) => identical(e, ctx)),
                  matching: f)
              .evaluate()
              .isNotEmpty;
    }

    await tester.tap(find.byKey(const ValueKey('desktop_login_email')));
    await tester.pump();
    expect(focusIn(find.byKey(const ValueKey('desktop_login_email'))), isTrue);

    Future<void> tab() async {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tab();
    expect(
        focusIn(find.byKey(const ValueKey('desktop_login_password'))), isTrue,
        reason: 'senha');
    await tab();
    expect(focusIn(find.byType(IconButton)), isTrue, reason: 'olho');
    await tab();
    expect(focusIn(find.widgetWithText(TextButton, 'Esqueci minha senha')),
        isTrue,
        reason: 'esqueci');
    await tab();
    expect(
        focusIn(find.byWidgetPredicate(
            (w) => w is FilledButton)),
        isTrue,
        reason: 'entrar');
    await _drain(tester);
  });

  testWidgets('tema escuro monta sem erro', (tester) async {
    tester.view.physicalSize = const Size(1366, 768);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider
              .overrideWith((ref) => _FakeAuth(<List<String>>[])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [GoRoute(path: '/', builder: (_, __) => const LoginPage())],
          ),
          theme: AppTheme.dark.copyWith(
            textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Poppins'),
          ),
        ),
      ),
    );
    for (var i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(_panel), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _drain(tester);
  });
}
