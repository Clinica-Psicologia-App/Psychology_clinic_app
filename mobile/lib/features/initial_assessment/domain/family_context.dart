import 'genogram_enums.dart';

/// Clima emocional da família e padrões transgeracionais (Tela 3, nível do
/// paciente). Mapeia `patient_family_context`.
class FamilyContext {
  const FamilyContext({
    this.familyClimate = const [],
    this.familyClimateOther,
    this.transgenerationalPatterns = const [],
    this.transgenerationalPatternsOther,
    this.filledByRole,
  });

  final List<FamilyClimateTrait> familyClimate;
  final String? familyClimateOther;
  final List<TransgenerationalPattern> transgenerationalPatterns;
  final String? transgenerationalPatternsOther;
  final String? filledByRole;

  factory FamilyContext.fromJson(Map<String, dynamic> json) {
    return FamilyContext(
      familyClimate: parseKeys(
          json['family_climate'], FamilyClimateTrait.values, (e) => e.key),
      familyClimateOther: json['family_climate_other'] as String?,
      transgenerationalPatterns: parseKeys(json['transgenerational_patterns'],
          TransgenerationalPattern.values, (e) => e.key),
      transgenerationalPatternsOther:
          json['transgenerational_patterns_other'] as String?,
      filledByRole: json['filled_by_role'] as String?,
    );
  }
}
