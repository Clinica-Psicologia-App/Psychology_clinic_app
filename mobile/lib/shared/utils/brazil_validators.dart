import 'input_formatters.dart';

String? validateOptionalCpf(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = digitsOnly(value);
  if (digits.length != 11) {
    return 'CPF deve ter 11 dígitos';
  }
  return null;
}

String? validateOptionalPhone(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final digits = digitsOnly(value);
  if (digits.length < 10 || digits.length > 11) {
    return 'Telefone inválido';
  }
  return null;
}
