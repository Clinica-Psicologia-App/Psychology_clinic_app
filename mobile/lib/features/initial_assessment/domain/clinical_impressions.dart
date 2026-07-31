import 'functioning_level.dart';

/// Bloco 4 — Primeiras Impressões Clínicas (staff-only, o paciente nunca vê).
/// Mapeia `patient_clinical_impressions` + a junção de necessidades emocionais.
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
    this.schemaHypothesesText,
    this.modeHypothesesText,
    this.emotionalNeedsText,
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

  // Campos de texto livre
  final String? schemaHypothesesText;
  final String? modeHypothesesText;
  final String? emotionalNeedsText;

  factory ClinicalImpressions.fromJson(Map<String, dynamic> json) {
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
      schemaHypothesesText: json['schema_hypotheses_text'] as String?,
      modeHypothesesText: json['mode_hypotheses_text'] as String?,
      emotionalNeedsText: json['emotional_needs_text'] as String?,
    );
  }
}
