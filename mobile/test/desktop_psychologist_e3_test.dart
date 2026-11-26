// E3 da psicóloga em desktop: ficha do paciente a partir de 768 px. Tudo o que
// a ficha do celular mostra e abre é comparado com a de desktop.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_draft.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/patient_vitals.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_details_page.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/desktop_patient_file.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/patient_context_header.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_psychologist/desktop_psychologist_menu.dart';
import 'package:terapia_esquema/shared/widgets/module_grid_card.dart';

import 'desktop_admin_hover_helper.dart';
import 'psychologist_desktop_fixtures.dart';

const desk = Size(1366, 768);
const wide = Size(1920, 1080);
const tablet = Size(834, 1112);
const phone = Size(390, 5000);
const file = '/psychologist/patients/p3';

const _groups = {
  'Conhecer meu paciente': 'História, vínculos e contexto de vida.',
  'Avaliar': 'Instrumentos psicológicos e resultados.',
  'Compreender': 'Formulação e visão integrada do caso.',
  'Intervir': 'Planejamento e recursos de intervenção.',
  'Acompanhar': 'Monitoramento contínuo entre sessões.',
};

const _modules = [
  'Dados Iniciais',
  'Contexto de Vida',
  'Demandas Terapêuticas',
  'Linha do Tempo',
  'Genograma',
  'Recursos Saudáveis',
  'Esquemas',
  'Personalidade',
  'Apego',
  'Conceitualização de Caso',
  'Mapa Mental',
  'Infográficos',
  'Plano Terapêutico',
  'Recursos Terapêuticos',
  'Biblioteca de filmes',
  'Psicoeducação',
  'Check-in',
  'Diário',
  'Exercícios e Tarefas',
];

late GoRouter _router;

Widget _destination(BuildContext context, GoRouterState state) {
  final extra = state.extra;
  final shown = extra is PatientInvitationDraft
      ? 'convite ${extra.fullName} ${extra.email} ${extra.phone} '
          '${extra.responsiblePsychologistId}'
      : '$extra';
  return Scaffold(body: Center(child: Text('Destino ${state.uri} | $shown')));
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  String location = file,
  Patient? Function()? patient,
  Future<PatientVitals?> Function()? vitals,
  Future<ClinicFeatureEntitlements> Function()? entitlements,
  bool tourSeen = true,
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'coach_seen_tour_home_psicologo': true,
    if (tourSeen) 'coach_seen_tour_ficha_paciente': true,
  });
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _router = psiRouter(
    location,
    ficha: (_, __) => const PatientDetailsPage(
        role: ProfileRole.psychologist, patientId: 'p3'),
    newInvitation: _destination,
    patientRoutes: [
      GoRoute(path: ':a', builder: _destination, routes: [
        GoRoute(path: ':b', builder: _destination, routes: [
          GoRoute(path: ':c', builder: _destination),
        ]),
      ]),
    ],
    outside: [
      GoRoute(
          path: '/psychologist/genogram-panel/:id', builder: _destination),
      GoRoute(path: '/psychologist/psychoeducation', builder: _destination),
    ],
  );
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(psiApp(
    _router,
    dark: dark,
    entitlements: entitlements,
    overrides: [
      patientDetailProvider.overrideWith(
          (ref, id) async => patient == null ? psiMarina() : patient()),
      patientVitalsProvider.overrideWith(
          (ref, id) => vitals == null ? Future.value(psiVitals) : vitals()),
    ],
  ));
  await _settle(tester, 15);
}

Future<void> _settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

final _view = find.byType(DesktopPatientFile);
final _board = find.byType(DesktopModuleBoard);

Finder _in(Finder f) => find.descendant(of: _view, matching: f);
Finder _text(String s) => _in(find.text(s));
Finder _module(String title) =>
    find.descendant(of: _board, matching: find.text(title));
Finder _tile(String title) =>
    find.ancestor(of: _module(title), matching: find.byType(InkWell)).first;

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

/// Toca e devolve o destino aberto (nulo se nada abriu), voltando em seguida.
Future<String?> _open(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await _settle(tester, 3);
  await tester.tap(target);
  await _settle(tester);
  final found = find.textContaining('Destino ');
  if (found.evaluate().isEmpty) return null;
  final text = tester.widget<Text>(found).data!;
  _router.pop();
  await _settle(tester);
  return text;
}

/// Subtítulo e disponibilidade de cada módulo na ficha aberta.
Map<String, (String, bool)> _mobileModules(WidgetTester tester) => {
      for (final c
          in tester.widgetList<ModuleGridCard>(find.byType(ModuleGridCard)))
        c.title: (c.subtitle, c.enabled),
    };

Map<String, (String, bool)> _desktopModules(WidgetTester tester) {
  return {
    for (final title in _modules)
      title: (
        tester
            .widgetList<Text>(find.descendant(
                of: _tile(title), matching: find.byType(Text)))
            .last
            .data!,
        tester.widget<InkWell>(_tile(title)).onTap != null,
      ),
  };
}

/// Cinco colunas lado a lado, ou um bloco por grupo com 2 colunas.
void _expectArrangement(WidgetTester tester,
    {required bool columns, required String reason}) {
  final headers = [
    for (final title in _groups.keys) tester.getTopLeft(_module(title)),
  ];
  final first = tester.getTopLeft(_module('Dados Iniciais'));
  final second = tester.getTopLeft(_module('Contexto de Vida'));
  for (var i = 1; i < headers.length; i++) {
    if (columns) {
      expect(headers[i].dy, headers.first.dy, reason: reason);
      expect(headers[i].dx, greaterThan(headers[i - 1].dx), reason: reason);
    } else {
      expect(headers[i].dx, headers.first.dx, reason: reason);
      expect(headers[i].dy, greaterThan(headers[i - 1].dy), reason: reason);
    }
  }
  if (columns) {
    expect(second.dx, first.dx, reason: reason);
    expect(second.dy, greaterThan(first.dy), reason: reason);
  } else {
    expect(second.dy, first.dy, reason: reason);
    expect(second.dx, greaterThan(first.dx + 150), reason: reason);
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

  testWidgets('barra: trilha, identidade, situação, psicóloga e ações',
      (tester) async {
    await _pump(tester, desk);
    expect(_view, findsOneWidget);
    expect(find.byType(PatientContextHeader), findsNothing);
    for (final text in [
      'Pacientes',
      'Marina Exemplo',
      'PACIENTE ATIVO',
      'App ativo',
      'Dra. Helena Exemplo',
      'Tour',
      'Relatório clínico',
      'Dados cadastrais',
    ]) {
      expect(_text(text), findsOneWidget, reason: text);
    }
    expect(_text('Ativo'), findsNothing);
    // A etiqueta do acesso fica logo depois da situação.
    expect(tester.getTopLeft(_text('App ativo')).dx,
        greaterThan(tester.getTopRight(_text('PACIENTE ATIVO')).dx));
    // Tudo na barra, em uma linha.
    final y = tester.getCenter(_text('Dados cadastrais')).dy;
    for (final text in [
      'Pacientes',
      'Marina Exemplo',
      'App ativo',
      'Tour'
    ]) {
      expect(tester.getCenter(_text(text)).dy, closeTo(y, 2), reason: text);
    }
    // Em 1366 e 1920 o nome da psicóloga aparece inteiro, com e sem acesso.
    for (final size in [desk, wide]) {
      for (final (access, label) in const [
        (PatientAccessStatus.active, 'App ativo'),
        (PatientAccessStatus.noAppAccess, 'Sem acesso ao app'),
      ]) {
        await _pump(tester, size,
            patient: () => psiMarina(access: access));
        final text = tester.renderObject<RenderParagraph>(find.descendant(
            of: _text('Dra. Helena Exemplo'),
            matching: find.byType(RichText)));
        expect(text.didExceedMaxLines, isFalse, reason: '$size $access');
        expect(_text(label), findsOneWidget);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('faixa: identificação e os três números', (tester) async {
    await _pump(tester, desk,
        patient: () => psiMarina(relationship: 'single'));
    for (final text in [
      'Idade',
      'Nascimento',
      'Ocupação',
      'Designer',
      'Estado civil',
      'Solteiro(a)',
      'Resumo do paciente',
      'Há 2d',
      'Último check-in',
      '3',
      'Metas ativas',
      '1 pend.',
      'Questionários',
    ]) {
      expect(_text(text), findsOneWidget, reason: text);
    }
    expect(find.textContaining(' anos'), findsOneWidget);
    expect(find.textContaining('1992'), findsOneWidget);
  });

  testWidgets('resumo: "Em dia" e "Nenhum"; some carregando ou com erro',
      (tester) async {
    await _pump(tester, desk,
        vitals: () async => const PatientVitals(
            lastCheckinDays: null,
            activeGoals: 0,
            pendingQuestionnaires: 0));
    expect(_text('Nenhum'), findsOneWidget);
    expect(_text('Em dia'), findsOneWidget);

    for (final vitals in <Future<PatientVitals?> Function()>[
      () => Future.any(<Future<PatientVitals?>>[]),
      () async => throw Exception('falha fictícia'),
      () async => null,
    ]) {
      await _pump(tester, desk, vitals: vitals);
      expect(_text('Resumo do paciente'), findsNothing);
      expect(_text('Metas ativas'), findsNothing);
      expect(_text('Designer'), findsOneWidget);
      expect(_text('Relatório clínico'), findsOneWidget);
      expect(_module('Check-in'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('5 grupos e 19 módulos: mesmos nomes e descrições do celular',
      (tester) async {
    await _pump(tester, phone);
    final mobile = _mobileModules(tester);
    expect(mobile.keys, _modules);

    await _pump(tester, desk);
    for (final group in _groups.entries) {
      expect(_module(group.key), findsOneWidget);
      expect(_module(group.value), findsOneWidget);
    }
    expect(_desktopModules(tester), mobile);
  });

  testWidgets('1366x768 e 1920: cinco colunas sem rolagem', (tester) async {
    for (final size in [desk, wide]) {
      await _pump(tester, size);
      final tops = <double>[];
      final lefts = <double>[];
      for (final title in _groups.keys) {
        tops.add(tester.getTopLeft(_module(title)).dy);
        lefts.add(tester.getTopLeft(_module(title)).dx);
      }
      expect(tops.toSet(), hasLength(1), reason: '$size');
      expect([...lefts]..sort(), lefts);
      final scroll = tester.state<ScrollableState>(find
          .ancestor(of: _board, matching: find.byType(Scrollable))
          .first);
      expect(scroll.position.maxScrollExtent, 0, reason: '$size');
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('estreito: um bloco por grupo, módulos em 2 colunas',
      (tester) async {
    for (final size in const [Size(768, 1024), tablet, Size(1024, 768)]) {
      await _pump(tester, size);
      final first = tester.getTopLeft(_module('Dados Iniciais'));
      final second = tester.getTopLeft(_module('Contexto de Vida'));
      expect(second.dy, first.dy, reason: '$size');
      expect(second.dx, greaterThan(first.dx + 200));
      expect(tester.getTopLeft(_module('Avaliar')).dy,
          greaterThan(tester.getTopLeft(_module('Recursos Saudáveis')).dy));
      for (final title in _modules) {
        expect(_module(title), findsOneWidget, reason: '$title $size');
      }
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('troca em 900 px de área: 900, 1179, 1180, 1200 e 1360',
      (tester) async {
    // Janela, largura da área dos módulos e se são cinco colunas.
    for (final (width, area, columns) in const [
      (900.0, 784.0, false),
      (1179.0, 899.0, false),
      (1180.0, 900.0, true),
      (1200.0, 920.0, true),
      (1360.0, 1080.0, true),
    ]) {
      for (final patient in <Patient Function()>[
        psiMarina,
        () => psiMarina(
            name: 'Maria Aparecida dos Santos Fictícia de Albuquerque Teste',
            occupation: 'Coordenadora de projetos educacionais e comunitários',
            relationship: 'married',
            access: PatientAccessStatus.noAppAccess),
      ]) {
        await _pump(tester, Size(width, 900), patient: patient);
        expect(tester.getSize(_board).width, area, reason: '$width');
        _expectArrangement(tester, columns: columns, reason: '$width');
        for (final title in _modules) {
          expect(_module(title), findsOneWidget, reason: '$title $width');
          expect(tester.getTopRight(_tile(title)).dx,
              lessThanOrEqualTo(width),
              reason: '$title $width');
        }
        expect(tester.takeException(), isNull, reason: '$width');
      }
    }
  });

  testWidgets('redimensionar entre 1179 e 1200 troca o arranjo',
      (tester) async {
    await _pump(tester, const Size(1179, 900));
    _expectArrangement(tester, columns: false, reason: '1179');
    for (final (width, columns) in const [
      (1200.0, true),
      (1179.0, false),
      (1180.0, true),
    ]) {
      tester.view.physicalSize = Size(width, 900);
      await _settle(tester, 15);
      _expectArrangement(tester, columns: columns, reason: '$width');
      expect(tester.takeException(), isNull, reason: '$width');
    }
  });

  testWidgets('com o menu recolhido, 1024 já cabe em cinco colunas',
      (tester) async {
    await _pump(tester, const Size(1024, 768));
    _expectArrangement(tester, columns: false, reason: 'menu aberto');
    desktopAdminMenuCollapsed.value = true;
    addTearDown(() => desktopAdminMenuCollapsed.value = false);
    await _settle(tester, 15);
    _expectArrangement(tester, columns: true, reason: 'menu recolhido');
    expect(tester.takeException(), isNull);
  });

  testWidgets('nada se perde em nenhuma largura; textos longos não estouram',
      (tester) async {
    for (final size in const [
      Size(768, 1024),
      tablet,
      Size(1024, 768),
      Size(1200, 800),
      Size(1280, 720),
      desk,
      Size(1440, 900),
      wide,
    ]) {
      await _pump(tester, size,
          patient: () => psiMarina(
              name: 'Maria Aparecida dos Santos Fictícia de Albuquerque Teste',
              occupation:
                  'Coordenadora de projetos educacionais e comunitários',
              relationship: 'married',
              access: PatientAccessStatus.noAppAccess));
      for (final text in [
        'PACIENTE ATIVO',
        'Sem acesso ao app',
        'Dra. Helena Exemplo',
        'Estado civil',
        'Metas ativas',
        'Dados cadastrais',
        'Convidar paciente',
      ]) {
        expect(_text(text), findsOneWidget, reason: '$text $size');
        expect(tester.getTopRight(_text(text)).dx,
            lessThanOrEqualTo(size.width),
            reason: '$text $size');
      }
      for (final tip in ['Tour', 'Relatório clínico']) {
        expect(
            _text(tip).evaluate().length +
                _in(find.byTooltip(tip)).evaluate().length,
            greaterThanOrEqualTo(1),
            reason: '$tip $size');
      }
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('todos os destinos são os mesmos do celular', (tester) async {
    Patient patient() => psiMarina(access: PatientAccessStatus.noAppAccess);
    const common = [
      ..._modules,
      'Último check-in',
      'Metas ativas',
      'Dados cadastrais',
      'Relatório clínico',
    ];

    await _pump(tester, phone, patient: patient);
    final mobile = <String, String?>{
      for (final label in common)
        label: await _open(tester, find.text(label)),
      'Resumo: Questionários':
          await _open(tester, find.text('Questionários')),
      'Convidar paciente':
          await _open(tester, find.byTooltip('Convidar paciente')),
    };

    await _pump(tester, desk, patient: patient);
    final desktop = <String, String?>{
      for (final label in common) label: await _open(tester, _text(label)),
      'Resumo: Questionários': await _open(tester, _text('Questionários')),
      'Convidar paciente':
          await _open(tester, _in(find.byTooltip('Convidar paciente'))),
    };

    expect(mobile.values, everyElement(isNotNull));
    expect(desktop, mobile);
    expect(desktop['Convidar paciente'], contains('convite Marina Exemplo'));
    expect(desktop['Apego'], contains('attachment'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('plano bloqueado: mesmas regras; bloqueado não abre',
      (tester) async {
    await _pump(tester, phone, entitlements: () async => psiBlocked);
    final mobile = _mobileModules(tester);

    await _pump(tester, desk, entitlements: () async => psiBlocked);
    final desktop = _desktopModules(tester);
    expect(desktop, mobile);
    final blocked = [
      for (final e in desktop.entries)
        if (!e.value.$2) e.key,
    ];
    expect(blocked, [
      'Esquemas',
      'Apego',
      'Infográficos',
      'Recursos Terapêuticos',
      'Biblioteca de filmes',
      'Psicoeducação',
      'Exercícios e Tarefas',
    ]);
    expect(find.text('Bloqueado pelo plano da clínica.'), findsNWidgets(6));
    expect(_in(find.byIcon(Icons.lock_outline_rounded)), findsNWidgets(7));
    expect(await _open(tester, _module('Esquemas')), isNull);
    expect(_location(), file);
    expect(await _open(tester, _module('Personalidade')), isNotNull);
  });

  testWidgets('validando permissões: igual ao celular', (tester) async {
    Future<ClinicFeatureEntitlements> pending() =>
        Future.any(<Future<ClinicFeatureEntitlements>>[]);
    await _pump(tester, phone, entitlements: pending);
    final mobile = _mobileModules(tester);
    await _pump(tester, desk, entitlements: pending);
    expect(_desktopModules(tester), mobile);
    expect(find.text('Validando permissões...'), findsNWidgets(6));
  });

  testWidgets('convite só para ativo sem acesso; inativo sinalizado',
      (tester) async {
    await _pump(tester, desk);
    expect(_text('Convidar paciente'), findsNothing);
    await _pump(tester, desk,
        patient: () => psiMarina(
            active: false, access: PatientAccessStatus.noAppAccess));
    expect(_text('PACIENTE INATIVO'), findsOneWidget);
    expect(_text('PACIENTE ATIVO'), findsNothing);
    expect(_text('Convidar paciente'), findsNothing);
  });

  testWidgets('"App ativo" também na faixa; os outros acessos como hoje',
      (tester) async {
    for (final size in const [tablet, Size(1280, 720), desk]) {
      await _pump(tester, size);
      expect(_text('App ativo'), findsOneWidget, reason: '$size');
      expect(_text('Ativo'), findsNothing, reason: '$size');
    }
    await _pump(tester, desk,
        patient: () => psiMarina(
            active: false, access: PatientAccessStatus.inactive));
    expect(_text('Inativo'), findsOneWidget);
    expect(_text('App ativo'), findsNothing);
    // Sem informação de acesso: nenhuma etiqueta.
    await _pump(tester, desk, patient: () => psiMarina(access: null));
    expect(_text('App ativo'), findsNothing);
    expect(_text('Sem acesso ao app'), findsNothing);
  });

  testWidgets('carregando, erro e não encontrado dentro da moldura',
      (tester) async {
    var fail = true;
    await _pump(tester, desk, patient: () {
      if (fail) throw Exception('falha fictícia');
      return psiMarina();
    });
    expect(find.text('Não foi possível carregar o paciente.'), findsOneWidget);
    expect(find.byType(DesktopPatientFileFrame), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Tentar novamente'));
    await _settle(tester, 12);
    expect(_view, findsOneWidget);

    await _pump(tester, desk, patient: () => null);
    expect(find.text('Paciente não encontrado.'), findsOneWidget);
    // A trilha leva de volta à lista mesmo sem paciente.
    await tester.tap(find.descendant(
        of: find.byType(DesktopTopBar), matching: find.text('Pacientes')));
    await _settle(tester);
    expect(_location(), '/psychologist/patients');
  });

  testWidgets('trilha volta à lista; menu marca Pacientes', (tester) async {
    await _pump(tester, desk);
    final item = find.descendant(
        of: find.byType(DesktopPsychologistMenu),
        matching: find.text('Pacientes'));
    expect(
        tester
            .widget<Semantics>(find
                .ancestor(of: item, matching: find.byType(Semantics))
                .first)
            .properties
            .selected,
        isTrue);
    await tester.tap(_text('Pacientes'));
    await _settle(tester);
    expect(_location(), '/psychologist/patients');
    expect(_view, findsNothing);
  });

  testWidgets('dois toques não abrem a tela duas vezes', (tester) async {
    await _pump(tester, desk);
    await tester.tap(_module('Personalidade'));
    await tester.tap(_module('Mapa Mental'), warnIfMissed: false);
    await _settle(tester);
    expect(find.textContaining('Destino '), findsOneWidget);
    _router.pop();
    await _settle(tester);
    expect(_location(), file);
    expect(_view, findsOneWidget);
  });

  testWidgets('tutorial abre na primeira vez e volta pelo "Tour"',
      (tester) async {
    await _pump(tester, desk, tourSeen: false);
    expect(find.textContaining('Esta é a ficha completa'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Pular'));
    await _settle(tester);
    expect(find.textContaining('Esta é a ficha completa'), findsNothing);
    await tester.tap(_text('Tour'));
    await _settle(tester);
    expect(find.textContaining('Esta é a ficha completa'), findsOneWidget);
    await tester.tap(find.text('Pular'));
    await _settle(tester);
  });

  testWidgets('entra e volta animando só o conteúdo', (tester) async {
    await _pump(tester, desk, location: '/psychologist/patients');
    await tester.tap(find.text('Marina Exemplo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 40));
    final inBar = find.ancestor(
        of: _text('Dados cadastrais'),
        matching: find.byKey(daContentEntranceKey));
    expect(inBar, findsNothing);
    await _settle(tester, 12);
    expect(
        find.ancestor(
            of: _module('Check-in'),
            matching: find.byKey(daContentEntranceKey)),
        findsOneWidget);

    await tester.tap(_module('Diário'));
    await _settle(tester);
    _router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 40));
    expect(
        tester
            .widget<FadeTransition>(find
                .ancestor(
                    of: _module('Check-in'),
                    matching: find.byKey(daContentEntranceKey))
                .first)
            .opacity
            .value,
        inExclusiveRange(0.0, 1.0));
    await _settle(tester);
  });

  testWidgets('teclado: Enter abre o módulo', (tester) async {
    await _pump(tester, desk);
    Focus.of(tester.element(_module('Linha do Tempo'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _settle(tester);
    expect(find.textContaining('Destino '), findsOneWidget);
  });

  testWidgets('hover sem piscada; bloqueado não realça', (tester) async {
    await _pump(tester, desk);
    await expectSmoothRowHover(tester, _module('Mapa Mental'));
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await _pump(tester, desk, entitlements: () async => psiBlocked);
    await expectSmoothRowHover(tester, _module('Mapa Mental'), reduced: true);
    expect(tester.widget<InkWell>(_tile('Esquemas')).mouseCursor,
        SystemMouseCursors.basic);
  });

  testWidgets('tema escuro sem overflow', (tester) async {
    for (final size in [desk, tablet]) {
      await _pump(tester, size, dark: true);
      expect(_module('Check-in'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('celular não muda e a troca de largura não quebra',
      (tester) async {
    await _pump(tester, phone);
    expect(_view, findsNothing);
    expect(find.byType(PatientContextHeader), findsOneWidget);
    expect(find.byType(ModuleGridCard), findsNWidgets(19));
    // No celular a etiqueta continua como era.
    expect(find.text('Ativo'), findsOneWidget);
    expect(find.text('App ativo'), findsNothing);
    tester.view.physicalSize = desk;
    await _settle(tester);
    expect(_view, findsOneWidget);
    tester.view.physicalSize = phone;
    await _settle(tester);
    expect(find.byType(ModuleGridCard), findsNWidgets(19));
    expect(tester.takeException(), isNull);
  });
}
