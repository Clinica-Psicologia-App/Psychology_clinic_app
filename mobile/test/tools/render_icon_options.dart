// Folha de comparação dos ícones candidatos do mapa mental, desenhados no
// mesmo círculo e no mesmo tamanho do nodo real — não é teste, só grava a
// imagem para escolha visual.
//
//   flutter test test/tools/render_icon_options.dart
//
// Saída: build/icon_options.png  e  build/icon_options_grid.png
//
// O segundo arquivo desenha cada glifo isolado sobre uma cruz que marca o
// centro exato da caixa. É com ele que dá para medir, por pixel, quanto a
// "tinta" de cada ícone pende para um lado — o desvio que obrigou
// flag_outlined e shield_outlined a levarem ajuste manual no widget.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';

const _rows = <({String concept, Color color, List<(String, IconData)> icons})>[
  (
    concept: 'Esquemas',
    color: AppColors.blue,
    icons: [
      ('psychology (atual)', Icons.psychology_outlined),
      ('account_tree', Icons.account_tree_outlined),
      ('layers', Icons.layers_outlined),
      ('hub', Icons.hub_outlined),
    ],
  ),
  (
    concept: 'Modos',
    color: AppColors.purple,
    icons: [
      ('self_improvement (atual)', Icons.self_improvement_outlined),
      ('theater_comedy', Icons.theater_comedy_outlined),
      ('switch_account', Icons.switch_account_outlined),
      ('face', Icons.face_outlined),
    ],
  ),
  (
    concept: 'Problemas',
    color: AppColors.warning,
    icons: [
      ('report_problem (atual)', Icons.report_problem_outlined),
      ('error_outline', Icons.error_outline),
      ('warning_amber', Icons.warning_amber_outlined),
      ('healing', Icons.healing_outlined),
    ],
  ),
  (
    concept: 'Apego',
    color: AppColors.turquoise,
    icons: [
      ('favorite_border (atual)', Icons.favorite_border),
      ('diversity_1', Icons.diversity_1_outlined),
      ('volunteer_activism', Icons.volunteer_activism_outlined),
      ('link', Icons.link_outlined),
    ],
  ),
  (
    concept: 'Enfrentamento',
    color: AppColors.cyan,
    icons: [
      ('shield (atual, torto)', Icons.shield_outlined),
      ('security', Icons.security_outlined),
      ('health_and_safety', Icons.health_and_safety_outlined),
      ('umbrella', Icons.umbrella_outlined),
    ],
  ),
  (
    concept: 'Objetivos',
    color: AppColors.turquoise,
    icons: [
      ('flag (atual, torto)', Icons.flag_outlined),
      ('track_changes', Icons.track_changes),
      ('my_location', Icons.my_location_outlined),
      ('rocket_launch', Icons.rocket_launch_outlined),
    ],
  ),
  (
    concept: 'Parental',
    color: AppColors.purple,
    icons: [
      ('family_restroom (atual)', Icons.family_restroom_outlined),
      ('escalator_warning', Icons.escalator_warning_outlined),
      ('child_care', Icons.child_care_outlined),
      ('diversity_1', Icons.diversity_1_outlined),
    ],
  ),
  (
    concept: 'História',
    color: AppColors.cyan,
    icons: [
      ('timeline (atual)', Icons.timeline_outlined),
      ('history', Icons.history_outlined),
      ('auto_stories', Icons.auto_stories_outlined),
      ('schedule', Icons.schedule_outlined),
    ],
  ),
];

/// Ordem achatada dos glifos, usada pela grade de medição.
final _allIcons = [
  for (final row in _rows)
    for (final icon in row.icons) (row.concept, icon.$1, icon.$2),
];

void main() {
  setUpAll(() async {
    final fontBytes = File(
      r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
    ).readAsBytesSync();
    await ui.loadFontFromList(fontBytes, fontFamily: 'MaterialIcons');
  });

  testWidgets('folha de comparação dos ícones', (tester) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFE9EEF9),
          body: RepaintBoundary(
            key: const Key('sheet'),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in _rows) _ConceptRow(row: row),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    await _capture(tester, const Key('sheet'), 'build/icon_options.png');
  });

  testWidgets('grade de medição do centramento', (tester) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: RepaintBoundary(
            key: const Key('grid'),
            child: Wrap(
              children: [
                for (final entry in _allIcons)
                  // Glifo grande de propósito: o desvio é medido como
                  // fração do tamanho do ícone, então quanto maior o
                  // render, mais casas decimais confiáveis. O script
                  // depois converte para o tamanho usado no app.
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Center(
                      child: Icon(entry.$3, size: 96, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    await _capture(tester, const Key('grid'), 'build/icon_options_grid.png');

    // ignore: avoid_print
    print('GLIFOS=${_allIcons.map((e) => '${e.$1}|${e.$2}').join(';')}');
  });
}

Future<void> _capture(WidgetTester tester, Key key, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await boundary.toImage(pixelRatio: 2.0);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
  // ignore: avoid_print
  print('Gerado em $path');
}

class _ConceptRow extends StatelessWidget {
  const _ConceptRow({required this.row});

  final ({String concept, Color color, List<(String, IconData)> icons}) row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              row.concept,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.navy,
              ),
            ),
          ),
          for (final (label, icon) in row.icons)
            Container(
              width: 150,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Mesmo círculo do nodo real: 44px, borda 2.2, fundo 14%.
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: row.color.withValues(alpha: 0.14),
                      border: Border.all(color: row.color, width: 2.2),
                    ),
                    child: Icon(icon, size: 22, color: row.color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
