/// Lente clínica do terapeuta (staff-only). Reúne as "Observações Iniciais"
/// (Bloco 1 privado) e a leitura clínica do Motivo da Procura (Bloco 2).
/// Mapeia `patient_clinical_intake`.
class ClinicalIntake {
  const ClinicalIntake({
    this.initialObservations,
    this.mainComplaint,
    this.currentProblem,
    this.precipitatingFactors,
    this.patientGoals,
    this.motivation,
    this.initialHypotheses,
  });

  final String? initialObservations; // Bloco 1 — campo privado
  final String? mainComplaint; // Queixa principal
  final String? currentProblem; // Problema atual
  final String? precipitatingFactors; // Fatores precipitantes
  final String? patientGoals; // Objetivos do paciente
  final String? motivation; // Motivação
  final String? initialHypotheses; // Hipóteses iniciais

  factory ClinicalIntake.fromJson(Map<String, dynamic> json) {
    return ClinicalIntake(
      initialObservations: json['initial_observations'] as String?,
      mainComplaint: json['main_complaint'] as String?,
      currentProblem: json['current_problem'] as String?,
      precipitatingFactors: json['precipitating_factors'] as String?,
      patientGoals: json['patient_goals'] as String?,
      motivation: json['motivation'] as String?,
      initialHypotheses: json['initial_hypotheses'] as String?,
    );
  }
}
