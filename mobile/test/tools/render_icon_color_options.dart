// Compara as formas de ter ícone colorido no nodo do mapa mental:
//
//   1. Monocromático  — o que existe hoje (glifo outlined na cor do nodo)
//   2. Emoji          — o que aparece no print de referência
//   3. Duotone        — glifo preenchido em tom claro + contorno em tom forte
//   4. Duotone 2 cores— preenchido numa matiz, contorno noutra
//
//   flutter test test/tools/render_icon_color_options.dart
//
// Saída: build/icon_color_options.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';

const _rows = <({
  String concept,
  Color color,
  Color second,
  IconData outlined,
  IconData filled,
  String emoji
})>[
  (
    concept: 'Esquemas',
    color: AppColors.blue,
    second: AppColors.purple,
    outlined: Icons.psychology_outlined,
    filled: Icons.psychology,
    emoji: '\u{1F9E0}',
  ),
  (
    concept: 'Modos',
    color: AppColors.purple,
    second: AppColors.cyan,
    outlined: Icons.self_improvement_outlined,
    filled: Icons.self_improvement,
    emoji: '\u{1F9D8}',
  ),
  (
    concept: 'Problemas',
    color: AppColors.warning,
    second: AppColors.error,
    outlined: Icons.report_problem_outlined,
    filled: Icons.report_problem,
    emoji: '\u{26A0}\u{FE0F}',
  ),
  (
    concept: 'Apego',
    color: AppColors.turquoise,
    second: AppColors.error,
    outlined: Icons.favorite_border,
    filled: Icons.favorite,
    emoji: '\u{2764}\u{FE0F}',
  ),
  (
    concept: 'Enfrentamento',
    color: AppColors.cyan,
    second: AppColors.blue,
    outlined: Icons.shield_outlined,
    filled: Icons.shield,
    emoji: '\u{1F6E1}\u{FE0F}',
  ),
  (
    concept: 'Objetivos',
    color: AppColors.turquoise,
    second: AppColors.success,
    outlined: Icons.flag_outlined,
    filled: Icons.flag,
    emoji: '\u{1F6A9}',
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
    // Fonte de emoji do próprio Windows, só para a coluna 2 mostrar como
    // ficaria. Em produção quem fornece o desenho é o sistema do usuário —
    // e é justamente por isso que o resultado muda de aparelho para aparelho.
    await ui.loadFontFromList(
      File(r'C:\Windows\Fonts\seguiemj.ttf').readAsBytesSync(),
      fontFamily: 'SysEmoji',
    );
  });

  testWidgets('opções de ícone colorido', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
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
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final row in _rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          const SizedBox(width: 150),
                          _Cell(child: _mono(row)),
                          _Cell(child: _emoji(row)),
                          _Cell(child: _duotone(row, twoHue: false)),
                          _Cell(child: _duotone(row, twoHue: true)),
                        ],
                      ),
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
    File('build/icon_color_options.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('Gerado em build/icon_color_options.png');
  });
}

/// Círculo idêntico ao do nodo real: 44px, borda 2.2, fundo a 14%.
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

Widget _mono(
    ({
      String concept,
      Color color,
      Color second,
      IconData outlined,
      IconData filled,
      String emoji
    }) row) {
  return _ring(row.color, Icon(row.outlined, size: 22, color: row.color));
}

Widget _emoji(
    ({
      String concept,
      Color color,
      Color second,
      IconData outlined,
      IconData filled,
      String emoji
    }) row) {
  return _ring(
    row.color,
    Text(
      row.emoji,
      style: const TextStyle(fontSize: 20, fontFamily: 'SysEmoji'),
    ),
  );
}

/// Duas camadas do mesmo desenho: a versão preenchida bem clara por baixo,
/// o contorno forte por cima. Dá volume sem sair do Material Icons.
Widget _duotone(
  ({
    String concept,
    Color color,
    Color second,
    IconData outlined,
    IconData filled,
    String emoji
  }) row, {
  required bool twoHue,
}) {
  final fillColor = twoHue ? row.second : row.color;
  return _ring(
    row.color,
    Stack(
      alignment: Alignment.center,
      children: [
        Icon(row.filled, size: 22, color: fillColor.withValues(alpha: 0.38)),
        Icon(row.outlined, size: 22, color: row.color),
      ],
    ),
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 170, child: Center(child: child));
  }
}
