import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
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

/// Mensagem exibida na tela de login após redirect (ex.: sessão expirada).
final authRedirectMessageProvider = StateProvider<String?>((ref) => null);

/// Indica que há uma sessão de recuperação de senha ativa (link de e-mail clicado).
/// Enquanto verdadeiro, o router redireciona para /update-password.
final passwordRecoveryActiveProvider = StateProvider<bool>((ref) => false);

class AuthController extends StateNotifier<AsyncValue<UserProfile?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    _listenAuth();
  }

  final Ref _ref;
  bool _hadAuthenticatedSession = false;

  void _listenAuth() {
    _ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (prev, next) {
      final authState = next.valueOrNull;
      if (authState == null) return;

      final event = authState.event;
      final session = authState.session;

      if (session == null) {
        if (_hadAuthenticatedSession && event == AuthChangeEvent.signedOut) {
          _setRedirectMessage(
            userMessageForCode(AppExceptionCodes.sessionExpired),
          );
        }
        _hadAuthenticatedSession = false;
        state = const AsyncValue.data(null);
        return;
      }

      _hadAuthenticatedSession = true;

      switch (event) {
        case AuthChangeEvent.tokenRefreshed:
          // Mantém profile em memória; não exibe loading global.
          break;
        case AuthChangeEvent.initialSession:
        case AuthChangeEvent.signedIn:
          loadProfile();
          break;
        case AuthChangeEvent.userUpdated:
          // Durante recuperação de senha, o usuário fará logout após atualizar.
          // Não carrega profile aqui para evitar redirect indevido para home.
          if (!_ref.read(passwordRecoveryActiveProvider)) {
            loadProfile();
          }
          break;
        case AuthChangeEvent.passwordRecovery:
          // Sessão de recuperação recebida via link de e-mail.
          // Sinaliza o router para navegar a /update-password.
          _ref.read(passwordRecoveryActiveProvider.notifier).state = true;
          state = const AsyncValue.data(null);
          break;
        case AuthChangeEvent.mfaChallengeVerified:
          break;
        case AuthChangeEvent.signedOut:
          // Limpa o modo de recuperação ao sair (inclusive após redefinir senha).
          _ref.read(passwordRecoveryActiveProvider.notifier).state = false;
          state = const AsyncValue.data(null);
          break;
        default:
          state = const AsyncValue.data(null);
      }
    });
  }

  void _setRedirectMessage(String message) {
    _ref.read(authRedirectMessageProvider.notifier).state = message;
  }

  void clearRedirectMessage() {
    _ref.read(authRedirectMessageProvider.notifier).state = null;
  }

  Future<void> loadProfile() async {
    if (!_ref.read(authRepositoryProvider).hasSession) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final profile =
          await _ref.read(profileRepositoryProvider).fetchCurrentProfile();
      state = AsyncValue.data(profile);
    } catch (e, st) {
      await _handleAuthFailure(mapToAppException(e), st);
    }
  }

  Future<void> _handleAuthFailure(AppException ex, StackTrace st) async {
    if (ex.code == AppExceptionCodes.sessionExpired ||
        ex.code == AppExceptionCodes.unauthorized) {
      _setRedirectMessage(userMessageFor(ex));
      await _safeSignOut();
      state = const AsyncValue.data(null);
      return;
    }

    if (ex.code == AppExceptionCodes.profileNotFound) {
      _setRedirectMessage(userMessageFor(ex));
      await _safeSignOut();
      state = const AsyncValue.data(null);
      return;
    }

    state = AsyncValue.error(ex, st);
  }

  Future<void> _safeSignOut() async {
    try {
      await _ref.read(authRepositoryProvider).signOut();
    } catch (_) {
      // Limpa estado local mesmo se signOut remoto falhar.
    }
  }

  Future<void> signIn(String email, String password) async {
    clearRedirectMessage();
    state = const AsyncValue.loading();
    try {
      await _ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          );
      final profile =
          await _ref.read(profileRepositoryProvider).fetchCurrentProfile();
      _hadAuthenticatedSession = true;
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(mapToAppException(e), st);
    }
  }

  Future<void> signOut() async {
    clearRedirectMessage();
    try {
      await _ref.read(authRepositoryProvider).signOut();
    } catch (e, st) {
      state = AsyncValue.error(mapToAppException(e), st);
      return;
    } finally {
      _hadAuthenticatedSession = false;
      state = const AsyncValue.data(null);
    }
  }

  Future<void> restoreSession() async {
    clearRedirectMessage();
    state = const AsyncValue.loading();

    final repo = _ref.read(authRepositoryProvider);
    var session = repo.currentSession;

    if (session == null) {
      state = const AsyncValue.data(null);
      return;
    }

    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      if (DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 1)))) {
        session = await repo.refreshSession();
        if (session == null) {
          _setRedirectMessage(
            userMessageForCode(AppExceptionCodes.sessionExpired),
          );
          await _safeSignOut();
          state = const AsyncValue.data(null);
          return;
        }
      }
    }

    _hadAuthenticatedSession = true;
    await loadProfile();
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserProfile?>>((ref) {
  return AuthController(ref);
});
