/// Nível atual de funcionamento (Bloco 4). Bate com o CHECK de
/// `patient_clinical_impressions.functioning_level`.
enum FunctioningLevel {
  excellent,
  good,
  moderate,
  impaired,
  severelyImpaired,
}

extension FunctioningLevelMeta on FunctioningLevel {
  String get key => switch (this) {
        FunctioningLevel.excellent => 'excellent',
        FunctioningLevel.good => 'good',
        FunctioningLevel.moderate => 'moderate',
        FunctioningLevel.impaired => 'impaired',
        FunctioningLevel.severelyImpaired => 'severely_impaired',
      };

  String get label => switch (this) {
        FunctioningLevel.excellent => 'Excelente',
        FunctioningLevel.good => 'Bom',
        FunctioningLevel.moderate => 'Moderado',
        FunctioningLevel.impaired => 'Comprometido',
        FunctioningLevel.severelyImpaired => 'Muito comprometido',
      };
}

FunctioningLevel? functioningLevelFromKey(String? key) {
  if (key == null) return null;
  for (final level in FunctioningLevel.values) {
    if (level.key == key) return level;
  }
  return null;
}
