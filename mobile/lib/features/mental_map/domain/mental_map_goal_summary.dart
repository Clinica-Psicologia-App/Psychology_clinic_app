class MentalMapGoalSummary {
  const MentalMapGoalSummary({
    required this.id,
    required this.title,
    required this.statusLabel,
    this.targetDateLabel,
  });

  final String id;
  final String title;
  final String statusLabel;
  final String? targetDateLabel;
}
