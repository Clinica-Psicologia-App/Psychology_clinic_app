class MentalMapCheckInSummary {
  const MentalMapCheckInSummary({
    required this.id,
    this.moodScore,
    this.anxietyScore,
    this.energyScore,
    this.problemIntensityScore,
    required this.checkedInAt,
  });

  final String id;
  final int? moodScore;
  final int? anxietyScore;
  final int? energyScore;
  final int? problemIntensityScore;
  final DateTime checkedInAt;
}
