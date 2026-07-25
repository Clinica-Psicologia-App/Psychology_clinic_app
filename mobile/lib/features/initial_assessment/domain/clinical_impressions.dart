import 'functioning_level.dart';

/// Bloco 4 — Primeiras Impressões Clínicas (staff-only, o paciente nunca vê).
/// Mapeia `patient_clinical_impressions` + as junções de checklist
/// (esquemas, modos e necessidades emocionais) resolvidas como listas de ids.
class ClinicalImpressions {
  const ClinicalImpressions({
    this.observedTemperament,
    this.therapeuticBond,
    this.resources,
    this.vulnerabilities,
    this.hypotheses,
    this.previousDiagnoses,
    this.differentialDiagnosis,
    this.functioningLevel,
    this.therapeuticPriorities,
    this.schemaHypothesisIds = const [],
    this.modeHypothesisIds = const [],
    this.emotionalNeedIds = const [],
  });

  // Impressão geral
  final String? observedTemperament;
  final String? therapeuticBond;
  final String? resources;
  final String? vulnerabilities;

  // Perspectiva diagnóstica
  final String? hypotheses;
  final String? previousDiagnoses;
  final String? differentialDiagnosis;

  // Nível de funcionamento
  final FunctioningLevel? functioningLevel;

  // Prioridades terapêuticas
  final String? therapeuticPriorities;

  // Checklists (ids selecionados)
  final List<String> schemaHypothesisIds;
  final List<String> modeHypothesisIds;
  final List<String> emotionalNeedIds;

  factory ClinicalImpressions.fromJson(
    Map<String, dynamic> json, {
    List<String> schemaHypothesisIds = const [],
    List<String> modeHypothesisIds = const [],
    List<String> emotionalNeedIds = const [],
  }) {
    return ClinicalImpressions(
      observedTemperament: json['observed_temperament'] as String?,
      therapeuticBond: json['therapeutic_bond'] as String?,
      resources: json['resources'] as String?,
      vulnerabilities: json['vulnerabilities'] as String?,
      hypotheses: json['hypotheses'] as String?,
      previousDiagnoses: json['previous_diagnoses'] as String?,
      differentialDiagnosis: json['differential_diagnosis'] as String?,
      functioningLevel:
          functioningLevelFromKey(json['functioning_level'] as String?),
      therapeuticPriorities: json['therapeutic_priorities'] as String?,
      schemaHypothesisIds: schemaHypothesisIds,
      modeHypothesisIds: modeHypothesisIds,
      emotionalNeedIds: emotionalNeedIds,
    );
  }
}
