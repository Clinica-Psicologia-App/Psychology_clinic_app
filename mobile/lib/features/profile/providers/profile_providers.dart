import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/profile_repository.dart';
import '../domain/avatar_config.dart';
import '../domain/avatar_type.dart';
import '../domain/user_profile.dart';

export '../domain/avatar_config.dart';
export '../domain/avatar_type.dart';
export '../domain/user_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Profile do usuário autenticado (null se deslogado).
final currentProfileProvider = Provider<AsyncValue<UserProfile?>>((ref) {
  return ref.watch(authControllerProvider);
});

/// Mutações do próprio perfil.
///
/// Cada operação recarrega o `authControllerProvider` ao final — ele segue
/// sendo a fonte de verdade do profile, então AppBars e homes refletem a
/// mudança sem precisar de estado duplicado.
class EditProfileNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Bloqueia disparo duplo enquanto uma operação está em voo.
  bool get _busy => state.isLoading;

  Future<void> _run(
      Future<void> Function(ProfileRepository repo) action) async {
    if (_busy) return;
    state = const AsyncValue.loading();
    try {
      await action(ref.read(profileRepositoryProvider));
      await ref.read(authControllerProvider.notifier).loadProfile();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateDetails({String? fullName, String? phone}) {
    return _run(
      (repo) => repo.updateOwnProfile(fullName: fullName, phone: phone),
    );
  }

  Future<void> changePhoto({
    required Uint8List bytes,
    required String fileName,
  }) {
    return _run(
      (repo) => repo.uploadPhoto(bytes: bytes, fileName: fileName),
    );
  }

  Future<void> saveAvatarConfig(AvatarConfig config) {
    return _run((repo) => repo.saveAvatarConfig(config));
  }

  /// Reativa uma fonte já existente (foto ou avatar salvo) sem reenviar nada.
  Future<void> selectAvatarType(AvatarType type) {
    return _run((repo) => repo.selectAvatarType(type));
  }

  /// Volta para as iniciais preservando foto e configuração.
  Future<void> useInitials() {
    return _run((repo) => repo.useInitials());
  }

  /// Apaga a foto do Storage e limpa as referências.
  Future<void> deletePhoto() {
    return _run((repo) => repo.deletePhoto());
  }
}

final editProfileProvider =
    AsyncNotifierProvider<EditProfileNotifier, void>(EditProfileNotifier.new);
