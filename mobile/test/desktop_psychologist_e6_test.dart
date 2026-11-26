// E6 da psicóloga em desktop: Questionários a partir de 768 px. Destinos e
// regras são comparados com o celular.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_routes.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/widgets/desktop_psychologist_catalog.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/widgets/questionnaire_list_tile.dart';
import 'package:terapia_esquema/shared/widgets/async_state_body.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_kit.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'package:terapia_esquema/shared/widgets/loading_skeleton.dart';

import 'desktop_admin_hover_helper.dart';
import 'psychologist_desktop_fixtures.dart';

const desk = Size(1366, 768);
const wide = Size(1920, 1080);
const tablet = Size(834, 1112);
const phone = Size(390, 2400);

const catalog = '/psychologist/questionnaires';
const patients = '/psychologist/patients';

late GoRouter _router;
late PsiLoads _loads;

Future<void> _settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  Future<List<Questionnaire>> Function()? items,
  bool dark = false,
  bool reducedMotion = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'coach_seen_tour_home_psicologo': true,
    'coach_seen_tour_pacientes': true,
  });
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  if (reducedMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }
  desktopAdminMenuCollapsed.value = false;
  _loads = PsiLoads();
  _router = psiRouter('/psychologist');
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
      psiApp(_router, dark: dark, loads: _loads, questionnaires: items));
  await _settle(tester, 12);
  _router.push(catalog);
  await _settle(tester, 15);
}

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

Object? _extra() => _router.routerDelegate.currentConfiguration.last
    .buildState(
        _router.configuration, _router.routerDelegate.currentConfiguration)
    .extra;

final _view = find.byType(DesktopPsychologistCatalog);

Finder _in(String text) =>
    find.descendant(of: _view, matching: find.text(text));

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await _settle(tester, 3);
  await tester.tap(target);
  await _settle(tester, 10);
}

/// Toca e devolve (endereço, extra) abertos, voltando em seguida.
Future<(String, Object?)> _destination(
    WidgetTester tester, Finder target) async {
  await _tap(tester, target);
  final result = (_location(), _extra());
  if (result.$1 != catalog) {
    _router.pop();
    await _settle(tester, 12);
  }
  return result;
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

  testWidgets('abaixo de 768 segue a tela do celular; de 768 em diante, tabela',
      (tester) async {
    for (final w in [390.0, 767.0]) {
      await _pump(tester, Size(w, 2400));
      expect(_view, findsNothing);
      expect(find.text('INSTRUMENTOS CLÍNICOS'), findsOneWidget);
      expect(find.byType(QuestionnaireListTile), findsWidgets);
    }
    for (final size in const [Size(768, 1024), tablet, desk, wide]) {
      await _pump(tester, size);
      expect(_view, findsOneWidget);
      expect(find.text('INSTRUMENTOS CLÍNICOS'), findsNothing);
      expect(find.byType(QuestionnaireListTile), findsNothing);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('barra, atalho, catálogo, colunas e linhas', (tester) async {
    await _pump(tester, desk);
    for (final text in [
      'Questionários',
      'Instrumentos clínicos',
      'Liberar para paciente',
      'Escolha um paciente e libere os questionários.',
      'Catálogo disponível',
      'A disponibilidade para o paciente segue esta lista e a relação clínica com você.',
      'Instrumentos',
      'Instrumento',
      'Código',
      'Instrumento fictício 1',
      'Q1',
      'Instrumento fictício 6',
      'Q6',
      '6',
    ]) {
      expect(_in(text), findsOneWidget, reason: text);
    }
    expect(_in('Em validação'), findsNWidgets(6));
    expect(find.byTooltip('Atualizar'), findsOneWidget);
    expect(find.textContaining('Meus'), findsNothing);
  });

  testWidgets('nada do que o celular informa se perde', (tester) async {
    const shown = [
      'Inventário fictício completo',
      'Autora Exemplo',
      'v1.2',
      'Licença pendente validação (texto fictício).',
      'Uso autorizado (texto fictício).',
      'FICT_A',
      'PARENTAL_STYLES_V1',
      'Último mês',
      'História de vida',
      'Mãe e pai',
      'Homologado',
      'Em validação',
      'Suspenso',
      'Rascunho',
    ];
    final locks = <int>[];
    for (final size in [const Size(390, 4000), tablet, desk]) {
      await _pump(tester, size, items: () async => psiCatalogDetalhado());
      for (final text in shown) {
        expect(find.text(text), findsOneWidget, reason: '$size $text');
      }
      expect(find.textContaining('Descrição fictícia'), findsOneWidget);
      // Mesmo critério de aplicação: os mesmos cadeados.
      locks.add(find.byIcon(Icons.lock_outline).evaluate().length);
      expect(tester.takeException(), isNull, reason: '$size');
    }
    expect(locks[1], locks[0]);
    expect(locks[2], locks[0]);
    expect(locks[0], greaterThan(0));
    final t = DesktopAdminTokens.of(tester.element(_view));
    Color color(String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;
    expect(color('Licença pendente validação (texto fictício).'), t.err);
    expect(color('Uso autorizado (texto fictício).'), t.tx2);
  });

  testWidgets('mesmos destinos do celular: liberar e abrir instrumento',
      (tester) async {
    final results = <List<(String, Object?)>>[];
    for (final size in [phone, desk]) {
      await _pump(tester, size, items: () async => psiCatalogDetalhado());
      results.add([
        await _destination(tester, find.text('Liberar para paciente')),
        // Instrumento aplicável e bloqueado: hoje os dois abrem a lista.
        await _destination(tester, find.text('Inventário fictício completo')),
        await _destination(tester, find.text('Instrumento suspenso fictício')),
      ]);
    }
    expect(results[1], results[0]);
    expect(results[0], [
      (patients, PatientSelectionIntent.questionnaires),
      (patients, null),
      (patients, null),
    ]);
  });

  testWidgets('teclado: Tab chega ao atalho e Enter abre', (tester) async {
    await _pump(tester, desk);
    final release = Focus.of(tester.element(find.text('Liberar para paciente')),
        scopeOk: true);
    release.requestFocus();
    await _settle(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester, 12);
    expect(_location(), patients);
    expect(_extra(), PatientSelectionIntent.questionnaires);
  });

  testWidgets('vazio como hoje: sem atalho', (tester) async {
    for (final size in [phone, desk]) {
      await _pump(tester, size, items: () async => []);
      expect(find.text('Sem questionários liberados'), findsOneWidget);
      expect(
          find.textContaining(
              'Nenhum questionário liberado para você no momento.'),
          findsOneWidget);
      expect(
          find.textContaining(
              'Solicite ao administrador a liberação dos instrumentos.'),
          findsOneWidget);
      expect(find.text('Liberar para paciente'), findsNothing);
      expect(find.text('Catálogo disponível'), findsOneWidget);
    }
  });

  testWidgets('carregando: esqueleto, sem atalho nem número', (tester) async {
    final never = Completer<List<Questionnaire>>();
    await _pump(tester, desk, items: () => never.future);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.text('Liberar para paciente'), findsNothing);
    expect(_in('Instrumentos'), findsNothing);
    expect(_in('Código'), findsOneWidget);
  });

  testWidgets('erro: mensagem de hoje e tentar de novo recarrega',
      (tester) async {
    var fail = true;
    await _pump(tester, desk, items: () async {
      if (fail) throw StateError('x');
      return psiCatalog();
    });
    expect(
        find.text(
            'Não conseguimos carregar os questionários. Tente novamente.'),
        findsOneWidget);
    expect(find.text('Liberar para paciente'), findsNothing);
    fail = false;
    await _tap(
        tester,
        find.descendant(
            of: find.byType(ErrorStatePanel),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));
    expect(find.text('Instrumento fictício 1'), findsOneWidget);
  });

  testWidgets('Atualizar recarrega o catálogo', (tester) async {
    await _pump(tester, desk);
    final before = _loads.questionnaires;
    await _tap(tester, find.byTooltip('Atualizar'));
    expect(_loads.questionnaires, before + 1);
    expect(find.text('Instrumento fictício 1'), findsOneWidget);
  });

  testWidgets('passar o mouse na linha não pisca nem mexe', (tester) async {
    await _pump(tester, desk);
    await expectSmoothRowHover(tester, find.text('Instrumento fictício 2'));
  });

  testWidgets('movimento reduzido: sem exceção e realce instantâneo',
      (tester) async {
    await _pump(tester, desk, reducedMotion: true);
    expect(tester.takeException(), isNull);
    await expectSmoothRowHover(tester, find.text('Instrumento fictício 2'),
        reduced: true);
  });

  testWidgets('menu marca Questionários e a barra não é a do celular',
      (tester) async {
    await _pump(tester, desk);
    expect(find.byType(AppBar), findsNothing);
    expect(
        find.descendant(
            of: find.byType(DesktopTopBar),
            matching: find.text('Questionários')),
        findsOneWidget);
    expect(find.text('Questionários'), findsNWidgets(2));
  });

  testWidgets('escuro, telas baixas e textos longos sem estouro',
      (tester) async {
    for (final size in const [
      Size(768, 600),
      Size(1024, 640),
      Size(1280, 600),
      wide
    ]) {
      await _pump(tester, size,
          dark: true,
          items: () async => [
                Questionnaire(
                    id: 'long',
                    code: 'CODIGO_FICTICIO_MUITO_COMPRIDO_V10',
                    name: 'Instrumento fictício de nome comprido ' * 5,
                    description: 'Descrição fictícia repetida. ' * 20,
                    authorName: 'Autoria fictícia comprida ' * 6,
                    instrumentVersion: 'versão fictícia comprida ' * 4,
                    licenseNotes: 'Nota fictícia de licença. ' * 10,
                    isActive: true),
                ...psiCatalog(),
              ]);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
