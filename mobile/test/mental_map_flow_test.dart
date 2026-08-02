import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map.dart';
import 'package:terapia_esquema/features/mental_map/presentation/mental_map_node_state.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_widgets.dart';

/// O hub do mapa mental passou a mostrar as áreas ativas com um fluxo de
/// partículas correndo pela fibra até o núcleo, e a densidade desse fluxo é
/// a quantidade de registros. Como isso é a informação (e não enfeite), as
/// regras que a sustentam precisam ficar travadas.
void main() {
  group('densidade do fluxo', () {
    test('mais registros deixam o fluxo mais denso', () {
      // Espaçamento menor = partículas mais juntas = fluxo mais denso.
      expect(flowSpacingFor(3), lessThan(flowSpacingFor(2)));
      expect(flowSpacingFor(2), lessThan(flowSpacingFor(1)));
      expect(flowSpacingFor(1), lessThan(flowSpacingFor(0)));
    });

    test('acima de 3 registros a densidade satura', () {
      // Sem o teto, uma área com 20 itens viraria uma linha contínua e
      // perderia a leitura de "partículas".
      expect(flowSpacingFor(9), flowSpacingFor(3));
      expect(flowSpacingFor(50), flowSpacingFor(3));
    });

    test('todo espaçamento divide a distância do ciclo', () {
      // O laço do fluxo só fecha sem salto se o avanço por ciclo for um
      // múltiplo inteiro do espaçamento. Se algum dia alguém acrescentar
      // um valor que não divide, a animação passa a "pular" a cada volta.
      for (final count in [0, 1, 2, 3, 7]) {
        final spacing = flowSpacingFor(count);
        expect(
          flowCycleDistance % spacing,
          0,
          reason: '$spacing não divide $flowCycleDistance',
        );
      }
    });
  });

  group('hub do mapa mental', () {
    testWidgets('renderiza sem erro de layout e mantém as seis áreas',
        (tester) async {
      await _pumpHub(tester);

      expect(tester.takeException(), isNull);
      for (final title in const [
        'Esquemas',
        'Modos',
        'Problemas',
        'Apego',
        'Objetivos',
        'Enfrentamento',
      ]) {
        expect(find.text(title), findsOneWidget, reason: 'faltou $title');
      }
    });

    // O núcleo encolheu para abrir percurso para a fibra; as três leituras
    // que moravam dentro dele saíram para fora do círculo. Elas mudaram de
    // lugar — se sumirem de vez, é regressão.
    testWidgets('as leituras do núcleo continuam na tela, agora fora dele',
        (tester) async {
      await _pumpHub(tester);

      expect(find.text('Roberto'), findsOneWidget);
      expect(find.textContaining('Sem problemas'), findsOneWidget);
      expect(find.textContaining('Sem objetivos ativos'), findsOneWidget);
      expect(find.textContaining('Sem check-in'), findsOneWidget);
    });

    testWidgets('o núcleo resume quantas áreas estão ativas', (tester) async {
      await _pumpHub(tester);

      expect(find.text('4 áreas ativas'), findsOneWidget);
    });

    testWidgets('singular quando só uma área tem registro', (tester) async {
      await _pumpHub(tester, nodes: [_node('schemas', 'Esquemas', 1)]);

      expect(find.text('1 área ativa'), findsOneWidget);
    });

    // Sem isto o fluxo continuaria correndo para quem pediu para reduzir
    // movimento no sistema.
    testWidgets('com "reduzir movimento" a tela ainda monta e não anima',
        (tester) async {
      await _pumpHub(tester, disableAnimations: true);

      expect(tester.takeException(), isNull);
      expect(find.text('Roberto'), findsOneWidget);
      // Se algum controller tivesse ficado repetindo, pumpAndSettle
      // estouraria o tempo em vez de assentar.
      await tester.pumpAndSettle();
    });
  });
}

MentalMapHubNodeData _node(String id, String title, int itemCount) {
  return MentalMapHubNodeData(
    id: id,
    title: title,
    subtitle: '$itemCount registros',
    items: List.generate(itemCount, (i) => 'Item $i'),
    emptyLabel: 'Sem registros',
    icon: Icons.psychology_outlined,
    accentColor: AppColors.blue,
    isFilled: itemCount > 0,
    visualState: itemCount > 0
        ? MentalMapNodeVisualState.filled
        : MentalMapNodeVisualState.pending,
  );
}

Future<void> _pumpHub(
  WidgetTester tester, {
  List<MentalMapHubNodeData>? nodes,
  bool disableAnimations = false,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  final hubNodes = nodes ??
      [
        _node('schemas', 'Esquemas', 3),
        _node('modes', 'Modos', 2),
        _node('problems', 'Problemas', 1),
        _node('attachment', 'Apego', 1),
        _node('goals', 'Objetivos', 0),
        _node('coping', 'Enfrentamento', 0),
      ];

  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 800),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: SingleChildScrollView(
            child: MentalMapVisualHub(
              caseMap: const MentalCaseMap(
                center: MentalCaseMapCenter(
                  patientName: 'Roberto',
                  activeProblemsLabel: 'Sem problemas',
                  activeGoalsLabel: 'Sem objetivos ativos',
                  lastCheckInLabel: 'Sem check-in',
                ),
                primaryNodes: [],
                contextNodes: [],
              ),
              nodes: hubNodes,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}
