class MentalMapCaseSummary {
  const MentalMapCaseSummary({
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

  final String? intakeSummary;
  final String? currentLifeContext;
  final String? therapyDemands;
  final List<String> centralHypotheses;
  final List<String> currentFocuses;

  bool get hasContent {
    return _hasText(intakeSummary) ||
        _hasText(currentLifeContext) ||
        _hasText(therapyDemands) ||
        centralHypotheses.isNotEmpty ||
        currentFocuses.isNotEmpty;
  }

  static bool _hasText(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
