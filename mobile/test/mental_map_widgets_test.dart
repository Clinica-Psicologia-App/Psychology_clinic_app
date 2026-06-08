import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_node_detail.dart';
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
    ),
  ];

  testWidgets('MentalMapRadialHub uses grid fallback on small screens',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            child: MentalMapRadialHub(center: center, nodes: nodes),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('mental-map-grid-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('mental-map-radial-layout')), findsNothing);
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

    expect(find.byKey(const ValueKey('mental-map-radial-layout')), findsOneWidget);
    expect(find.byKey(const ValueKey('mental-map-grid-layout')), findsNothing);
  });

  testWidgets('MentalMapNodeDetailSheet shows items and data source',
      (tester) async {
    const detail = MentalMapNodeDetail(
      id: 'schemas',
      title: 'Esquemas',
      items: ['Abandono 5.80'],
      dataSource: 'YSQ — última resposta concluída',
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
    expect(find.text('YSQ — última resposta concluída'), findsOneWidget);
    expect(find.text('Abandono 5.80'), findsOneWidget);
    expect(find.text('Abrir dashboard clínico'), findsOneWidget);
  });
}
