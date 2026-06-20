import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/config/env_config.dart';
import '../../../core/supabase/supabase_bootstrap.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  bool get hasSession => currentSession != null;

  /// Renova access token quando possível (PKCE + refresh token).
  Future<Session?> refreshSession() async {
    try {
      final response = await _client.auth.refreshSession();
      return response.session;
    } catch (_) {
      return null;
    }
  }

  Future<Session> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final session = response.session;
      if (session == null) {
        throw StateError('Login sem sessão retornada.');
      }
      return session;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: EnvConfig.passwordResetRedirectUrl,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> updatePassword(String password) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: password));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Encerra sessão local e remota (global).
  Future<void> signOut() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.global);
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
