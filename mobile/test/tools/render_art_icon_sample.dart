// Folha completa: cada conceito do mapa mental em mono / emoji / desenhado,
// no círculo real do nodo, mais uma faixa ampliada dos desenhos a 96px.
//
//   flutter test test/tools/render_art_icon_sample.dart
//
// Saída: build/art_icon_sample.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_art_icon.dart';

const _rows = <({
  String concept,
  Color color,
  IconData mono,
  String emoji,
  MentalMapArt art,
})>[
  (
    concept: 'Esquemas',
    color: AppColors.blue,
    mono: Icons.psychology_outlined,
    emoji: '\u{1F9E0}',
    art: MentalMapArt.schemas,
  ),
  (
    concept: 'Modos',
    color: AppColors.purple,
    mono: Icons.self_improvement_outlined,
    emoji: '\u{1F9D8}',
    art: MentalMapArt.modes,
  ),
  (
    concept: 'Problemas',
    color: AppColors.warning,
    mono: Icons.report_problem_outlined,
    emoji: '\u{26A0}\u{FE0F}',
    art: MentalMapArt.problems,
  ),
  (
    concept: 'Apego',
    color: AppColors.turquoise,
    mono: Icons.favorite_border,
    emoji: '\u{2764}\u{FE0F}',
    art: MentalMapArt.attachment,
  ),
  (
    concept: 'Enfrentamento',
    color: AppColors.cyan,
    mono: Icons.shield_outlined,
    emoji: '\u{1F6E1}\u{FE0F}',
    art: MentalMapArt.coping,
  ),
  (
    concept: 'Parental',
    color: AppColors.purple,
    mono: Icons.family_restroom_outlined,
    emoji: '\u{1F46A}',
    art: MentalMapArt.parental,
  ),
  (
    concept: 'Objetivos',
    color: AppColors.turquoise,
    mono: Icons.flag_outlined,
    emoji: '\u{1F3AF}',
    art: MentalMapArt.goals,
  ),
  (
    concept: 'História',
    color: AppColors.cyan,
    mono: Icons.timeline_outlined,
    emoji: '\u{1F551}',
    art: MentalMapArt.history,
  ),
];

void main() {
  setUpAll(() async {
    await ui.loadFontFromList(
      File(
        r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf',
      ).readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    await ui.loadFontFromList(
      File(r'C:\Windows\Fonts\seguiemj.ttf').readAsBytesSync(),
      fontFamily: 'SysEmoji',
    );
  });

  testWidgets('folha completa dos ícones desenhados', (tester) async {
    tester.view.physicalSize = const Size(1000, 1900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFE9EEF9),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: RepaintBoundary(
              key: const Key('sheet'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final row in _rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SampleRow(row: row),
                    ),
                  const SizedBox(height: 20),
                  // Faixa ampliada: acabamento dos desenhos a 96px.
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (final row in _rows) _Big(art: row.art),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 60));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('sheet')));
    final image = await boundary.toImage(pixelRatio: 2.0);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File('build/art_icon_sample.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('Gerado em build/art_icon_sample.png');
  });
}

Widget _ring(Color color, Widget child) {
  return Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.14),
      border: Border.all(color: color, width: 2.2),
    ),
    child: Center(child: child),
  );
}

class _SampleRow extends StatelessWidget {
  const _SampleRow({required this.row});

  final ({
    String concept,
    Color color,
    IconData mono,
    String emoji,
    MentalMapArt art,
  }) row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            row.concept,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.navy,
            ),
          ),
        ),
        SizedBox(
          width: 130,
          child: Center(
            child: _ring(row.color, Icon(row.mono, size: 22, color: row.color)),
          ),
        ),
        SizedBox(
          width: 130,
          child: Center(
            child: _ring(
              row.color,
              Text(row.emoji,
                  style: const TextStyle(fontSize: 20, fontFamily: 'SysEmoji')),
            ),
          ),
        ),
        SizedBox(
          width: 130,
          child: Center(
            child: _ring(row.color, MentalMapArtIcon(art: row.art, size: 22)),
          ),
        ),
      ],
    );
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.art});

  final MentalMapArt art;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: MentalMapArtIcon(art: art, size: 84),
    );
  }
}
