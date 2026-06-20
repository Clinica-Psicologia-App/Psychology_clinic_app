class FinishQuestionnaireResult {
  const FinishQuestionnaireResult({
    required this.responseId,
    required this.questionnaireName,
    this.completedAt,
    required this.resultsCount,
  });

  final String responseId;
  final String questionnaireName;
  final DateTime? completedAt;
  final int resultsCount;

  factory FinishQuestionnaireResult.fromApi(
    Map<String, dynamic> data,
    String questionnaireName,
  ) {
    final response = Map<String, dynamic>.from(data['response'] as Map);
    final results = data['results'] as List? ?? [];
    final completedRaw = response['completed_at'] as String?;

    return FinishQuestionnaireResult(
      responseId: response['id'] as String,
      questionnaireName: questionnaireName,
      completedAt:
          completedRaw != null ? DateTime.tryParse(completedRaw) : null,
      resultsCount: results.length,
    );
  }
}
