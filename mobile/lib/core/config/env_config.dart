import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Configuração via `--dart-define-from-file=env.local.json`.
/// Copie `env.example.json` → `env.local.json` e ajuste para remoto/produção.
abstract final class EnvConfig {
  static const String _urlDefine = String.fromEnvironment('SUPABASE_URL');
  static const String _anonKeyDefine = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Chave anon padrão do Supabase **local** (`supabase start`). Em staging/produção
  /// use sempre `env.local.json` / CI — nunca a demo key do projeto remoto.
  static const String _defaultAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static String get supabaseUrl {
    final url = _urlDefine.isNotEmpty ? _urlDefine : _localDefaultUrl;
    return _androidLoopbackFix(url);
  }

  /// env.local.json costuma usar 127.0.0.1; no emulador Android isso não alcança o host.
  static String _androidLoopbackFix(String url) {
    if (!kIsWeb && Platform.isAndroid && url.contains('127.0.0.1')) {
      return url.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return url;
  }

  static String get supabaseAnonKey {
    if (_anonKeyDefine.isNotEmpty) return _anonKeyDefine;
    return _defaultAnonKey;
  }

  /// Emulador Android: host `10.0.2.2` aponta para localhost da máquina.
  static String get _localDefaultUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:54321';
    }
    return 'http://127.0.0.1:54321';
  }

  static void validate() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL e SUPABASE_ANON_KEY são obrigatórios. '
        'Use --dart-define-from-file=env.local.json',
      );
    }
  }
}
