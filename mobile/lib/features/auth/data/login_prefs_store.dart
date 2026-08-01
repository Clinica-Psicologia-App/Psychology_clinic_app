import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persistência local (no dispositivo) do último e-mail usado no login,
/// para pré-preencher o formulário em acessos futuros.
///
/// Segue o mesmo padrão do OnboardingStore: arquivo simples no diretório
/// de documentos do app, com falhas tratadas de forma silenciosa (a
/// conveniência nunca pode impedir o login).
class LoginPrefsStore {
  const LoginPrefsStore();

  static const _fileName = '.esquemacore_last_email';

  Future<String?> lastEmail() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!file.existsSync()) return null;
      final email = (await file.readAsString()).trim();
      return email.isEmpty ? null : email;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastEmail(String email) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      await File('${dir.path}/$_fileName').writeAsString(email.trim());
    } catch (_) {
      // Ignora: estado local apenas, sem impacto crítico.
    }
  }
}
