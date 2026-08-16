import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/profile/data/profile_repository.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/profile/providers/profile_providers.dart';

/// O EditProfileNotifier já engoliu operações em silêncio: `build()` é async,
/// então o estado nasce em `loading`, e a guarda de disparo duplo — que olhava
/// `state.isLoading` — barrava a PRIMEIRA chamada, feita no mesmo instante em
/// que o notifier é criado. A tela mostrava sucesso e nada era gravado.
void main() {
  late _FakeRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        authControllerProvider.overrideWith((ref) => _FakeAuthController()),
      ],
    );
    addTearDown(container.dispose);
  });

  test('a primeira operação após criar o notifier chega ao repositório',
      () async {
    // Exatamente o padrão usado nas telas: ler o notifier e chamar o método
    // na mesma expressão, sem esperar nada antes.
    await container
        .read(editProfileProvider.notifier)
        .saveAvatarConfig(const AvatarConfig(hairStyle: AvatarHairStyle.afro));

    expect(
      repo.savedConfigs,
      hasLength(1),
      reason: 'a operação foi descartada em silêncio',
    );
    expect(repo.savedConfigs.single.hairStyle, AvatarHairStyle.afro);
  });

  test('operações seguidas continuam funcionando', () async {
    final notifier = container.read(editProfileProvider.notifier);

    await notifier.saveAvatarConfig(const AvatarConfig());
    await notifier.useInitials();
    await notifier.saveAvatarConfig(
      const AvatarConfig(hairStyle: AvatarHairStyle.bun),
    );

    expect(repo.savedConfigs, hasLength(2));
    expect(repo.initialsCalls, 1);
  });

  test('erro no repositório é propagado para a tela', () async {
    repo.shouldFail = true;

    expect(
      () => container
          .read(editProfileProvider.notifier)
          .saveAvatarConfig(const AvatarConfig()),
      throwsA(isA<Exception>()),
    );
  });

  test('falha não deixa o notifier travado para a próxima tentativa', () async {
    final notifier = container.read(editProfileProvider.notifier);

    repo.shouldFail = true;
    await expectLater(
      notifier.saveAvatarConfig(const AvatarConfig()),
      throwsA(isA<Exception>()),
    );

    repo.shouldFail = false;
    await notifier.saveAvatarConfig(const AvatarConfig());

    expect(repo.savedConfigs, hasLength(1));
  });
}

class _FakeRepo implements ProfileRepository {
  final savedConfigs = <AvatarConfig>[];
  int initialsCalls = 0;
  bool shouldFail = false;

  @override
  Future<UserProfile> saveAvatarConfig(AvatarConfig config) async {
    if (shouldFail) throw Exception('falha simulada');
    savedConfigs.add(config);
    return _profile;
  }

  @override
  Future<UserProfile> useInitials() async {
    initialsCalls++;
    return _profile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _profile = UserProfile(
  id: 'psi-1',
  clinicId: 'clinic-1',
  role: ProfileRole.psychologist,
  fullName: 'Bruno Psicólogo',
  email: 'bruno@example.com',
  isActive: true,
);

class _FakeAuthController extends AuthController {
  _FakeAuthController() : super(_DummyRef()) {
    state = const AsyncValue.data(_profile);
  }

  @override
  Future<void> loadProfile() async {
    state = const AsyncValue.data(_profile);
  }

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
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
    return _DummySubscription<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummySubscription<T> implements ProviderSubscription<T> {
  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
