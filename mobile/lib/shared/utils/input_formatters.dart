import 'package:flutter/services.dart';

/// Mantém só dígitos (útil antes de enviar à API).
String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

/// Telefone BR: (XX) XXXXX-XXXX ou (XX) XXXX-XXXX (10–11 dígitos).
class BrazilPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    if (digits.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    if (digits.isNotEmpty) {
      buffer.write('(');
      final ddd = digits.length >= 2 ? digits.substring(0, 2) : digits;
      buffer.write(ddd);
      if (digits.length >= 2) buffer.write(') ');
    }
    if (digits.length > 2) {
      final rest = digits.substring(2);
      if (digits.length <= 10) {
        if (rest.length > 4) {
          buffer.write('${rest.substring(0, 4)}-${rest.substring(4)}');
        } else {
          buffer.write(rest);
        }
      } else {
        if (rest.length > 5) {
          buffer.write('${rest.substring(0, 5)}-${rest.substring(5)}');
        } else {
          buffer.write(rest);
        }
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// CPF: XXX.XXX.XXX-XX (11 dígitos).
class CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = digitsOnly(newValue.text);
    if (digits.length > 11) {
      return oldValue;
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('-');
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
