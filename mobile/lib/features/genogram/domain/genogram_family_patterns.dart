class GenogramFamilyPatterns {
  const GenogramFamilyPatterns({
    required this.patientId,
    required this.selectedKeys,
    this.otherText,
  });

  final String patientId;
  final Set<String> selectedKeys;
  final String? otherText;

  bool get hasOther =>
      selectedKeys.contains(GenogramFamilyPatternOption.other.key);

  factory GenogramFamilyPatterns.empty(String patientId) {
    return GenogramFamilyPatterns(patientId: patientId, selectedKeys: {});
  }

  factory GenogramFamilyPatterns.fromJson(Map<String, dynamic> json) {
    final rawKeys = json['pattern_keys'] as List? ?? const [];
    return GenogramFamilyPatterns(
      patientId: json['patient_id'] as String,
      selectedKeys: rawKeys.map((item) => item.toString()).toSet(),
      otherText: json['other_text'] as String?,
    );
  }
}

enum GenogramFamilyPatternOption {
  separations('separations', 'Separações conjugais'),
  violence('violence', 'Violência'),
  emotionalDependency('emotional_dependency', 'Dependência emocional'),
  alcoholism('alcoholism', 'Alcoolismo'),
  chemicalDependency('chemical_dependency', 'Dependência química'),
  psychiatricSymptoms(
    'psychiatric_symptoms',
    'Doenças e sintomas psiquiátricos',
  ),
  abandonment('abandonment', 'Abandono'),
  severeIllness('severe_illness', 'Doenças graves'),
  financialCrises('financial_crises', 'Falências ou crises financeiras'),
  perfectionism('perfectionism', 'Perfeccionismo'),
  emotionalRigidity('emotional_rigidity', 'Rigidez emocional'),
  abusiveRelationships('abusive_relationships', 'Relacionamentos abusivos'),
  suicideAttempts('suicide_attempts', 'Tentativas de suicídio'),
  excessiveCaretaking(
    'excessive_caretaking',
    'Cuidar excessivamente dos outros',
  ),
  other('other', 'Outro');

  const GenogramFamilyPatternOption(this.key, this.label);

  final String key;
  final String label;

  static GenogramFamilyPatternOption? fromKey(String key) {
    return GenogramFamilyPatternOption.values
        .where((option) => option.key == key)
        .firstOrNull;
  }
}
