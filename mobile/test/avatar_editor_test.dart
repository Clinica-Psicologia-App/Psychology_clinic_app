import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/profile/presentation/avatar_editor_page.dart';
import 'package:terapia_esquema/features/profile/presentation/widgets/avatar_artwork.dart';
import 'package:terapia_esquema/features/profile/presentation/widgets/user_avatar.dart';

void main() {
  group('AvatarPainter', () {
    // O painter é código de desenho: o que dá para travar em teste é que ele
    // não lance para nenhuma combinação e que só repinte quando a config muda.
    test('não lança para nenhuma combinação de opções', () {
      for (final hair in AvatarHairStyle.values) {
        for (final facial in AvatarFacialHair.values) {
          for (final glasses in AvatarGlasses.values) {
            final config = AvatarConfig(
              hairStyle: hair,
              facialHair: facial,
              glasses: glasses,
            );
            expect(
              () => _paintOnce(AvatarPainter(config)),
              returnsNormally,
              reason: 'falhou em $hair / $facial / $glasses',
            );
          }
        }
      }
    });

    test('cobre todas as roupas, olhos, sobrancelhas e tons de pele', () {
      for (final outfit in AvatarOutfit.values) {
        for (final eye in AvatarEyeStyle.values) {
          expect(
            () => _paintOnce(
              AvatarPainter(AvatarConfig(outfit: outfit, eyeStyle: eye)),
            ),
            returnsNormally,
          );
        }
      }
      for (final skin in AvatarSkinTone.values) {
        for (final brow in AvatarEyebrowStyle.values) {
          expect(
            () => _paintOnce(
              AvatarPainter(AvatarConfig(skinTone: skin, eyebrowStyle: brow)),
            ),
            returnsNormally,
          );
        }
      }
    });

    test('cobre formato de rosto, nariz, boca e acessórios', () {
      for (final face in AvatarFaceShape.values) {
        for (final nose in AvatarNose.values) {
          for (final mouth in AvatarMouth.values) {
            for (final acc in AvatarAccessory.values) {
              expect(
                () => _paintOnce(
                  AvatarPainter(AvatarConfig(
                    faceShape: face,
                    noseStyle: nose,
                    mouthStyle: mouth,
                    accessory: acc,
                  )),
                ),
                returnsNormally,
                reason: 'falhou em $face / $nose / $mouth / $acc',
              );
            }
          }
        }
      }
    });

    test('formato do rosto altera o desenho', () {
      const oval = AvatarConfig(faceShape: AvatarFaceShape.oval);
      const square = AvatarConfig(faceShape: AvatarFaceShape.square);
      expect(
        const AvatarPainter(oval).shouldRepaint(const AvatarPainter(square)),
        isTrue,
      );
    });

    test('só repinta quando a configuração muda', () {
      const a = AvatarConfig();
      const b = AvatarConfig(hairStyle: AvatarHairStyle.afro);

      expect(const AvatarPainter(a).shouldRepaint(const AvatarPainter(a)),
          isFalse);
      expect(
          const AvatarPainter(a).shouldRepaint(const AvatarPainter(b)), isTrue);
    });
  });

  group('UserAvatar', () {
    testWidgets('desenha o avatar geométrico quando o tipo é custom',
        (tester) async {
      await _pump(
        tester,
        _profile(
          avatarType: AvatarType.custom,
          avatarConfig: const AvatarConfig(),
        ),
      );

      expect(find.byType(AvatarArtwork), findsOneWidget);
      // Iniciais são o fallback; não devem aparecer junto.
      expect(find.text('BP'), findsNothing);
    });

    testWidgets('cai nas iniciais quando custom não tem configuração',
        (tester) async {
      await _pump(tester, _profile(avatarType: AvatarType.custom));

      expect(find.byType(AvatarArtwork), findsNothing);
      expect(find.text('BP'), findsOneWidget);
    });

    testWidgets('mantém as iniciais quando o tipo é initials', (tester) async {
      await _pump(
        tester,
        _profile(
          avatarType: AvatarType.initials,
          avatarConfig: const AvatarConfig(),
        ),
      );

      expect(find.byType(AvatarArtwork), findsNothing);
      expect(find.text('BP'), findsOneWidget);
    });
  });

  group('editor de avatar', () {
    testWidgets('abre no avatar já salvo e habilita salvar só após mudança',
        (tester) async {
      const salvo = AvatarConfig(hairStyle: AvatarHairStyle.afro);
      await _pumpEditor(tester, salvo);

      final botao = find.widgetWithText(FilledButton, 'Salvar avatar');
      expect(botao, findsOneWidget);
      expect(
        tester.widget<FilledButton>(botao).onPressed,
        isNull,
        reason: 'sem alterações, salvar fica desabilitado',
      );

      // Troca o tom de pele pela grade de opções.
      await tester.tap(find.text('Escura').first);
      await tester.pumpAndSettle();

      expect(tester.widget<FilledButton>(botao).onPressed, isNotNull);
    });

    testWidgets('restaurar volta à configuração inicial', (tester) async {
      await _pumpEditor(tester, const AvatarConfig());

      await tester.tap(find.text('Escura').first);
      await tester.pumpAndSettle();

      final botao = find.widgetWithText(FilledButton, 'Salvar avatar');
      expect(tester.widget<FilledButton>(botao).onPressed, isNotNull);

      await tester.tap(find.byTooltip('Restaurar'));
      await tester.pumpAndSettle();

      expect(
        tester.widget<FilledButton>(botao).onPressed,
        isNull,
        reason: 'voltou ao inicial, então não há mais alterações pendentes',
      );
    });

    testWidgets('trocar de categoria mostra outras opções', (tester) async {
      await _pumpEditor(tester, const AvatarConfig());

      expect(find.text('Porcelana'), findsOneWidget);

      // "Cabelo" está visível sem rolar a barra de categorias.
      await tester.tap(find.text('Cabelo'));
      await tester.pumpAndSettle();

      expect(find.text('Porcelana'), findsNothing);
      // Item do topo da lista de propósito: a grade é rolável e o catálogo de
      // cabelos cresce, então mirar um item do fim tornaria o teste refém da
      // quantidade de opções em vez da troca de categoria.
      expect(find.text('Raspado'), findsOneWidget);
    });
  });
}

void _paintOnce(CustomPainter painter) {
  final recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size.square(100));
  recorder.endRecording();
}

UserProfile _profile({
  required AvatarType avatarType,
  AvatarConfig? avatarConfig,
}) {
  return UserProfile(
    id: 'psi-1',
    clinicId: 'clinic-1',
    role: ProfileRole.psychologist,
    fullName: 'Bruno Psicólogo',
    email: 'bruno@example.com',
    isActive: true,
    avatarType: avatarType,
    avatarConfig: avatarConfig,
  );
}

Future<void> _pump(WidgetTester tester, UserProfile profile) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: UserAvatar(profile: profile))),
  );
  await tester.pump();
}

Future<void> _pumpEditor(WidgetTester tester, AvatarConfig salvo) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _FakeAuthController(
            _profile(avatarType: AvatarType.custom, avatarConfig: salvo),
          ),
        ),
      ],
      child: const MaterialApp(home: AvatarEditorPage()),
    ),
  );
  await tester.pumpAndSettle();
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(UserProfile profile) : super(_DummyRef()) {
    _profile = profile;
    state = AsyncValue.data(profile);
  }

  late final UserProfile _profile;

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(_profile);
  }
}

class _DummyRef implements Ref {
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool? fireImmediately,
  }) {
    return _DummyProviderSubscription<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyProviderSubscription<T> implements ProviderSubscription<T> {
  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
