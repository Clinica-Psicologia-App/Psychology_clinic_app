// Gera uma folha de amostras do avatar em PNG, para inspeção visual.
//
// Não é um teste de verdade — é uma ferramenta. Fica em test/ porque precisa do
// binding do flutter_test para acessar o canvas.
//
//   flutter test test/tools/render_avatar_sheet.dart
//
// Saída: build/avatar_sheet.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/presentation/widgets/avatar_artwork.dart';

const _cell = 120.0;
const _cols = 6;

void main() {
  test('gera folha de amostras do avatar', () async {
    final samples = <(String, AvatarConfig)>[
      ('padrão', const AvatarConfig()),
      (
        'longo cacheado',
        const AvatarConfig(
          skinTone: AvatarSkinTone.brown,
          hairStyle: AvatarHairStyle.longCurly,
          hairColor: AvatarHairColor.black,
          eyeStyle: AvatarEyeStyle.wide,
          outfit: AvatarOutfit.blazer,
          outfitColor: AvatarPaletteColor.purple,
          backgroundColor: AvatarPaletteColor.amber,
        )
      ),
      (
        'barba cheia',
        const AvatarConfig(
          skinTone: AvatarSkinTone.light,
          hairStyle: AvatarHairStyle.short,
          hairColor: AvatarHairColor.auburn,
          facialHair: AvatarFacialHair.fullBeard,
          outfit: AvatarOutfit.hoodie,
          outfitColor: AvatarPaletteColor.navy,
          backgroundColor: AvatarPaletteColor.cyan,
        )
      ),
      (
        'óculos + coque',
        const AvatarConfig(
          skinTone: AvatarSkinTone.porcelain,
          hairStyle: AvatarHairStyle.bun,
          hairColor: AvatarHairColor.blonde,
          glasses: AvatarGlasses.rounded,
          eyeStyle: AvatarEyeStyle.happy,
          outfit: AvatarOutfit.collared,
          outfitColor: AvatarPaletteColor.rose,
          backgroundColor: AvatarPaletteColor.slate,
        )
      ),
      (
        'afro',
        const AvatarConfig(
          skinTone: AvatarSkinTone.deep,
          hairStyle: AvatarHairStyle.afro,
          hairColor: AvatarHairColor.black,
          eyebrowStyle: AvatarEyebrowStyle.thick,
          outfit: AvatarOutfit.vNeck,
          outfitColor: AvatarPaletteColor.turquoise,
          backgroundColor: AvatarPaletteColor.navy,
        )
      ),
      (
        'sem cabelo + cavanhaque',
        const AvatarConfig(
          skinTone: AvatarSkinTone.tan,
          hairStyle: AvatarHairStyle.none,
          facialHair: AvatarFacialHair.goatee,
          hairColor: AvatarHairColor.gray,
          glasses: AvatarGlasses.square,
          outfitColor: AvatarPaletteColor.slate,
          backgroundColor: AvatarPaletteColor.blue,
        )
      ),
    ];

    // Segunda fileira: um estilo de cabelo por célula, para conferir todos.
    for (final style in AvatarHairStyle.values) {
      samples.add((
        style.key,
        AvatarConfig(
          hairStyle: style,
          skinTone: AvatarSkinTone.medium,
          hairColor: AvatarHairColor.darkBrown,
          backgroundColor: AvatarPaletteColor.slate,
        ),
      ));
    }

    // Terceira: pelos faciais e óculos.
    for (final facial in AvatarFacialHair.values) {
      samples.add((
        facial.key,
        AvatarConfig(
          facialHair: facial,
          skinTone: AvatarSkinTone.light,
          backgroundColor: AvatarPaletteColor.cyan,
        ),
      ));
    }
    for (final glasses in AvatarGlasses.values) {
      samples.add((
        glasses.key,
        AvatarConfig(
          glasses: glasses,
          skinTone: AvatarSkinTone.tan,
          backgroundColor: AvatarPaletteColor.amber,
        ),
      ));
    }
    for (final outfit in AvatarOutfit.values) {
      samples.add((
        outfit.key,
        AvatarConfig(
          outfit: outfit,
          outfitColor: AvatarPaletteColor.purple,
          backgroundColor: AvatarPaletteColor.turquoise,
        ),
      ));
    }
    for (final eye in AvatarEyeStyle.values) {
      samples.add((
        eye.key,
        AvatarConfig(eyeStyle: eye, backgroundColor: AvatarPaletteColor.rose),
      ));
    }

    final rows = (samples.length / _cols).ceil();
    final width = _cols * _cell;
    final height = rows * (_cell + 18);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, height),
      Paint()..color = const Color(0xFFE9EEF9),
    );

    for (var i = 0; i < samples.length; i++) {
      final (_, config) = samples[i];
      final col = i % _cols;
      final row = i ~/ _cols;
      final dx = col * _cell;
      final dy = row * (_cell + 18);

      canvas.save();
      canvas.translate(dx + 10, dy + 6);
      // Recorte circular, como o avatar aparece no app.
      canvas.clipPath(
        Path()..addOval(Rect.fromLTWH(0, 0, _cell - 20, _cell - 20)),
      );
      AvatarPainter(config).paint(canvas, Size.square(_cell - 20));
      canvas.restore();

      // Sem rótulo: o ambiente de teste não carrega fontes, e o texto sairia
      // como retângulos pretos. A ordem das amostras está no código acima.
    }

    final image =
        await recorder.endRecording().toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final out = File('build/avatar_sheet.png');
    out.parent.createSync(recursive: true);
    out.writeAsBytesSync(bytes!.buffer.asUint8List());

    // ignore: avoid_print
    print('Folha gerada em ${out.absolute.path}');
    expect(out.existsSync(), isTrue);
  });
}
