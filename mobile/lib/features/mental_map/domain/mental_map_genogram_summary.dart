class MentalMapGenogramSummary {
  const MentalMapGenogramSummary({
    required this.peopleCount,
    required this.relationshipCount,
    required this.sensitivePeopleCount,
    required this.sensitiveRelationshipCount,
  });

  static const empty = MentalMapGenogramSummary(
    peopleCount: 0,
    relationshipCount: 0,
    sensitivePeopleCount: 0,
    sensitiveRelationshipCount: 0,
  );

  final int peopleCount;
  final int relationshipCount;
  final int sensitivePeopleCount;
  final int sensitiveRelationshipCount;

  bool get hasContent => peopleCount > 0 || relationshipCount > 0;

  bool get hasSensitiveItems =>
      sensitivePeopleCount > 0 || sensitiveRelationshipCount > 0;

  int get totalSensitiveCount =>
      sensitivePeopleCount + sensitiveRelationshipCount;
}
