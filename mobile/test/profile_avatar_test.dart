import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';

/// Linha mínima de `profiles` como o PostgREST devolve.
Map<String, dynamic> profileRow({
  String fullName = 'Ana Maria Souza',
  String? avatarType,
  String? avatarPath,
  String? avatarUrl,
  String? avatarUpdatedAt,
  Map<String, dynamic>? avatarConfig,
  String? phone,
}) {
  return {
    'id': 'user-1',
    'clinic_id': 'clinic-1',
    'role': 'psychologist',
    'full_name': fullName,
    'email': 'ana@exemplo.com',
    'is_active': true,
    'phone': phone,
    'created_at': '2026-01-15T10:00:00Z',
    'avatar_type': avatarType,
    'avatar_path': avatarPath,
    'avatar_url': avatarUrl,
    'avatar_config': avatarConfig,
    'avatar_updated_at': avatarUpdatedAt,
  };
}

String fakePublicUrl(String path) => 'https://cdn.exemplo.com/avatars/$path';

void main() {
  group('AvatarType', () {
    test('mapeia as chaves conhecidas', () {
      expect(AvatarType.fromKey('initials'), AvatarType.initials);
      expect(AvatarType.fromKey('photo'), AvatarType.photo);
      expect(AvatarType.fromKey('custom'), AvatarType.custom);
    });

    test('chave desconhecida ou nula cai em initials', () {
      expect(AvatarType.fromKey('sticker_3d'), AvatarType.initials);
      expect(AvatarType.fromKey(null), AvatarType.initials);
      expect(AvatarType.fromKey(''), AvatarType.initials);
    });
  });

  group('AvatarConfig', () {
    test('json nulo devolve null', () {
      expect(AvatarConfig.fromJson(null), isNull);
    });

    test('serializa e desserializa preservando as escolhas', () {
      const config = AvatarConfig(
        skinTone: AvatarSkinTone.deep,
        hairStyle: AvatarHairStyle.afro,
        hairColor: AvatarHairColor.black,
        glasses: AvatarGlasses.square,
        outfit: AvatarOutfit.blazer,
        backgroundColor: AvatarPaletteColor.purple,
      );

      final restored = AvatarConfig.fromJson(config.toJson());

      expect(restored, config);
      expect(restored!.skinTone, AvatarSkinTone.deep);
      expect(restored.hairStyle, AvatarHairStyle.afro);
      expect(restored.glasses, AvatarGlasses.square);
    });

    test('grava sempre a versão corrente do schema', () {
      final json = const AvatarConfig().toJson();
      expect(json['schemaVersion'], kAvatarConfigSchemaVersion);
    });

    test('config de versão futura é lida sem lançar', () {
      final restored = AvatarConfig.fromJson({
        'schemaVersion': 99,
        'skinTone': 'tan',
        'hairStyle': 'estilo_que_ainda_nao_existe',
      });

      expect(restored, isNotNull);
      expect(restored!.skinTone, AvatarSkinTone.tan);
      // Opção desconhecida cai no padrão em vez de quebrar a leitura.
      expect(restored.hairStyle, AvatarHairStyle.short);
      // Ao regravar, normaliza para a versão atual.
      expect(restored.toJson()['schemaVersion'], kAvatarConfigSchemaVersion);
    });

    test('campo com tipo errado cai no padrão', () {
      final restored = AvatarConfig.fromJson({
        'skinTone': 42,
        'glasses': ['rounded'],
      });

      expect(restored!.skinTone, AvatarSkinTone.medium);
      expect(restored.glasses, AvatarGlasses.none);
    });

    test('json vazio produz a configuração padrão', () {
      expect(AvatarConfig.fromJson(const {}), const AvatarConfig());
    });

    test('copyWith altera só o campo pedido', () {
      const base = AvatarConfig();
      final changed = base.copyWith(hairColor: AvatarHairColor.blonde);

      expect(changed.hairColor, AvatarHairColor.blonde);
      expect(changed.skinTone, base.skinTone);
      expect(changed.outfit, base.outfit);
      expect(changed, isNot(base));
    });

    test('igualdade permite detectar alterações pendentes', () {
      const a = AvatarConfig();
      const b = AvatarConfig();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(glasses: AvatarGlasses.rounded), isNot(a));
    });

    test('serializado cabe no limite aceito pelo banco', () {
      final json = AvatarConfig.random(Random(7)).toJson().toString();
      expect(json.length, lessThan(kAvatarConfigMaxJsonLength));
    });

    group('random', () {
      test('é determinístico para a mesma seed', () {
        expect(
            AvatarConfig.random(Random(42)), AvatarConfig.random(Random(42)));
      });

      test('nunca coloca a roupa na mesma cor do fundo', () {
        for (var seed = 0; seed < 50; seed++) {
          final config = AvatarConfig.random(Random(seed));
          expect(
            config.outfitColor,
            isNot(config.backgroundColor),
            reason: 'seed $seed gerou roupa e fundo da mesma cor',
          );
        }
      });

      test('sobrevive à ida e volta do JSON', () {
        final config = AvatarConfig.random(Random(3));
        expect(AvatarConfig.fromJson(config.toJson()), config);
      });
    });
  });

  group('UserProfile.initials', () {
    UserProfile withName(String name) =>
        UserProfile.fromJson(profileRow(fullName: name));

    test('usa primeiro e último nome', () {
      expect(withName('Ana Maria Souza').initials, 'AS');
    });

    test('nome único usa uma letra', () {
      expect(withName('Ana').initials, 'A');
    });

    test('espaços extras não geram iniciais vazias', () {
      expect(withName('  Ana   Souza  ').initials, 'AS');
    });

    test('nome só com espaços cai na interrogação', () {
      expect(withName('   ').initials, '?');
    });

    test('preserva acentuação', () {
      expect(withName('Édipo Ângelo').initials, 'ÉÂ');
    });
  });

  group('UserProfile — resolução do avatar', () {
    test('sem foto e sem config exibe iniciais', () {
      final profile = UserProfile.fromJson(profileRow());
      expect(profile.effectiveAvatarType, AvatarType.initials);
      expect(profile.photoUrl, isNull);
    });

    test('avatar_path vira URL pública', () {
      final profile = UserProfile.fromJson(
        profileRow(
            avatarType: 'photo', avatarPath: 'user-1/profile/photo.webp'),
        publicUrlOf: fakePublicUrl,
      );

      expect(profile.effectiveAvatarType, AvatarType.photo);
      expect(
        profile.photoUrl,
        'https://cdn.exemplo.com/avatars/user-1/profile/photo.webp',
      );
    });

    test('avatar_url legado continua funcionando', () {
      final profile = UserProfile.fromJson(
        profileRow(
          avatarType: 'photo',
          avatarUrl: 'https://legado.exemplo.com/foto.jpg',
        ),
        publicUrlOf: fakePublicUrl,
      );

      expect(profile.effectiveAvatarType, AvatarType.photo);
      expect(profile.photoUrl, 'https://legado.exemplo.com/foto.jpg');
    });

    test('avatar_path tem precedência sobre o avatar_url legado', () {
      final profile = UserProfile.fromJson(
        profileRow(
          avatarType: 'photo',
          avatarPath: 'user-1/profile/photo.png',
          avatarUrl: 'https://legado.exemplo.com/foto.jpg',
        ),
        publicUrlOf: fakePublicUrl,
      );

      expect(profile.photoUrl, contains('user-1/profile/photo.png'));
    });

    test('registro antigo com foto e sem avatar_type é tratado como foto', () {
      final profile = UserProfile.fromJson(
        profileRow(avatarUrl: 'https://legado.exemplo.com/foto.jpg'),
      );
      expect(profile.effectiveAvatarType, AvatarType.photo);
    });

    test('tipo photo sem imagem alguma degrada para iniciais', () {
      final profile = UserProfile.fromJson(profileRow(avatarType: 'photo'));
      expect(profile.effectiveAvatarType, AvatarType.initials);
    });

    test('tipo custom sem configuração degrada para iniciais', () {
      final profile = UserProfile.fromJson(profileRow(avatarType: 'custom'));
      expect(profile.effectiveAvatarType, AvatarType.initials);
    });

    test('tipo custom com configuração é exibível', () {
      final profile = UserProfile.fromJson(
        profileRow(
          avatarType: 'custom',
          avatarConfig: const AvatarConfig().toJson(),
        ),
      );

      expect(profile.effectiveAvatarType, AvatarType.custom);
      expect(profile.avatarConfig, isNotNull);
    });

    test('foto guardada não some ao exibir as iniciais', () {
      final profile = UserProfile.fromJson(
        profileRow(
          avatarType: 'initials',
          avatarPath: 'user-1/profile/photo.webp',
          avatarUpdatedAt: '2026-07-31T12:00:00Z',
        ),
        publicUrlOf: fakePublicUrl,
      );

      // O usuário pediu iniciais, mas a foto continua disponível para reativar.
      expect(profile.photoUrl, isNotNull);
    });
  });

  group('UserProfile — cache busting', () {
    test('acrescenta a versão derivada de avatar_updated_at', () {
      final url = UserProfile.resolvePhotoUrl(
        avatarPath: 'user-1/profile/photo.webp',
        legacyAvatarUrl: null,
        avatarUpdatedAt: DateTime.utc(2026, 7, 31, 12),
        publicUrlOf: fakePublicUrl,
      );

      expect(
        url,
        'https://cdn.exemplo.com/avatars/user-1/profile/photo.webp'
        '?v=${DateTime.utc(2026, 7, 31, 12).millisecondsSinceEpoch}',
      );
    });

    test('sem carimbo não acrescenta parâmetro', () {
      final url = UserProfile.resolvePhotoUrl(
        avatarPath: 'user-1/profile/photo.webp',
        legacyAvatarUrl: null,
        avatarUpdatedAt: null,
        publicUrlOf: fakePublicUrl,
      );

      expect(url, isNot(contains('?v=')));
    });

    test('usa & quando a URL já tem query string', () {
      final url = UserProfile.resolvePhotoUrl(
        avatarPath: null,
        legacyAvatarUrl: 'https://legado.exemplo.com/foto.jpg?token=abc',
        avatarUpdatedAt: DateTime.utc(2026, 7, 31),
        publicUrlOf: fakePublicUrl,
      );

      expect(url, contains('?token=abc&v='));
    });

    test('duas datas diferentes produzem URLs diferentes', () {
      String? urlAt(DateTime at) => UserProfile.resolvePhotoUrl(
            avatarPath: 'user-1/profile/photo.webp',
            legacyAvatarUrl: null,
            avatarUpdatedAt: at,
            publicUrlOf: fakePublicUrl,
          );

      expect(
        urlAt(DateTime.utc(2026, 7, 31)),
        isNot(urlAt(DateTime.utc(2026, 8, 1))),
      );
    });

    test('path vazio ou em branco não vira URL', () {
      expect(
        UserProfile.resolvePhotoUrl(
          avatarPath: '   ',
          legacyAvatarUrl: '  ',
          avatarUpdatedAt: DateTime.utc(2026, 7, 31),
          publicUrlOf: fakePublicUrl,
        ),
        isNull,
      );
    });

    test('sem resolver de URL o path é ignorado e o legado assume', () {
      final url = UserProfile.resolvePhotoUrl(
        avatarPath: 'user-1/profile/photo.webp',
        legacyAvatarUrl: 'https://legado.exemplo.com/foto.jpg',
        avatarUpdatedAt: null,
      );

      expect(url, 'https://legado.exemplo.com/foto.jpg');
    });
  });

  group('UserProfile.copyWith', () {
    test('altera só o campo pedido', () {
      final profile = UserProfile.fromJson(profileRow(phone: '11999998888'));
      final changed = profile.copyWith(fullName: 'Ana M. Souza');

      expect(changed.fullName, 'Ana M. Souza');
      expect(changed.phone, '11999998888');
      expect(changed.email, profile.email);
      expect(changed.role, ProfileRole.psychologist);
    });
  });
}
