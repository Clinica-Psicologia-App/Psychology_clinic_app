/// Bloco 2 — "O que está acontecendo?" (respostas do paciente).
/// Mapeia `patient_intake`. Visível ao paciente.
class PatientIntake {
  const PatientIntake({
    this.reasonForSeeking,
    this.problemDuration,
    this.mainDiscomfort,
    this.expectations,
    this.relatedEvent,
    this.completedAt,
    this.filledByRole,
  });

  final String? reasonForSeeking; // O que fez você procurar terapia agora?
  final String? problemDuration; // Há quanto tempo isso acontece?
  final String? mainDiscomfort; // O que mais incomoda hoje?
  final String? expectations; // O que espera que seja diferente após a terapia?
  final String? relatedEvent; // Existe algum acontecimento importante...?
  final DateTime? completedAt;
  final String? filledByRole;

  bool get isEmpty =>
      (reasonForSeeking ?? '').trim().isEmpty &&
      (problemDuration ?? '').trim().isEmpty &&
      (mainDiscomfort ?? '').trim().isEmpty &&
      (expectations ?? '').trim().isEmpty &&
      (relatedEvent ?? '').trim().isEmpty;

  factory PatientIntake.fromJson(Map<String, dynamic> json) {
    return PatientIntake(
      reasonForSeeking: json['reason_for_seeking'] as String?,
      problemDuration: json['problem_duration'] as String?,
      mainDiscomfort: json['main_discomfort'] as String?,
      expectations: json['expectations'] as String?,
      relatedEvent: json['related_event'] as String?,
      completedAt: _parse(json['completed_at']),
      filledByRole: json['filled_by_role'] as String?,
    );
  }

  static DateTime? _parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
