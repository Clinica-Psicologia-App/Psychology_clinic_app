class ClinicalDashboardHistoryEntry {
  const ClinicalDashboardHistoryEntry({
    required this.responseId,
    required this.questionnaireCode,
    required this.questionnaireName,
    required this.completedAt,
    required this.hasResults,
  });

  final String responseId;
  final String questionnaireCode;
  final String questionnaireName;
  final DateTime? completedAt;
  final bool hasResults;
}
