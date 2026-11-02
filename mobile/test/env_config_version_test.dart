import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/config/env_config.dart';

void main() {
  test('sem defines, o rótulo mostra "dev" e o ambiente local', () {
    final label = EnvConfig.versionLabel;
    expect(label, startsWith('Versão dev'));
    // Sem SUPABASE_URL o backend padrão é o local.
    expect(label, contains('ambiente local'));
    expect(label, isNot(contains('build')));
  });
}
