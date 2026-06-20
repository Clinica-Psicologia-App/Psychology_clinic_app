import 'genogram_gender.dart';
import 'genogram_person.dart';

class GenogramPersonInput {
  const GenogramPersonInput({
    required this.fullName,
    this.nickname,
    this.relationshipToPatient,
    this.gender,
    this.birthYear,
    this.deathYear,
    this.isDeceased = false,
    this.notes,
    this.isSensitive = false,
  });

  final String fullName;
  final String? nickname;
  final String? relationshipToPatient;
  final GenogramGender? gender;
  final int? birthYear;
  final int? deathYear;
  final bool isDeceased;
  final String? notes;
  final bool isSensitive;

  factory GenogramPersonInput.fromPerson(GenogramPerson person) {
    return GenogramPersonInput(
      fullName: person.fullName,
      nickname: person.nickname,
      relationshipToPatient: person.relationshipToPatient,
      gender: person.gender,
      birthYear: person.birthYear,
      deathYear: person.deathYear,
      isDeceased: person.isDeceased,
      notes: person.notes,
      isSensitive: person.isSensitive,
    );
  }

  String? validate() {
    if (fullName.trim().isEmpty) return 'Informe o nome.';
    if (fullName.trim().length > 200) {
      return 'Nome muito longo (máx. 200 caracteres).';
    }
    final yearError = _validateYear(birthYear, 'nascimento');
    if (yearError != null) return yearError;
    final deathError = _validateYear(deathYear, 'falecimento');
    if (deathError != null) return deathError;
    if (birthYear != null && deathYear != null && deathYear! < birthYear!) {
      return 'Ano de falecimento não pode ser anterior ao de nascimento.';
    }
    return null;
  }

  static String? _validateYear(int? year, String label) {
    if (year == null) return null;
    if (year < 1800 || year > 2200) {
      return 'Ano de $label inválido (use 1800-2200).';
    }
    return null;
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'full_name': fullName.trim(),
      'nickname': _nullableTrim(nickname),
      'relationship_to_patient': _nullableTrim(relationshipToPatient),
      if (gender != null) 'gender': gender!.storageValue,
      if (birthYear != null) 'birth_year': birthYear,
      if (deathYear != null) 'death_year': deathYear,
      'is_deceased': isDeceased,
      'notes': _nullableTrim(notes),
      'is_sensitive': isSensitive,
    };
  }

  Map<String, dynamic> toUpdateJson() => toInsertJson();

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
