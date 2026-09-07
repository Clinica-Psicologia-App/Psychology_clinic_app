class MentalMapCaseSummary {
  const MentalMapCaseSummary({
    this.patientReason,
    this.intakeSummary,
    this.currentLifeContext,
    this.therapyDemands,
    required this.centralHypotheses,
    required this.currentFocuses,
  });

  static const empty = MentalMapCaseSummary(
    centralHypotheses: [],
    currentFocuses: [],
  );

  /// Motivo da busca relatado pelo próprio paciente no módulo Conhecer
  /// (`patient_intake.reason_for_seeking`).
  final String? patientReason;
  final String? intakeSummary;
  final String? currentLifeContext;
  final String? therapyDemands;
  final List<String> centralHypotheses;
  final List<String> currentFocuses;

  bool get hasContent {
    return _hasText(patientReason) ||
        _hasText(intakeSummary) ||
        _hasText(currentLifeContext) ||
        _hasText(therapyDemands) ||
        centralHypotheses.isNotEmpty ||
        currentFocuses.isNotEmpty;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
