// E2 da psicóloga em desktop: Pacientes em tabela a partir de 768 px.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/patient_data_completion.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_alert.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/desktop_patients_view.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/patient_list_tile.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_kit.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_psychologist/desktop_psychologist_menu.dart';
import 'package:terapia_esquema/shared/widgets/loading_skeleton.dart';

import 'desktop_admin_hover_helper.dart';
import 'psychologist_desktop_fixtures.dart';

const desk = Size(1366, 768);
const wide = Size(1920, 1080);
const tablet = Size(834, 1112);
const phone = Size(390, 2000);
const list = '/psychologist/patients';

late GoRouter _router;
late PsiLoads _loads;

Widget _stub(String text) => Scaffold(body: Center(child: Text(text)));

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  String location = list,
  Future<List<Patient>> Function()? patients,
  Future<List<PsychologistAlert>> Function()? alerts,
  Map<String, PatientDataCompletion>? completion,
  Set<String> pendingRelease = const {'p5'},
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues(
      {'coach_seen_tour_home_psicologo': true});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _router = psiRouter(location, patientRoutes: [
    GoRoute(
        path: 'results',
        builder: (_, s) => _stub('Resultados ${s.pathParameters['patientId']}')),
    GoRoute(
        path: 'initial-assessment',
        builder: (_, s) =>
            _stub('Avaliação ${s.pathParameters['patientId']}')),
  ]);
  _loads = PsiLoads();
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(psiApp(
    _router,
    loads: _loads,
    patients: patients,
    alerts: alerts,
    completion: completion ?? psiCompletion,
    pendingRelease: pendingRelease,
    dark: dark,
  ));
  await _settle(tester, 15);
}

Future<void> _settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _view = find.byType(DesktopPatientsView);

Finder _in(Finder f) => find.descendant(of: _view, matching: f);
Finder _text(String s) => _in(find.text(s));

/// Linha da tabela que contém o nome.
Finder _row(String name) =>
    find.ancestor(of: _text(name), matching: find.byType(InkWell)).first;

Finder _inRow(String name, Finder f) =>
    find.descendant(of: _row(name), matching: f);

const _names = [
  'Beatriz Amostra',
  'Clara Teste',
  'Marina Exemplo',
  'Rafael Modelo',
  'Tiago Fictício',
  'Sofia Simulada',
];

/// Nomes visíveis, de cima para baixo.
List<String> _order(WidgetTester tester) {
  final found = <(double, String)>[
    for (final name in _names)
      if (find.text(name).evaluate().isNotEmpty)
        (tester.getTopLeft(find.text(name).first).dy, name),
  ]..sort((a, b) => a.$1.compareTo(b.$1));
  return [for (final f in found) f.$2];
}

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await _settle(tester, 3);
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

  testWidgets('barra superior: título, alertas, contagem e ações',
      (tester) async {
    await _pump(tester, desk);
    expect(_view, findsOneWidget);
    expect(find.byType(PatientListTile), findsNothing);
    for (final text in [
      'Pacientes',
      '2 alertas',
      '5 ativos · 6 total',
      'Convidar',
      'Novo paciente',
    ]) {
      expect(_text(text), findsOneWidget, reason: text);
    }
    expect(_loads.patients, 1);
    await tester.tap(_in(find.byTooltip('Atualizar')));
    await _settle(tester);
    expect(_loads.patients, 2);

    await tester.tap(_text('Convidar'));
    await _settle(tester);
    expect(_location(), '/psychologist/patient-invitations/new');
    _router.pop();
    await _settle(tester);
    await tester.tap(_text('Novo paciente'));
    await _settle(tester);
    expect(_location(), '$list/new');
    _router.pop();
    await _settle(tester);
    expect(_location(), list);
  });

  testWidgets('tabela: cabeçalhos, e-mail sob o nome e situação por linha',
      (tester) async {
    await _pump(tester, desk);
    for (final h in [
      'Paciente',
      'Status',
      'Último check-in',
      'Semana',
      'Adesão',
    ]) {
      expect(_text(h), findsOneWidget, reason: h);
    }
    for (var i = 1; i <= 5; i++) {
      expect(_text('usuario$i@example.com'), findsOneWidget);
      final name = tester.getTopLeft(_text(_names[i - 1]));
      final email = tester.getTopLeft(_text('usuario$i@example.com'));
      expect(email.dy, greaterThan(name.dy));
      expect(email.dx, name.dx);
    }
    // Em dia.
    expect(_inRow('Beatriz Amostra', find.text('Em dia')), findsOneWidget);
    expect(_inRow('Beatriz Amostra', find.text('Sem check-ins ainda')),
        findsOneWidget);
    // Sem check-in há 40 dias: motivo na coluna, sem botão.
    expect(_inRow('Clara Teste', find.text('Atenção')), findsOneWidget);
    expect(_inRow('Clara Teste', find.text('40 dias sem check-in')),
        findsOneWidget);
    expect(_inRow('Clara Teste', find.byType(IconButton)), findsNothing);
    expect(
        _inRow('Clara Teste', find.byIcon(Icons.lock_open_rounded)),
        findsNothing);
    // Só "Resultado a liberar": traço no check-in; motivo e botão na ponta.
    expect(_inRow('Tiago Fictício', find.text('Atenção')), findsOneWidget);
    expect(_inRow('Tiago Fictício', find.text('—')), findsOneWidget);
    expect(_inRow('Tiago Fictício', find.text('Sem check-ins ainda')),
        findsNothing);
    final reason = _inRow('Tiago Fictício', find.text('Resultado a liberar'));
    expect(reason, findsOneWidget);
    expect(tester.getTopLeft(reason).dx,
        greaterThan(tester.getTopLeft(_text('Adesão')).dx));
    expect(
        _inRow('Tiago Fictício',
            find.byTooltip('Abrir resultados para liberar')),
        findsOneWidget);
    // A inativa não aparece no filtro padrão.
    expect(find.text('Sofia Simulada'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('semana e adesão: pontos, porcentagem, dica e traços',
      (tester) async {
    await _pump(tester, desk,
        completion: {...psiCompletion}..remove('p4'),
        alerts: () async => [
              ...psiAlerts,
              const PsychologistAlert(
                  kind: PsychologistAlertKind.missingCheckin,
                  patientName: 'Marina Exemplo',
                  daysCount: 3,
                  patientId: 'p3'),
            ]);
    // 3 dias: atenção, 4 pontos preenchidos.
    expect(_inRow('Marina Exemplo', find.text('3 dias sem check-in')),
        findsOneWidget);
    expect(_inRow('Marina Exemplo', find.text('Atenção')), findsOneWidget);
    int filled(String name) => tester
        .widgetList<Text>(_inRow(name, find.byType(Text)))
        .where((w) => const ['S', 'T', 'Q', 'D'].contains(w.data))
        .where((w) => w.style!.color!.a == 1)
        .length;
    expect(filled('Beatriz Amostra'), 7);
    expect(filled('Marina Exemplo'), 4);
    expect(filled('Clara Teste'), 0);

    for (final (name, percent) in const [
      ('Beatriz Amostra', '83'),
      ('Clara Teste', '17'),
      ('Marina Exemplo', '100'),
      ('Tiago Fictício', '33'),
    ]) {
      expect(_inRow(name, find.text(percent)), findsOneWidget, reason: name);
      expect(
          tester
              .widget<CircularProgressIndicator>(
                  _inRow(name, find.byType(CircularProgressIndicator)))
              .value,
          closeTo(int.parse(percent) / 100, 0.01));
    }
    expect(_inRow('Marina Exemplo',
        find.byTooltip('Avaliação inicial completa')), findsOneWidget);
    expect(_inRow('Beatriz Amostra', find.byTooltip('Falta: Questionários')),
        findsOneWidget);
    // Sem dado de preenchimento: traço.
    expect(_inRow('Rafael Modelo', find.byType(CircularProgressIndicator)),
        findsNothing);
    expect(_inRow('Rafael Modelo', find.text('—')), findsOneWidget);
  });

  testWidgets('filtros Ativos, Inativos e Todos', (tester) async {
    await _pump(tester, desk);
    await tester.tap(_text('Inativos'));
    await _settle(tester);
    expect(_order(tester), ['Sofia Simulada']);
    expect(_inRow('Sofia Simulada', find.text('Inativo')), findsOneWidget);
    expect(_inRow('Sofia Simulada', find.text('Acompanhamento encerrado')),
        findsOneWidget);
    // Inativa: sem semana nem adesão (como no celular).
    expect(_inRow('Sofia Simulada', find.text('—')), findsNWidgets(2));
    await tester.tap(_text('Todos'));
    await _settle(tester);
    expect(_order(tester), hasLength(6));
    await tester.tap(_text('Ativos'));
    await _settle(tester);
    expect(_order(tester), hasLength(5));
  });

  testWidgets('mesma lista e mesma ordem do celular em todo filtro e ordem',
      (tester) async {
    final alerts = [
      ...psiAlerts,
      const PsychologistAlert(
          kind: PsychologistAlertKind.missingCheckin,
          patientName: 'Rafael Modelo',
          daysCount: 3,
          patientId: 'p4'),
    ];
    Future<Map<String, List<String>>> orders(Size size) async {
      await _pump(tester, size, alerts: () async => alerts);
      // No celular o texto "Ativos" também aparece no cabeçalho.
      Finder option(String label) {
        final chip = find.widgetWithText(FilterChip, label);
        return chip.evaluate().isEmpty ? _text(label) : chip;
      }

      final result = <String, List<String>>{};
      for (final filter in ['Ativos', 'Inativos', 'Todos']) {
        await tester.tap(option(filter));
        await _settle(tester, 6);
        for (final sort in ['A–Z', 'Último acesso', 'Alertas']) {
          await tester.tap(option(sort));
          await _settle(tester, 6);
          result['$filter/$sort'] = _order(tester);
        }
      }
      return result;
    }

    final mobile = await orders(phone);
    final desktop = await orders(desk);
    expect(desktop, mobile);
    // E a ordem muda de fato entre os modos.
    expect(desktop['Ativos/Alertas'], isNot(desktop['Ativos/A–Z']));
  });

  testWidgets('busca por nome, e-mail e psicólogo; limpar e Esc',
      (tester) async {
    await _pump(tester, desk);
    await _search(tester, 'marina');
    expect(_order(tester), ['Marina Exemplo']);
    await tester.tap(_in(find.byTooltip('Limpar busca')));
    await _settle(tester);
    expect(_order(tester), hasLength(5));
    expect(_in(find.byTooltip('Limpar busca')), findsNothing);

    await _search(tester, 'usuario4@');
    expect(_order(tester), ['Rafael Modelo']);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(_order(tester), hasLength(5));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);

    await _search(tester, 'dra. helena');
    expect(_order(tester), hasLength(5));
  });

  testWidgets('sem resultado: textos de hoje e "Limpar busca e filtros"',
      (tester) async {
    await _pump(tester, desk);
    await _search(tester, 'zzz');
    expect(_text('Nenhum resultado'), findsOneWidget);
    expect(_text('Nenhum paciente corresponde à busca ou aos filtros.'),
        findsOneWidget);
    await tester.tap(_text('Limpar busca e filtros'));
    await _settle(tester);
    // Como hoje: limpa a busca e passa para "Todos".
    expect(_order(tester), hasLength(6));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
  });

  testWidgets('carteira vazia: texto aprovado no desktop; celular igual',
      (tester) async {
    await _pump(tester, desk, patients: () async => const []);
    expect(_text('Nenhum paciente'), findsOneWidget);
    expect(_text('Nenhum paciente encontrado.'), findsOneWidget);
    expect(_text('Use Novo paciente para cadastrar o primeiro.'),
        findsOneWidget);
    expect(find.textContaining('Toque em +'), findsNothing);
    expect(_text('0 ativos · 0 total'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _pump(tester, phone, patients: () async => const []);
    expect(find.textContaining('Toque em + para cadastrar o primeiro.'),
        findsOneWidget);
    expect(find.textContaining('Use Novo paciente'), findsNothing);
  });

  testWidgets('carregando: esqueleto na tabela, filtros no lugar',
      (tester) async {
    await _pump(tester, desk,
        patients: () => Future.any(<Future<List<Patient>>>[]));
    expect(_in(find.byType(LoadingSkeleton)), findsWidgets);
    expect(_text('Paciente'), findsOneWidget);
    expect(_text('Ativos'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Marina Exemplo'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('erro: mesma mensagem e tentar de novo', (tester) async {
    var fail = true;
    await _pump(tester, desk, patients: () async {
      if (fail) throw Exception('falha fictícia');
      return psiPatients;
    });
    expect(_text('Não conseguimos carregar. Pode tentar de novo?'),
        findsOneWidget);
    fail = false;
    await tester.tap(_text('Tentar novamente'));
    await _settle(tester);
    expect(_order(tester), hasLength(5));
  });

  testWidgets('linha abre a ficha, por clique e por Enter', (tester) async {
    await _pump(tester, desk);
    await tester.tap(_text('Marina Exemplo'));
    await _settle(tester);
    expect(find.text('Ficha p3'), findsOneWidget);
    _router.pop();
    await _settle(tester);
    expect(_view, findsOneWidget);

    Focus.of(tester.element(_text('Rafael Modelo'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.text('Ficha p4'), findsOneWidget);
  });

  testWidgets('botão do motivo vai direto ao assunto, sem abrir a ficha',
      (tester) async {
    await _pump(tester, desk);
    await tester.tap(_in(find.byTooltip('Abrir resultados para liberar')));
    await _settle(tester);
    expect(find.text('Resultados p5'), findsOneWidget);
    expect(find.text('Ficha p5', skipOffstage: false), findsNothing);
    _router.pop();
    await _settle(tester);

    // Avaliação inicial vazia: traço no check-in e botão próprio.
    await _pump(tester, desk, pendingRelease: const {}, completion: {
      'p5': const PatientDataCompletion(
          patientId: 'p5',
          perfil: false,
          queixa: false,
          areas: false,
          historia: false,
          familia: false,
          questionarios: false),
    });
    expect(_inRow('Tiago Fictício', find.text('Sem avaliação inicial')),
        findsOneWidget);
    await tester.tap(_in(find.byTooltip('Abrir avaliação inicial')));
    await _settle(tester);
    expect(find.text('Avaliação p5'), findsOneWidget);
  });

  testWidgets('sem alertas: sem selo e todos em dia', (tester) async {
    await _pump(tester, desk,
        alerts: () async => const [], pendingRelease: const {});
    expect(find.textContaining('alertas'), findsNothing);
    expect(_text('Em dia'), findsNWidgets(5));
  });

  testWidgets('larguras: colunas visíveis e sem overflow', (tester) async {
    for (final size in const [
      Size(768, 1024),
      tablet,
      Size(1024, 768),
      desk,
      Size(1440, 900),
      wide,
      Size(1366, 560),
    ]) {
      await _pump(tester, size);
      expect(find.byType(DesktopPsychologistMenu), findsOneWidget);
      for (final text in [
        'Adesão',
        'Beatriz Amostra',
        'Tiago Fictício',
        'Resultado a liberar',
      ]) {
        expect(_text(text), findsOneWidget, reason: '$text $size');
        expect(tester.getTopRight(_text(text)).dx,
            lessThanOrEqualTo(size.width),
            reason: '$text $size');
      }
      expect(_in(find.byTooltip('Abrir resultados para liberar')),
          findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      // Estados dentro do painel também cabem.
      await _search(tester, 'zzz');
      expect(tester.takeException(), isNull, reason: 'vazio $size');
    }
  });

  testWidgets('lista longa rola dentro do painel, com o cabeçalho parado',
      (tester) async {
    await _pump(tester, desk,
        patients: () async => [
              for (var i = 0; i < 60; i++)
                Patient(
                    id: 'x$i',
                    fullName: 'Pessoa Fictícia ${i + 100}',
                    email: 'usuario$i@example.com'),
            ]);
    final header = tester.getTopLeft(_text('Paciente'));
    expect(find.text('Pessoa Fictícia 159'), findsNothing);
    await tester.drag(_text('Pessoa Fictícia 103'), const Offset(0, -4000));
    await _settle(tester);
    expect(find.text('Pessoa Fictícia 159'), findsOneWidget);
    expect(tester.getTopLeft(_text('Paciente')), header);
    expect(tester.takeException(), isNull);
  });

  testWidgets('menu marca Pacientes e a barra não reanima ao voltar',
      (tester) async {
    await _pump(tester, desk, location: '/psychologist');
    await tester.tap(find.text('Carteira e plano terapêutico'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    // Tela com barra própria: uma única entrada, só no conteúdo.
    final entrance = find.ancestor(
        of: _text('Beatriz Amostra'),
        matching: find.byKey(daContentEntranceKey));
    expect(entrance, findsOneWidget);
    expect(tester.widget<FadeTransition>(entrance).opacity.value,
        inExclusiveRange(0.0, 1.0));
    expect(
        find.ancestor(
            of: _text('Convidar'),
            matching: find.byKey(daContentEntranceKey)),
        findsNothing);
    await _settle(tester);
    final selected = tester
        .widget<Semantics>(find
            .ancestor(
                of: find.descendant(
                    of: find.byType(DesktopPsychologistMenu),
                    matching: find.text('Pacientes')),
                matching: find.byType(Semantics))
            .first)
        .properties
        .selected;
    expect(selected, isTrue);
  });

  testWidgets('escolha de paciente (atalho) segue como antes, com entrada',
      (tester) async {
    await _pump(tester, desk, location: '/psychologist');
    await tester.tap(find.text('Respostas e revisão'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final picker = find.textContaining('Escolher paciente');
    expect(picker, findsOneWidget);
    expect(_view, findsNothing);
    expect(
        tester
            .widget<FadeTransition>(find
                .ancestor(
                    of: picker, matching: find.byKey(daContentEntranceKey))
                .first)
            .opacity
            .value,
        inExclusiveRange(0.0, 1.0));
    await _settle(tester);
  });

  testWidgets('hover sem piscada na linha; reduzir movimento sem animação',
      (tester) async {
    await _pump(tester, desk);
    await expectSmoothRowHover(tester, _text('Marina Exemplo'));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester, desk);
    await expectSmoothRowHover(tester, _text('Marina Exemplo'), reduced: true);
    expect(
        tester
            .widget<CircularProgressIndicator>(_inRow('Beatriz Amostra',
                find.byType(CircularProgressIndicator)))
            .value,
        closeTo(5 / 6, 0.001));
  });

  testWidgets('segmentos marcam a opção e a busca limpa usa o kit',
      (tester) async {
    await _pump(tester, tablet);
    expect(find.byType(DaSegmented<int>), findsNWidgets(2));
    expect(find.byType(DaSearchField), findsOneWidget);
    bool? selected(String label) => tester
        .widget<Semantics>(find
            .ancestor(of: _text(label), matching: find.byType(Semantics))
            .first)
        .properties
        .selected;
    expect(selected('Ativos'), isTrue);
    expect(selected('A–Z'), isTrue);
    await tester.tap(_text('Alertas'));
    await _settle(tester);
    expect(selected('Alertas'), isTrue);
    expect(selected('A–Z'), isFalse);
  });

  testWidgets('tema escuro sem overflow', (tester) async {
    for (final size in [desk, tablet]) {
      await _pump(tester, size, dark: true);
      expect(_text('Beatriz Amostra'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('celular não muda; busca e filtro sobrevivem à troca de largura',
      (tester) async {
    await _pump(tester, phone);
    expect(_view, findsNothing);
    expect(find.byType(PatientListTile), findsNWidgets(5));
    expect(find.byType(FilterChip), findsNWidgets(6));

    tester.view.physicalSize = desk;
    await _settle(tester);
    await _search(tester, 'marina');
    tester.view.physicalSize = phone;
    await _settle(tester);
    expect(find.byType(PatientListTile), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = desk;
    await _settle(tester);
    expect(_order(tester), ['Marina Exemplo']);
  });
}
