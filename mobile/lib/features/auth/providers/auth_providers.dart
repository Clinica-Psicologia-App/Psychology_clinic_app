import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/providers/profile_providers.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(authRepositoryProvider).currentSession;
});

class AuthController extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthController(this._ref) : super(const AsyncValue.data(null)) {
    _listenAuth();
  }

  final Ref _ref;

  void _listenAuth() {
    _ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      final session = next.valueOrNull?.session;
      if (session == null) {
        state = const AsyncValue.data(null);
      } else {
        loadProfile();
      }
    });
  }

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile =
          await _ref.read(profileRepositoryProvider).fetchCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(mapToAppException(e), st);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          );
      final profile =
          await _ref.read(profileRepositoryProvider).fetchCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(mapToAppException(e), st);
    }
  }

  Future<void> signOut() async {
    try {
      await _ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(mapToAppException(e), st);
    }
  }

  Future<void> restoreSession() async {
    final session = _ref.read(authRepositoryProvider).currentSession;
    if (session == null) {
      state = const AsyncValue.data(null);
      return;
    }
    await loadProfile();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserProfile?>>((ref) {
  return AuthController(ref);
});
