import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_node_detail.dart';
import 'package:terapia_esquema/features/mental_map/presentation/mental_map_node_state.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_widgets.dart';

void main() {
  final center = const MentalCaseMapCenter(
    patientName: 'Maria Silva',
    activeProblemsLabel: '2 problemas ativos',
    activeGoalsLabel: '1 objetivo ativo',
    lastCheckInLabel: 'Humor 6 · Ans. 8',
  );

  final nodes = [
    const MentalMapHubNodeData(
      id: 'schemas',
      title: 'Esquemas',
      subtitle: 'Preenchido',
      items: ['Abandono 5.80', 'Privação 4.90'],
      emptyLabel: 'Pendente',
      icon: Icons.psychology_outlined,
      accentColor: Colors.blue,
      isFilled: true,
      visualState: MentalMapNodeVisualState.filled,
    ),
    const MentalMapHubNodeData(
      id: 'modes',
      title: 'Modos',
      subtitle: 'Preenchido',
      items: ['Criança vulnerável 5.40'],
      emptyLabel: 'Pendente',
      icon: Icons.self_improvement_outlined,
      accentColor: Colors.green,
      isFilled: true,
      visualState: MentalMapNodeVisualState.filled,
    ),
    const MentalMapHubNodeData(
      id: 'problems',
      title: 'Problemas',
      subtitle: '1 ativo',
      items: ['Ansiedade social'],
      emptyLabel: 'Pendente',
      icon: Icons.report_problem_outlined,
      accentColor: Colors.red,
      isFilled: true,
      visualState: MentalMapNodeVisualState.filled,
    ),
    const MentalMapHubNodeData(
      id: 'goals',
      title: 'Objetivos',
      subtitle: '1 ativo',
      items: ['Praticar exposição'],
      emptyLabel: 'Pendente',
      icon: Icons.flag_outlined,
      accentColor: Colors.orange,
      isFilled: true,
      visualState: MentalMapNodeVisualState.filled,
    ),
    const MentalMapHubNodeData(
      id: 'attachment',
      title: 'Apego',
      subtitle: 'Pendente',
      items: [],
      emptyLabel: 'Pendente',
      icon: Icons.favorite_border,
      accentColor: Colors.purple,
      isFilled: false,
      visualState: MentalMapNodeVisualState.pending,
    ),
    const MentalMapHubNodeData(
      id: 'coping',
      title: 'Enfrentamento',
      subtitle: 'Pendente',
      items: [],
      emptyLabel: 'Pendente',
      icon: Icons.shield_outlined,
      accentColor: Colors.teal,
      isFilled: false,
      visualState: MentalMapNodeVisualState.pending,
    ),
    const MentalMapHubNodeData(
      id: 'parental',
      title: 'Parentais',
      subtitle: 'Pendente',
      items: [],
      emptyLabel: 'Pendente',
      icon: Icons.family_restroom_outlined,
      accentColor: Colors.brown,
      isFilled: false,
      visualState: MentalMapNodeVisualState.pending,
    ),
    const MentalMapHubNodeData(
      id: 'history',
      title: 'História / Vínculos',
      subtitle: 'Preenchido',
      items: ['Mudança de trabalho'],
      emptyLabel: 'Pendente',
      icon: Icons.timeline_outlined,
      accentColor: Colors.indigo,
      isFilled: true,
      visualState: MentalMapNodeVisualState.filled,
    ),
  ];

  testWidgets('MentalMapRadialHub uses connected list on small screens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: MentalMapRadialHub(center: center, nodes: nodes),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('mental-map-connected-list')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('mental-map-radial-layout')), findsNothing);
  });

  for (final viewport in [(320.0, 1.6), (360.0, 1.6), (360.0, 2.0)]) {
    final (width, textScale) = viewport;
    testWidgets('órbita preserva layout e toques em $width e texto $textScale',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final opened = <String>[];
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: MentalMapRadialHub(
              center: center,
              nodes: [
                for (final node in nodes)
                  MentalMapHubNodeData(
                    id: node.id,
                    title: node.title,
                    subtitle: node.subtitle,
                    items: node.items,
                    emptyLabel: node.emptyLabel,
                    icon: node.icon,
                    accentColor: node.accentColor,
                    isFilled: node.isFilled,
                    visualState: node.visualState,
                    onTap: () => opened.add(node.id),
                  ),
              ],
            ),
          ),
        ),
      ));
      final orbit = tester.getRect(
          find.byKey(const ValueKey('mental-map-connected-list')));
      for (final node in nodes.where(
          (node) => !['parental', 'history'].contains(node.id))) {
        final label = find.text(node.title);
        expect(label, findsOneWidget);
        final rect = tester.getRect(label);
        expect(orbit.inflate(0.01).contains(rect.topLeft), isTrue,
            reason: '${node.id}: $rect fora de $orbit');
        expect(orbit.inflate(0.01).contains(rect.bottomRight), isTrue,
            reason: '${node.id}: $rect fora de $orbit');
        await tester.tap(label);
      }
      expect(opened,
          ['schemas', 'modes', 'problems', 'goals', 'attachment', 'coping']);
      // Confere também posições posteriores da flutuação, não só o frame inicial.
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 900));
        for (final node in nodes.where(
            (node) => !['parental', 'history'].contains(node.id))) {
          final rect = tester.getRect(find.text(node.title));
          expect(orbit.inflate(0.01).contains(rect.topLeft), isTrue,
              reason: '${node.id}: $rect fora de $orbit');
          expect(orbit.inflate(0.01).contains(rect.bottomRight), isTrue,
              reason: '${node.id}: $rect fora de $orbit');
        }
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final viewport in [(360.0, 1.0), (900.0, 1.0), (360.0, 1.6)]) {
    final (width, textScale) = viewport;
    testWidgets(
        'Personalidade abre detalhe em largura $width e texto $textScale',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const items = [
        'Neuroticismo: Muito Baixo',
        'Extroversão: Baixo',
        'Abertura à experiência: Médio',
      ];
      var opened = 0;
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(body: Builder(builder: (context) {
          return SingleChildScrollView(
            child: MentalMapVisualHub(
              caseMap: MentalCaseMap(
                  center: center,
                  primaryNodes: const [],
                  contextNodes: const []),
              nodes: [
                ...nodes,
                MentalMapHubNodeData(
                  id: 'personality',
                  title: 'Personalidade',
                  subtitle: 'Preenchido',
                  items: items,
                  emptyLabel: 'Pendente',
                  icon: Icons.psychology_alt_outlined,
                  accentColor: AppColors.purple,
                  isFilled: true,
                  visualState: MentalMapNodeVisualState.filled,
                  onTap: () {
                    opened++;
                    showMentalMapNodeDetailSheet(
                      context: context,
                      detail: const MentalMapNodeDetail(
                          id: 'personality',
                          title: 'Personalidade',
                          items: items,
                          dataSource: 'NEO PI-R - avaliação de personalidade',
                          ctaLabel: 'Abrir personalidade',
                          lastUpdatedAt: null),
                      onPrimaryTap: () {},
                    );
                  },
                ),
              ],
            ),
          );
        })),
      ));
      expect(find.text('Personalidade'), findsOneWidget);
      final card = find.byKey(const ValueKey('mental-map-personality'));
      await tester.ensureVisible(card);
      await tester.pump(const Duration(milliseconds: 300));
      for (final item in items) {
        expect(find.text(item), findsNothing);
      }
      await tester.tap(card);
      await tester.pump(const Duration(milliseconds: 300));
      expect(opened, 1);
      final sheet = find.byType(MentalMapNodeDetailSheet);
      expect(sheet, findsOneWidget);
      for (final item in items) {
        expect(find.descendant(of: sheet, matching: find.text(item)),
            findsOneWidget);
      }
      final dots = tester
          .widgetList<Icon>(
              find.descendant(of: sheet, matching: find.byIcon(Icons.circle)))
          .map((icon) => icon.color);
      expect(dots, [AppColors.error, AppColors.warning, AppColors.success]);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 900.0]) {
    testWidgets('Personalidade é uma bolinha do hub em largura $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MentalMapVisualHub(
              caseMap: MentalCaseMap.empty,
              nodes: [
                for (final id in const ['schemas', 'problems', 'personality'])
                  MentalMapHubNodeData(
                    id: id,
                    title: id == 'problems' ? 'Demandas' : id,
                    subtitle: 'Pendente',
                    items: const [],
                    emptyLabel: 'Pendente',
                    icon: Icons.hub_outlined,
                    accentColor: AppColors.blue,
                    isFilled: false,
                    visualState: MentalMapNodeVisualState.pending,
                  ),
              ],
            ),
          ),
        ),
      ));
      final bubble = find.byKey(const ValueKey('mental-map-personality'));
      expect(bubble, findsOneWidget);
      expect(find.byType(MentalMapHubNode), findsNothing);
      expect(find.text('Demandas'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Personalidade sem avaliação permite abrir o módulo existente',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: SingleChildScrollView(
          child: MentalMapVisualHub(
        caseMap: MentalCaseMap.empty,
        nodes: [
          MentalMapHubNodeData(
            id: 'personality',
            title: 'Personalidade',
            subtitle: 'Pendente',
            items: const [],
            emptyLabel: 'Pendente',
            icon: Icons.psychology_alt_outlined,
            accentColor: AppColors.purple,
            isFilled: false,
            visualState: MentalMapNodeVisualState.pending,
            onTap: () => opened++,
          )
        ],
      )),
    )));
    final card = find.byKey(const ValueKey('mental-map-personality'));
    await tester.ensureVisible(card);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Personalidade'), findsOneWidget);
    expect(find.text('Versão futura'), findsNothing);
    await tester.tap(card);
    expect(opened, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('MentalMapRadialHub keeps radial layout on wider screens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 760,
            child: MentalMapRadialHub(center: center, nodes: nodes),
          ),
        ),
      ),
    );

    expect(
        find.byKey(const ValueKey('mental-map-radial-layout')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('mental-map-connected-list')), findsNothing);
  });

  testWidgets('MentalMapNodeDetailSheet shows items and data source',
      (tester) async {
    const detail = MentalMapNodeDetail(
      id: 'schemas',
      title: 'Esquemas',
      items: ['Abandono 5.80'],
      dataSource: 'YSQ - última resposta concluída',
      ctaLabel: 'Abrir dashboard clínico',
      lastUpdatedAt: null,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return FilledButton(
                onPressed: () => showMentalMapNodeDetailSheet(
                  context: context,
                  detail: detail,
                  onPrimaryTap: () {},
                ),
                child: const Text('Abrir'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Esquemas'), findsOneWidget);
    expect(find.text('Origem dos dados'), findsOneWidget);
    expect(find.text('YSQ - última resposta concluída'), findsOneWidget);
    expect(find.text('Abandono 5.80'), findsOneWidget);
    expect(find.text('Abrir dashboard clínico'), findsOneWidget);
  });
}
