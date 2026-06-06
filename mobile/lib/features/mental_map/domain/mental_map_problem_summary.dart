class MentalMapProblemSummary {
  const MentalMapProblemSummary({
    required this.id,
    required this.title,
    this.intensity,
    required this.statusLabel,
  });

  final String id;
  final String title;
  final int? intensity;
  final String statusLabel;
}
