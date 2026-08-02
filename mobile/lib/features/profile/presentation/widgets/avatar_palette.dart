import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/avatar_config.dart';

/// Tradução das opções do avatar em cores concretas.
///
/// O domínio guarda apenas nomes ([AvatarPaletteColor.turquoise], …) para
/// permanecer Dart puro e para que um avatar salvo hoje continue legível se a
/// paleta do Design System mudar de tom amanhã. A ponte entre nome e cor vive
/// aqui, na apresentação, e é o único lugar que conhece valores hex.
abstract final class AvatarPalette {
  /// Cor de acento escolhida pelo usuário (roupa e fundo).
  static Color of(AvatarPaletteColor color) {
    return switch (color) {
      AvatarPaletteColor.turquoise => AppColors.turquoise,
      AvatarPaletteColor.cyan => AppColors.cyan,
      AvatarPaletteColor.blue => AppColors.blue,
      AvatarPaletteColor.purple => AppColors.purple,
      AvatarPaletteColor.navy => AppColors.navy,
      AvatarPaletteColor.rose => const Color(0xFFE05A79),
      AvatarPaletteColor.amber => const Color(0xFFE0912B),
      AvatarPaletteColor.slate => const Color(0xFF64748B),
    };
  }

  /// Versão suave da paleta, para o fundo do retrato.
  ///
  /// O fundo usa um pastel dessaturado em vez da cor cheia da marca: com a cor
  /// saturada atrás, o rosto perde o protagonismo e o conjunto fica infantil.
  /// A cor cheia continua valendo para a roupa, que precisa de peso.
  static Color background(AvatarPaletteColor color) {
    return switch (color) {
      AvatarPaletteColor.turquoise => const Color(0xFFCFE7E2),
      AvatarPaletteColor.cyan => const Color(0xFFD3E6F0),
      AvatarPaletteColor.blue => const Color(0xFFD6E1F2),
      AvatarPaletteColor.purple => const Color(0xFFE0DCF0),
      AvatarPaletteColor.navy => const Color(0xFFCBD3E0),
      AvatarPaletteColor.rose => const Color(0xFFF2DEDF),
      AvatarPaletteColor.amber => const Color(0xFFF0E4CE),
      AvatarPaletteColor.slate => const Color(0xFFDFE3E8),
    };
  }

  static String label(AvatarPaletteColor color) {
    return switch (color) {
      AvatarPaletteColor.turquoise => 'Turquesa',
      AvatarPaletteColor.cyan => 'Ciano',
      AvatarPaletteColor.blue => 'Azul',
      AvatarPaletteColor.purple => 'Roxo',
      AvatarPaletteColor.navy => 'Marinho',
      AvatarPaletteColor.rose => 'Rosa',
      AvatarPaletteColor.amber => 'Âmbar',
      AvatarPaletteColor.slate => 'Cinza',
    };
  }

  /// Tons de pele. A escala é ampla de propósito: a spec pede opções
  /// inclusivas, e nenhuma característica é restringida por papel ou gênero.
  static Color skin(AvatarSkinTone tone) {
    return switch (tone) {
      AvatarSkinTone.porcelain => const Color(0xFFF7DFD0),
      AvatarSkinTone.light => const Color(0xFFEFC9AC),
      AvatarSkinTone.olive => const Color(0xFFE0B891),
      AvatarSkinTone.medium => const Color(0xFFD9A576),
      AvatarSkinTone.tan => const Color(0xFFB77E4F),
      AvatarSkinTone.brown => const Color(0xFF8A5533),
      AvatarSkinTone.deep => const Color(0xFF5C3620),
      AvatarSkinTone.espresso => const Color(0xFF3E2416),
    };
  }

  static String skinLabel(AvatarSkinTone tone) {
    return switch (tone) {
      AvatarSkinTone.porcelain => 'Porcelana',
      AvatarSkinTone.light => 'Clara',
      AvatarSkinTone.olive => 'Oliva',
      AvatarSkinTone.medium => 'Média',
      AvatarSkinTone.tan => 'Morena',
      AvatarSkinTone.brown => 'Castanha',
      AvatarSkinTone.deep => 'Escura',
      AvatarSkinTone.espresso => 'Bem escura',
    };
  }

  static Color hair(AvatarHairColor color) {
    return switch (color) {
      AvatarHairColor.black => const Color(0xFF1B1B1F),
      AvatarHairColor.darkBrown => const Color(0xFF3B2417),
      AvatarHairColor.brown => const Color(0xFF6A4227),
      AvatarHairColor.lightBrown => const Color(0xFF98653C),
      AvatarHairColor.blonde => const Color(0xFFD9AE63),
      AvatarHairColor.auburn => const Color(0xFF8C3A24),
      AvatarHairColor.gray => const Color(0xFF9AA0A6),
      AvatarHairColor.white => const Color(0xFFE8E8E8),
    };
  }

  static String hairLabel(AvatarHairColor color) {
    return switch (color) {
      AvatarHairColor.black => 'Preto',
      AvatarHairColor.darkBrown => 'Castanho escuro',
      AvatarHairColor.brown => 'Castanho',
      AvatarHairColor.lightBrown => 'Castanho claro',
      AvatarHairColor.blonde => 'Loiro',
      AvatarHairColor.auburn => 'Ruivo',
      AvatarHairColor.gray => 'Grisalho',
      AvatarHairColor.white => 'Branco',
    };
  }

  // ── Rótulos das demais opções ──────────────────────────────────────────────

  static String hairStyleLabel(AvatarHairStyle style) {
    return switch (style) {
      AvatarHairStyle.none => 'Sem cabelo',
      AvatarHairStyle.buzz => 'Raspado',
      AvatarHairStyle.pixie => 'Pixie',
      AvatarHairStyle.short => 'Curto',
      AvatarHairStyle.shortCurly => 'Curto cacheado',
      AvatarHairStyle.undercut => 'Undercut',
      AvatarHairStyle.slickBack => 'Penteado para trás',
      AvatarHairStyle.medium => 'Chanel',
      AvatarHairStyle.wavy => 'Ondulado',
      AvatarHairStyle.long => 'Longo',
      AvatarHairStyle.longCurly => 'Longo cacheado',
      AvatarHairStyle.coils => 'Cachos definidos',
      AvatarHairStyle.braids => 'Tranças',
      AvatarHairStyle.bun => 'Coque',
      AvatarHairStyle.ponytail => 'Rabo de cavalo',
      AvatarHairStyle.afro => 'Black power',
      AvatarHairStyle.hijab => 'Hijab',
    };
  }

  static String eyeLabel(AvatarEyeStyle style) {
    return switch (style) {
      AvatarEyeStyle.round => 'Redondos',
      AvatarEyeStyle.almond => 'Amendoados',
      AvatarEyeStyle.narrow => 'Estreitos',
      AvatarEyeStyle.wide => 'Grandes',
      AvatarEyeStyle.happy => 'Sorridentes',
    };
  }

  static String eyebrowLabel(AvatarEyebrowStyle style) {
    return switch (style) {
      AvatarEyebrowStyle.straight => 'Retas',
      AvatarEyebrowStyle.arched => 'Arqueadas',
      AvatarEyebrowStyle.thick => 'Grossas',
      AvatarEyebrowStyle.thin => 'Finas',
      AvatarEyebrowStyle.raised => 'Erguidas',
    };
  }

  static String facialHairLabel(AvatarFacialHair style) {
    return switch (style) {
      AvatarFacialHair.none => 'Sem barba',
      AvatarFacialHair.stubble => 'Por fazer',
      AvatarFacialHair.mustache => 'Bigode',
      AvatarFacialHair.goatee => 'Cavanhaque',
      AvatarFacialHair.shortBeard => 'Barba curta',
      AvatarFacialHair.fullBeard => 'Barba cheia',
    };
  }

  static String glassesLabel(AvatarGlasses style) {
    return switch (style) {
      AvatarGlasses.none => 'Sem óculos',
      AvatarGlasses.rounded => 'Redondos',
      AvatarGlasses.square => 'Quadrados',
      AvatarGlasses.catEye => 'Gatinho',
      AvatarGlasses.aviator => 'Aviador',
      AvatarGlasses.halfRim => 'Meia armação',
    };
  }

  static String faceShapeLabel(AvatarFaceShape shape) {
    return switch (shape) {
      AvatarFaceShape.oval => 'Oval',
      AvatarFaceShape.round => 'Redondo',
      AvatarFaceShape.square => 'Anguloso',
    };
  }

  static String noseLabel(AvatarNose nose) {
    return switch (nose) {
      AvatarNose.soft => 'Suave',
      AvatarNose.straight => 'Reto',
      AvatarNose.wide => 'Largo',
    };
  }

  static String mouthLabel(AvatarMouth mouth) {
    return switch (mouth) {
      AvatarMouth.softSmile => 'Sorriso leve',
      AvatarMouth.smile => 'Sorriso',
      AvatarMouth.neutral => 'Neutra',
      AvatarMouth.grin => 'Sorriso aberto',
    };
  }

  static String accessoryLabel(AvatarAccessory accessory) {
    return switch (accessory) {
      AvatarAccessory.none => 'Nenhum',
      AvatarAccessory.studs => 'Brinco pequeno',
      AvatarAccessory.hoops => 'Argolas',
      AvatarAccessory.necklace => 'Colar',
    };
  }

  static String facialMarkLabel(AvatarFacialMark mark) {
    return switch (mark) {
      AvatarFacialMark.none => 'Nenhuma',
      AvatarFacialMark.freckles => 'Sardas',
      AvatarFacialMark.beautyMark => 'Pinta',
      AvatarFacialMark.laughLines => 'Marcas de expressão',
    };
  }

  static String outfitLabel(AvatarOutfit outfit) {
    return switch (outfit) {
      AvatarOutfit.crewneck => 'Camiseta',
      AvatarOutfit.collared => 'Camisa social',
      AvatarOutfit.vNeck => 'Gola V',
      AvatarOutfit.turtleneck => 'Gola alta',
      AvatarOutfit.cardigan => 'Cardigã',
      AvatarOutfit.blazer => 'Blazer',
      AvatarOutfit.labCoat => 'Jaleco',
      AvatarOutfit.scrubs => 'Scrub',
      AvatarOutfit.hoodie => 'Moletom',
    };
  }
}
