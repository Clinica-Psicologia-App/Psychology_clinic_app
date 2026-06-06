enum GenogramGender {
  male,
  female,
  other,
  unknown,
}

extension GenogramGenderX on GenogramGender {
  String get storageValue => name;

  String get label {
    switch (this) {
      case GenogramGender.male:
        return 'Masculino';
      case GenogramGender.female:
        return 'Feminino';
      case GenogramGender.other:
        return 'Outro';
      case GenogramGender.unknown:
        return 'Não informado';
    }
  }
}

GenogramGender? genogramGenderFromStorage(String? value) {
  if (value == null || value.isEmpty) return null;
  return GenogramGender.values.firstWhere(
    (g) => g.name == value,
    orElse: () => GenogramGender.unknown,
  );
}
