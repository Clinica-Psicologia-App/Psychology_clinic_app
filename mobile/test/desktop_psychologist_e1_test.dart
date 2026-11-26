// E1 da psicóloga em desktop: casca (menu B) e Início a partir de 768 px.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_alert.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_routes.dart';
import 'package:terapia_esquema/features/profile/presentation/widgets/user_avatar.dart';
import 'package:terapia_esquema/shared/widgets/app_canopy_header.dart';
import 'package:terapia_esquema/shared/widgets/app_scaffold.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_side_menu.dart';
import 'package:terapia_esquema/shared/widgets/desktop_psychologist/desktop_psychologist_menu.dart';

import 'desktop_admin_hover_helper.dart';
import 'psychologist_desktop_fixtures.dart';

const desk = Size(1366, 768);
const wide = Size(1920, 1080);
const tablet = Size(834, 1112);
const phone = Size(390, 844);
const navyBases = [Color(0xFF0D1B3D), Color(0xFF0A1530)];

late GoRouter _router;
late PsiLoads _loads;

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  String location = '/psychologist',
  Future<List<PsychologistAlert>> Function()? alerts,
  bool dark = false,
  bool tourSeen = true,
}) async {
  SharedPreferences.setMockInitialValues(
      tourSeen ? {'coach_seen_tour_home_psicologo': true} : {});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  addTearDown(() => desktopAdminMenuCollapsed.value = false);
  _router = psiRouter(location);
  _loads = PsiLoads();
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(
      psiApp(_router, loads: _loads, alerts: alerts, dark: dark));
  await _settle(tester, 15);
}

Future<void> _settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _menu = find.byType(DesktopPsychologistMenu);

Finder _inMenu(Finder f) => find.descendant(of: _menu, matching: f);
Finder _label(String text) => _inMenu(find.text(text));

/// Texto fora do menu (conteúdo da tela).
Finder _content(String text) => find.byElementPredicate((e) {
      final w = e.widget;
      if (w is! Text || w.data != text) return false;
      var inMenu = false;
      e.visitAncestorElements((a) {
        if (a.widget is DesktopPsychologistMenu) inMenu = true;
        return !inMenu;
      });
      return !inMenu;
    });

bool? _selected(WidgetTester tester, String label) => tester
    .widget<Semantics>(find
        .ancestor(of: _label(label), matching: find.byType(Semantics))
        .first)
    .properties
    .selected;

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

double _opacity(WidgetTester tester, Finder inside) => tester
    .widget<FadeTransition>(find
        .ancestor(of: inside, matching: find.byKey(daContentEntranceKey))
        .first)
    .opacity
    .value;

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

  testWidgets('menu: marca, grupos, contadores, ação e perfil (1366 e 1920)',
      (tester) async {
    for (final size in [desk, wide]) {
      await _pump(tester, size);
      expect(_menu, findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.getSize(_menu).width, size == desk ? 232 : 256);
      for (final label in [
        'ATENDIMENTO',
        'RECURSOS',
        'Início',
        'Pacientes',
        'Convites',
        'Questionários',
        'Novo paciente',
        'Recolher menu',
        'Dra. Helena Exemplo',
        'Profissional',
      ]) {
        expect(_label(label), findsOneWidget, reason: label);
      }
      expect(_inMenu(find.textContaining('Versão')), findsOneWidget);
      // 5 pacientes ativos (a inativa não conta) e 1 convite pendente.
      for (final (label, count) in [('Pacientes', '5'), ('Convites', '1')]) {
        expect(
            (tester.getCenter(_label(count)).dy -
                    tester.getCenter(_label(label)).dy)
                .abs(),
            lessThan(8),
            reason: '$label $count');
      }
      expect(_label('GESTÃO'), findsNothing);
      expect(_label('Novo acesso'), findsNothing);
      expect(_selected(tester, 'Início'), isTrue);
      expect(_selected(tester, 'Pacientes'), isFalse);
      expect(tester.takeException(), isNull, reason: '${size.width}');
    }
  });

  testWidgets('Início: saudação, números, notificações e atalhos abertos',
      (tester) async {
    await _pump(tester, desk);
    expect(_content('Início'), findsOneWidget);
    expect(_content('Profissional'), findsOneWidget);
    expect(find.byTooltip('Rever tutorial'), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.textContaining(RegExp(r'^BO[AM] ')), findsOneWidget);
    expect(_content('Dra. Helena Exemplo'), findsOneWidget);
    expect(_content('1 convite aguardando aceite. Bom trabalho por aqui.'),
        findsOneWidget);
    expect(_content('pacientes'), findsOneWidget);
    expect(_content('convite'), findsOneWidget);
    expect(_content('questionários liberados'), findsOneWidget);

    expect(_content('Notificações'), findsOneWidget);
    for (final text in [
      'Rafael Modelo',
      'Questionário em andamento',
      '41 dias',
      'Clara Teste',
      '40 dias',
      'Marina Exemplo',
      'Check-in realizado',
      'há 3h',
    ]) {
      expect(_content(text), findsOneWidget, reason: text);
    }

    // Os dois blocos já abertos, com as seis ações e os textos de hoje.
    expect(_content('Meus pacientes'), findsOneWidget);
    expect(_content('5 pacientes · 1 convite'), findsOneWidget);
    expect(_content('Avaliação e recursos'), findsOneWidget);
    expect(_content('6 questionários liberados'), findsOneWidget);
    for (final text in [
      'Carteira e plano terapêutico',
      'Enviar e acompanhar o aceite',
      'Cadastrar um paciente',
      'Questionários',
      'Instrumentos e liberação',
      'Resultados',
      'Respostas e revisão',
      'Recursos terapêuticos',
      'Materiais e exercícios',
    ]) {
      expect(_content(text), findsOneWidget, reason: text);
    }
    // Notificações à esquerda, atalhos numa coluna de 340 px à direita.
    expect(tester.getTopLeft(_content('Meus pacientes')).dx,
        greaterThan(tester.getTopRight(_content('Rafael Modelo')).dx));
    // Nada do cabeçalho do celular.
    expect(find.byType(AppCanopyScaffold), findsNothing);
    expect(find.byType(AppCanopyHeader), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem consulta nova: menu e Início usam as mesmas fontes',
      (tester) async {
    await _pump(tester, desk);
    await tester.tap(_label('Pacientes'));
    await _settle(tester);
    await tester.tap(_label('Início'));
    await _settle(tester);
    expect(
        (_loads.patients, _loads.invitations, _loads.questionnaires,
            _loads.alerts),
        (1, 1, 1, 1));
  });

  testWidgets('menu parado: navega, marca o item e não se move na troca',
      (tester) async {
    await _pump(tester, desk);
    final state = tester.state(_menu);
    final before = tester.getTopLeft(_label('Recolher menu'));
    for (final (label, rota) in [
      ('Pacientes', '/psychologist/patients'),
      ('Convites', '/psychologist/patient-invitations'),
      ('Questionários', '/psychologist/questionnaires'),
      ('Início', '/psychologist'),
    ]) {
      await tester.tap(_label(label));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(_menu, findsOneWidget);
      expect(tester.getTopLeft(_label('Recolher menu')), before,
          reason: '$label no meio da troca');
      await _settle(tester);
      expect(_location(), rota);
      expect(_selected(tester, label), isTrue, reason: label);
      expect(tester.takeException(), isNull, reason: label);
    }
    expect(identical(tester.state(_menu), state), isTrue);
  });

  testWidgets('atalhos do Início abrem os mesmos destinos e voltam',
      (tester) async {
    await _pump(tester, desk);
    for (final (title, rota, item) in [
      ('Carteira e plano terapêutico', '/psychologist/patients', 'Pacientes'),
      (
        'Enviar e acompanhar o aceite',
        '/psychologist/patient-invitations',
        'Convites'
      ),
      ('Cadastrar um paciente', '/psychologist/patients/new', 'Pacientes'),
      (
        'Instrumentos e liberação',
        '/psychologist/questionnaires',
        'Questionários'
      ),
    ]) {
      await tester.tap(_content(title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      // Tela empilhada também entra só pelo conteúdo, com o menu parado.
      expect(
          tester
              .widget<FadeTransition>(find.byKey(daContentEntranceKey).last)
              .opacity
              .value,
          inExclusiveRange(0.0, 1.0),
          reason: title);
      await _settle(tester);
      // Push: o menu acompanha a tela aberta.
      expect(_menu, findsOneWidget);
      expect(_location(), rota);
      expect(_selected(tester, item), isTrue, reason: '$title -> $item');
      expect(_selected(tester, 'Início'), isFalse, reason: title);
      _router.pop();
      await _settle(tester);
      expect(_selected(tester, 'Início'), isTrue, reason: 'voltar de $title');
    }
    for (final (title, intent) in [
      ('Respostas e revisão', 'results'),
      ('Materiais e exercícios', 'therapyResources'),
    ]) {
      await tester.tap(_content(title));
      await _settle(tester);
      expect(find.textContaining('PatientSelectionIntent.$intent'),
          findsOneWidget);
      _router.pop();
      await _settle(tester);
    }
  });

  testWidgets('cada notificação leva ao mesmo destino do celular',
      (tester) async {
    await _pump(tester, desk);
    for (final (name, page) in [
      ('Rafael Modelo', 'Ficha p4'),
      ('Clara Teste', 'Ficha p2'),
      ('Marina Exemplo', 'Check-ins p3'),
    ]) {
      await tester.tap(_content(name));
      await _settle(tester);
      expect(find.text(page), findsOneWidget, reason: name);
      expect(_selected(tester, 'Pacientes'), isTrue);
      _router.pop();
      await _settle(tester);
    }
  });

  testWidgets('"Ver todas" e "Mostrar menos"', (tester) async {
    final many = [
      ...psiAlerts,
      const PsychologistAlert(
          kind: PsychologistAlertKind.pendingResultsRelease,
          patientName: 'Tiago Fictício',
          daysCount: 2,
          patientId: 'p5'),
    ];
    await _pump(tester, desk, alerts: () async => many);
    expect(_content('Tiago Fictício'), findsNothing);
    await tester.tap(_content('Ver todas (4)'));
    await _settle(tester);
    expect(_content('Tiago Fictício'), findsOneWidget);
    await tester.tap(_content('Mostrar menos'));
    await _settle(tester);
    expect(_content('Tiago Fictício'), findsNothing);
  });

  testWidgets('sem notificações: sem painel, blocos lado a lado',
      (tester) async {
    await _pump(tester, desk, alerts: () async => const []);
    expect(_content('Notificações'), findsNothing);
    final a = tester.getTopLeft(_content('Meus pacientes'));
    final b = tester.getTopLeft(_content('Avaliação e recursos'));
    expect(a.dy, b.dy);
    expect(b.dx, greaterThan(a.dx + 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('carregando: painel com esqueleto, sem contagem', (tester) async {
    await _pump(tester, desk,
        alerts: () => Future.any(<Future<List<PsychologistAlert>>>[]));
    expect(_content('Notificações'), findsOneWidget);
    expect(_content('Rafael Modelo'), findsNothing);
    expect(_content('Meus pacientes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"Novo paciente" do menu não empilha duas vezes',
      (tester) async {
    await _pump(tester, desk, location: '/psychologist/patients');
    await tester.tap(_label('Novo paciente'));
    await _settle(tester);
    expect(_location(),
        PatientRoutes.create(psiProfile.role));
    await tester.tap(_label('Novo paciente'));
    await _settle(tester);
    _router.pop();
    await _settle(tester);
    expect(_location(), '/psychologist/patients');
  });

  testWidgets('perfil: rodapé do menu e avatar do Início', (tester) async {
    await _pump(tester, desk);
    await tester.tap(_label('Dra. Helena Exemplo'));
    await _settle(tester);
    expect(find.text('Perfil fictício'), findsOneWidget);
    _router.pop();
    await _settle(tester);
    await tester.tap(find.byType(UserAvatar));
    await _settle(tester);
    expect(find.text('Perfil fictício'), findsOneWidget);
  });

  testWidgets('conteúdo entra com fade + 8 px; a barra do Início não anima',
      (tester) async {
    await _pump(tester, desk);
    await tester.tap(_label('Convites'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final entering = find.byKey(daContentEntranceKey).last;
    final fade = tester.widget<FadeTransition>(entering).opacity.value;
    expect(fade, inExclusiveRange(0.0, 1.0));
    await _settle(tester);
    expect(tester.widget<FadeTransition>(entering).opacity.value, 1);

    // Voltar ao Início: a tela que sai some na hora e o conteúdo reentra.
    await tester.tap(_label('Início'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 40));
    expect(_opacity(tester, _content('Meus pacientes')),
        inExclusiveRange(0.0, 1.0));
    expect(
        find.ancestor(
            of: _content('Profissional'),
            matching: find.byKey(daContentEntranceKey)),
        findsNothing);
    await _settle(tester);
    expect(_opacity(tester, _content('Meus pacientes')), 1);
  });

  testWidgets('reduzir movimento: troca sem animação', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester, desk);
    await tester.tap(_label('Convites'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(
        tester
            .widget<FadeTransition>(find.byKey(daContentEntranceKey).last)
            .opacity
            .value,
        1);
    await _settle(tester);
    await tester.tap(_label('Recolher menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getSize(_menu).width, 64);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recolhe com dica e contador; tablet vira trilho',
      (tester) async {
    await _pump(tester, desk);
    await tester.tap(_label('Recolher menu'));
    await _settle(tester);
    expect(tester.getSize(_menu).width, 64);
    expect(_label('ATENDIMENTO'), findsNothing);
    expect(_inMenu(find.byTooltip('Pacientes · 5')), findsOneWidget);
    expect(_inMenu(find.byTooltip('Questionários')), findsOneWidget);
    expect(_inMenu(find.byTooltip('Instrumentos')), findsNothing);
    expect(_inMenu(find.byTooltip('Novo paciente')), findsOneWidget);

    for (final size in const [tablet, Size(768, 1024), Size(1366, 560)]) {
      await _pump(tester, size);
      expect(_label('Convites'), findsOneWidget);
      expect(_content('Avaliação e recursos'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
      if (size.width < 1024) {
        expect(tester.getSize(_menu).width, 76);
        expect(_label('Recolher menu'), findsNothing);
        // Uma coluna: atalhos abaixo das notificações.
        expect(tester.getTopLeft(_content('Meus pacientes')).dy,
            greaterThan(tester.getTopLeft(_content('Marina Exemplo')).dy));
      }
    }
  });

  testWidgets('telas ainda de celular abrem dentro da casca sem overflow',
      (tester) async {
    for (final size in const [tablet, Size(768, 1024), desk]) {
      for (final location in const [
        '/psychologist/patients',
        '/psychologist/patient-invitations',
        '/psychologist/questionnaires',
      ]) {
        await _pump(tester, size, location: location);
        expect(_menu, findsOneWidget, reason: '$location $size');
        expect(tester.takeException(), isNull, reason: '$location $size');
      }
    }
  });

  testWidgets('tema escuro sem overflow', (tester) async {
    for (final size in [desk, tablet]) {
      await _pump(tester, size, dark: true);
      expect(_content('Meus pacientes'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('hover sem piscada: menu, notificação e atalho', (tester) async {
    await _pump(tester, desk);
    await expectSmoothRowHover(tester, _label('Pacientes'), bases: navyBases);
    await expectSmoothRowHover(tester, _label('Novo paciente'),
        bases: const [Color(0xFF00A39B), Color(0xFF2F6FE4)]);
    await expectSmoothRowHover(tester, _content('Rafael Modelo'));
    await expectSmoothRowHover(tester, _content('Respostas e revisão'));
  });

  testWidgets('tutorial: aponta os dois blocos e o botão de ajuda o reabre',
      (tester) async {
    await _pump(tester, desk, tourSeen: false);
    expect(find.textContaining('Aqui no topo ficam as notificações'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Pular'));
    await _settle(tester);
    expect(find.textContaining('Aqui no topo'), findsNothing);
    await tester.tap(find.byTooltip('Rever tutorial'));
    await _settle(tester);
    expect(find.textContaining('Aqui no topo'), findsOneWidget);
    await tester.tap(find.text('Pular'));
    await _settle(tester);
  });

  testWidgets('celular não muda e a troca de largura não quebra',
      (tester) async {
    await _pump(tester, phone);
    expect(_menu, findsNothing);
    expect(find.byType(DesktopSideMenu), findsNothing);
    expect(find.byType(AppCanopyScaffold), findsOneWidget);
    expect(find.text('Meus pacientes'), findsOneWidget);
    expect(find.text('Carteira e plano terapêutico'), findsNothing);
    expect(find.byKey(daContentEntranceKey), findsNothing);

    // Redimensionar a janela (web): cruza os 768 px nos dois sentidos.
    tester.view.physicalSize = desk;
    await _settle(tester);
    expect(_menu, findsOneWidget);
    expect(find.text('Carteira e plano terapêutico'), findsOneWidget);
    tester.view.physicalSize = phone;
    await _settle(tester);
    expect(_menu, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
