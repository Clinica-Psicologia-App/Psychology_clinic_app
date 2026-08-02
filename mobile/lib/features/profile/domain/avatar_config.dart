// Configuração do avatar geométrico. É persistida em `profiles.avatar_config`
// (JSONB) e renderizada no cliente — não gera arquivo no Storage.
//
// Todas as opções são enums fechados: o cliente nunca grava string arbitrária,
// e valor desconhecido na leitura cai no padrão em vez de lançar. Isso mantém
// avatares criados por versões futuras do app legíveis por versões antigas.

import 'dart:math';

/// Versão do formato. Incrementar apenas em mudança incompatível; a leitura
/// tolera versões diferentes e preenche o que faltar com os padrões.
const int kAvatarConfigSchemaVersion = 1;

/// Limite defensivo espelhando a CHECK constraint do banco (2048 bytes).
const int kAvatarConfigMaxJsonLength = 2048;

// ---------------------------------------------------------------------------
// Opções
// ---------------------------------------------------------------------------

enum AvatarSkinTone {
  porcelain('porcelain'),
  light('light'),
  medium('medium'),
  tan('tan'),
  brown('brown'),
  deep('deep');

  const AvatarSkinTone(this.key);
  final String key;

  static AvatarSkinTone fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, medium);
}

enum AvatarHairStyle {
  none('none'),
  buzz('buzz'),
  pixie('pixie'),
  short('short'),
  shortCurly('short_curly'),
  undercut('undercut'),
  slickBack('slick_back'),
  medium('medium'),
  wavy('wavy'),
  long('long'),
  longCurly('long_curly'),
  coils('coils'),
  braids('braids'),
  bun('bun'),
  ponytail('ponytail'),
  afro('afro'),

  /// Véu de cabeça. Fica no mesmo eixo do cabelo porque ocupa o mesmo lugar
  /// no desenho e é mutuamente exclusivo com ele — o que também resolve a
  /// regra de compatibilidade sem precisar de uma camada de exceções.
  /// A cor acompanha a da roupa: é peça de vestuário, não cabelo.
  hijab('hijab');

  const AvatarHairStyle(this.key);
  final String key;

  static AvatarHairStyle fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, short);
}

enum AvatarHairColor {
  black('black'),
  darkBrown('dark_brown'),
  brown('brown'),
  lightBrown('light_brown'),
  blonde('blonde'),
  auburn('auburn'),
  gray('gray'),
  white('white');

  const AvatarHairColor(this.key);
  final String key;

  static AvatarHairColor fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, darkBrown);
}

enum AvatarFaceShape {
  oval('oval'),
  round('round'),
  square('square');

  const AvatarFaceShape(this.key);
  final String key;

  static AvatarFaceShape fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, oval);
}

enum AvatarNose {
  soft('soft'),
  straight('straight'),
  wide('wide');

  const AvatarNose(this.key);
  final String key;

  static AvatarNose fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, soft);
}

enum AvatarMouth {
  softSmile('soft_smile'),
  smile('smile'),
  neutral('neutral'),
  grin('grin');

  const AvatarMouth(this.key);
  final String key;

  static AvatarMouth fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, softSmile);
}

enum AvatarAccessory {
  none('none'),
  studs('studs'),
  hoops('hoops'),
  necklace('necklace');

  const AvatarAccessory(this.key);
  final String key;

  static AvatarAccessory fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, none);
}

enum AvatarEyeStyle {
  round('round'),
  almond('almond'),
  narrow('narrow'),
  wide('wide'),
  happy('happy');

  const AvatarEyeStyle(this.key);
  final String key;

  static AvatarEyeStyle fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, almond);
}

enum AvatarEyebrowStyle {
  straight('straight'),
  arched('arched'),
  thick('thick'),
  thin('thin'),
  raised('raised');

  const AvatarEyebrowStyle(this.key);
  final String key;

  static AvatarEyebrowStyle fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, straight);
}

/// A cor dos pelos faciais acompanha [AvatarConfig.hairColor] de propósito —
/// evita combinações incoerentes e reduz o espaço de configuração.
enum AvatarFacialHair {
  none('none'),
  stubble('stubble'),
  mustache('mustache'),
  goatee('goatee'),
  shortBeard('short_beard'),
  fullBeard('full_beard');

  const AvatarFacialHair(this.key);
  final String key;

  static AvatarFacialHair fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, none);
}

enum AvatarGlasses {
  none('none'),
  rounded('rounded'),
  square('square'),
  halfRim('half_rim');

  const AvatarGlasses(this.key);
  final String key;

  static AvatarGlasses fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, none);
}

enum AvatarOutfit {
  crewneck('crewneck'),
  collared('collared'),
  vNeck('v_neck'),
  blazer('blazer'),
  hoodie('hoodie');

  const AvatarOutfit(this.key);
  final String key;

  static AvatarOutfit fromKey(String? key) =>
      _lookup(values, key, (e) => e.key, crewneck);
}

/// Nomes de paleta, não valores hex. A tradução para cor vive na camada de
/// apresentação, junto do Design System — o domínio permanece Dart puro.
enum AvatarPaletteColor {
  turquoise('turquoise'),
  cyan('cyan'),
  blue('blue'),
  purple('purple'),
  navy('navy'),
  rose('rose'),
  amber('amber'),
  slate('slate');

  const AvatarPaletteColor(this.key);
  final String key;

  static AvatarPaletteColor fromKey(String? key, AvatarPaletteColor fallback) =>
      _lookup(values, key, (e) => e.key, fallback);
}

T _lookup<T>(
  List<T> values,
  String? key,
  String Function(T) keyOf,
  T fallback,
) {
  if (key == null) return fallback;
  for (final value in values) {
    if (keyOf(value) == key) return value;
  }
  return fallback;
}

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

class AvatarConfig {
  const AvatarConfig({
    this.schemaVersion = kAvatarConfigSchemaVersion,
    this.skinTone = AvatarSkinTone.medium,
    this.faceShape = AvatarFaceShape.oval,
    this.noseStyle = AvatarNose.soft,
    this.mouthStyle = AvatarMouth.softSmile,
    this.accessory = AvatarAccessory.none,
    this.hairStyle = AvatarHairStyle.short,
    this.hairColor = AvatarHairColor.darkBrown,
    this.eyeStyle = AvatarEyeStyle.almond,
    this.eyebrowStyle = AvatarEyebrowStyle.straight,
    this.facialHair = AvatarFacialHair.none,
    this.glasses = AvatarGlasses.none,
    this.outfit = AvatarOutfit.crewneck,
    this.outfitColor = AvatarPaletteColor.blue,
    this.backgroundColor = AvatarPaletteColor.turquoise,
  });

  final int schemaVersion;
  final AvatarSkinTone skinTone;
  final AvatarFaceShape faceShape;
  final AvatarNose noseStyle;
  final AvatarMouth mouthStyle;
  final AvatarAccessory accessory;
  final AvatarHairStyle hairStyle;
  final AvatarHairColor hairColor;
  final AvatarEyeStyle eyeStyle;
  final AvatarEyebrowStyle eyebrowStyle;
  final AvatarFacialHair facialHair;
  final AvatarGlasses glasses;
  final AvatarOutfit outfit;
  final AvatarPaletteColor outfitColor;
  final AvatarPaletteColor backgroundColor;

  /// Configuração inicial ao abrir o editor pela primeira vez.
  static const AvatarConfig initial = AvatarConfig();

  /// Nunca lança: chave ausente, tipo errado ou valor desconhecido caem no
  /// padrão do campo. `null` só retorna quando o próprio JSON é nulo.
  static AvatarConfig? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;

    String? str(String key) {
      final value = json[key];
      return value is String ? value : null;
    }

    final version = json['schemaVersion'];

    return AvatarConfig(
      schemaVersion: version is int ? version : kAvatarConfigSchemaVersion,
      skinTone: AvatarSkinTone.fromKey(str('skinTone')),
      faceShape: AvatarFaceShape.fromKey(str('faceShape')),
      noseStyle: AvatarNose.fromKey(str('noseStyle')),
      mouthStyle: AvatarMouth.fromKey(str('mouthStyle')),
      accessory: AvatarAccessory.fromKey(str('accessory')),
      hairStyle: AvatarHairStyle.fromKey(str('hairStyle')),
      hairColor: AvatarHairColor.fromKey(str('hairColor')),
      eyeStyle: AvatarEyeStyle.fromKey(str('eyeStyle')),
      eyebrowStyle: AvatarEyebrowStyle.fromKey(str('eyebrowStyle')),
      facialHair: AvatarFacialHair.fromKey(str('facialHair')),
      glasses: AvatarGlasses.fromKey(str('glasses')),
      outfit: AvatarOutfit.fromKey(str('outfit')),
      outfitColor: AvatarPaletteColor.fromKey(
        str('outfitColor'),
        AvatarPaletteColor.blue,
      ),
      backgroundColor: AvatarPaletteColor.fromKey(
        str('backgroundColor'),
        AvatarPaletteColor.turquoise,
      ),
    );
  }

  /// Sempre grava na versão corrente do schema, normalizando configs lidas de
  /// versões antigas.
  Map<String, dynamic> toJson() => {
        'schemaVersion': kAvatarConfigSchemaVersion,
        'skinTone': skinTone.key,
        'faceShape': faceShape.key,
        'noseStyle': noseStyle.key,
        'mouthStyle': mouthStyle.key,
        'accessory': accessory.key,
        'hairStyle': hairStyle.key,
        'hairColor': hairColor.key,
        'eyeStyle': eyeStyle.key,
        'eyebrowStyle': eyebrowStyle.key,
        'facialHair': facialHair.key,
        'glasses': glasses.key,
        'outfit': outfit.key,
        'outfitColor': outfitColor.key,
        'backgroundColor': backgroundColor.key,
      };

  AvatarConfig copyWith({
    AvatarSkinTone? skinTone,
    AvatarFaceShape? faceShape,
    AvatarNose? noseStyle,
    AvatarMouth? mouthStyle,
    AvatarAccessory? accessory,
    AvatarHairStyle? hairStyle,
    AvatarHairColor? hairColor,
    AvatarEyeStyle? eyeStyle,
    AvatarEyebrowStyle? eyebrowStyle,
    AvatarFacialHair? facialHair,
    AvatarGlasses? glasses,
    AvatarOutfit? outfit,
    AvatarPaletteColor? outfitColor,
    AvatarPaletteColor? backgroundColor,
  }) {
    return AvatarConfig(
      skinTone: skinTone ?? this.skinTone,
      faceShape: faceShape ?? this.faceShape,
      noseStyle: noseStyle ?? this.noseStyle,
      mouthStyle: mouthStyle ?? this.mouthStyle,
      accessory: accessory ?? this.accessory,
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyeStyle: eyeStyle ?? this.eyeStyle,
      eyebrowStyle: eyebrowStyle ?? this.eyebrowStyle,
      facialHair: facialHair ?? this.facialHair,
      glasses: glasses ?? this.glasses,
      outfit: outfit ?? this.outfit,
      outfitColor: outfitColor ?? this.outfitColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  /// Combinação aleatória válida. Aceita [random] para permitir teste
  /// determinístico por seed. Não depende de rede.
  ///
  /// A única regra de coerência aplicada: cabelo `none` não recebe cor de
  /// cabelo relevante, e o fundo nunca coincide com a cor da roupa — evita um
  /// avatar em que a roupa some contra o fundo.
  factory AvatarConfig.random([Random? random]) {
    final rng = random ?? Random();

    T pick<T>(List<T> options) => options[rng.nextInt(options.length)];

    final outfitColor = pick(AvatarPaletteColor.values);
    final backgrounds =
        AvatarPaletteColor.values.where((c) => c != outfitColor).toList();

    return AvatarConfig(
      skinTone: pick(AvatarSkinTone.values),
      faceShape: pick(AvatarFaceShape.values),
      noseStyle: pick(AvatarNose.values),
      mouthStyle: pick(AvatarMouth.values),
      accessory: pick(AvatarAccessory.values),
      hairStyle: pick(AvatarHairStyle.values),
      hairColor: pick(AvatarHairColor.values),
      eyeStyle: pick(AvatarEyeStyle.values),
      eyebrowStyle: pick(AvatarEyebrowStyle.values),
      facialHair: pick(AvatarFacialHair.values),
      glasses: pick(AvatarGlasses.values),
      outfit: pick(AvatarOutfit.values),
      outfitColor: outfitColor,
      backgroundColor: pick(backgrounds),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AvatarConfig &&
        other.skinTone == skinTone &&
        other.faceShape == faceShape &&
        other.noseStyle == noseStyle &&
        other.mouthStyle == mouthStyle &&
        other.accessory == accessory &&
        other.hairStyle == hairStyle &&
        other.hairColor == hairColor &&
        other.eyeStyle == eyeStyle &&
        other.eyebrowStyle == eyebrowStyle &&
        other.facialHair == facialHair &&
        other.glasses == glasses &&
        other.outfit == outfit &&
        other.outfitColor == outfitColor &&
        other.backgroundColor == backgroundColor;
  }

  @override
  int get hashCode => Object.hash(
        skinTone,
        faceShape,
        noseStyle,
        mouthStyle,
        accessory,
        hairStyle,
        hairColor,
        eyeStyle,
        eyebrowStyle,
        facialHair,
        glasses,
        outfit,
        outfitColor,
        backgroundColor,
      );
}
