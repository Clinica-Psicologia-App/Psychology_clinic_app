import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Persistência local (no dispositivo) do estado "já viu o onboarding".
///
/// Usa um arquivo marcador no diretório de documentos do app para evitar
/// adicionar uma dependência extra. Falhas são tratadas de forma segura:
/// em caso de erro assume-se que o usuário já viu (não prende ninguém na
/// tela de boas-vindas).
class OnboardingStore {
  const OnboardingStore();

  static const _fileName = '.esquemacore_onboarding_seen';

  Future<bool> hasSeen() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      return File('${dir.path}/$_fileName').existsSync();
    } catch (_) {
      return true;
    }
  }

  Future<void> markSeen() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!file.existsSync()) {
        await file.writeAsString(DateTime.now().toIso8601String());
      }
    } catch (_) {
      // Ignora: estado local apenas, sem impacto crítico.
    }
  }
}
