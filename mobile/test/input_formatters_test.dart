import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/shared/utils/brazil_validators.dart';
import 'package:terapia_esquema/shared/utils/input_formatters.dart';

void main() {
  test('digitsOnly strips mask characters', () {
    expect(digitsOnly('(51) 99306-9226'), '51993069226');
    expect(digitsOnly('041.040.820-45'), '04104082045');
  });

  test('validateOptionalCpf accepts empty', () {
    expect(validateOptionalCpf(null), isNull);
    expect(validateOptionalCpf(''), isNull);
  });

  test('validateOptionalCpf requires 11 digits', () {
    expect(validateOptionalCpf('123'), isNotNull);
    expect(validateOptionalCpf('041.040.820-45'), isNull);
  });
}
