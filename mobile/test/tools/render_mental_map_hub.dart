// Captura o "hub" do mapa mental (orbit mobile) em PNG para inspeção
// visual — não é um teste de verdade, só grava a imagem.
//
//   flutter test test/tools/render_mental_map_hub.dart
//
// Saída: build/mental_map_hub.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map.dart';
import 'package:terapia_esquema/features/mental_map/presentation/mental_map_node_state.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_widgets.dart';

// Mesmos ícones reais usados em patient_mental_map_page.dart#_buildHubNodes.
// A contagem de `items` é o que define a densidade do fluxo de cada fibra.
final _nodes = [
  const MentalMapHubNodeData(
    id: 'schemas',
    title: 'Esquemas',
    subtitle: '3 esquemas ativos',
    items: ['Defectividade', 'Abandono', 'Padrões inflexíveis'],
    emptyLabel: 'Sem esquemas',
    icon: Icons.psychology_outlined,
    accentColor: AppColors.blue,
    isFilled: true,
    visualState: MentalMapNodeVisualState.filled,
  ),
  const MentalMapHubNodeData(
    id: 'modes',
    title: 'Modos',
    subtitle: '2 modos ativos',
    items: ['Criança vulnerável', 'Protetor desligado'],
    emptyLabel: 'Sem modos',
    icon: Icons.self_improvement_outlined,
    accentColor: AppColors.purple,
    isFilled: true,
    visualState: MentalMapNodeVisualState.filled,
  ),
  const MentalMapHubNodeData(
    id: 'problems',
    title: 'Problemas',
    subtitle: '1 problema ativo',
    items: ['Ansiedade no trabalho'],
    emptyLabel: 'Sem problemas',
    icon: Icons.report_problem_outlined,
    accentColor: AppColors.warning,
    isFilled: true,
    visualState: MentalMapNodeVisualState.filled,
  ),
  const MentalMapHubNodeData(
    id: 'attachment',
    title: 'Apego',
    subtitle: 'Ambivalente',
    items: ['Vínculo materno ambivalente'],
    emptyLabel: 'Sem dados de apego',
    icon: Icons.favorite_border,
    accentColor: AppColors.turquoise,
    isFilled: true,
    visualState: MentalMapNodeVisualState.filled,
  ),
  const MentalMapHubNodeData(
    id: 'goals',
    title: 'Objetivos',
    subtitle: 'Sem objetivos ativos',
    items: [],
    emptyLabel: 'Sem objetivos ativos',
    icon: Icons.flag_outlined,
    accentColor: AppColors.turquoise,
    isFilled: false,
    visualState: MentalMapNodeVisualState.pending,
  ),
  const MentalMapHubNodeData(
    id: 'coping',
    title: 'Enfrentamento',
    subtitle: 'Sem dados',
    items: [],
    emptyLabel: 'Sem dados de enfrentamento',
    icon: Icons.shield_outlined,
    accentColor: AppColors.blue,
    isFilled: false,
    visualState: MentalMapNodeVisualState.pending,
  ),
];

const _center = MentalCaseMapCenter(
  patientName: 'Roberto',
  activeProblemsLabel: 'Sem problemas',
  activeGoalsLabel: 'Sem objetivos ativos',
  lastCheckInLabel: 'Sem check-in',
);

void main() {
  setUpAll(() async {
    // Sem isto, o ambiente de teste substitui qualquer glifo por um
    // quadrado genérico — e um quadrado é simétrico, então nunca mostraria
    // o desalinhamento óptico que só existe no glifo real da fonte.
    final fontBytes = File(
      r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ).readAsBytesSync();
    await ui.loadFontFromList(fontBytes, fontFamily: 'MaterialIcons');
  });

  testWidgets('captura o hub do mapa mental', (tester) async {
    // Largura < 600 força o branch mobile (_MentalMapMobileOrbit).
    tester.view.physicalSize = const Size(1080, 1600);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFE9EEF9),
          body: Center(
            child: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: RepaintBoundary(
                  key: const Key('capture'),
                  child: MentalMapVisualHub(
                    caseMap: const MentalCaseMap(
                      center: _center,
                      primaryNodes: [],
                      contextNodes: [],
                    ),
                    nodes: _nodes,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // O fluxo repete indefinidamente, então pumpAndSettle travaria. Avança
    // um pouco para as partículas saírem da posição inicial e mostrarem a
    // diferença de densidade entre as fibras.
    await tester.pump(const Duration(milliseconds: 420));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/mental_map_hub.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('Gerado em build/mental_map_hub.png');
  });
}
