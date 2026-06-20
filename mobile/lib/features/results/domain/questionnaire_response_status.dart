/// Status de `questionnaire_responses.status`.
enum QuestionnaireResponseStatus {
  draft('draft'),
  completed('completed'),
  cancelled('cancelled');

  const QuestionnaireResponseStatus(this.value);

  final String value;

  static QuestionnaireResponseStatus fromString(String raw) {
    return QuestionnaireResponseStatus.values.firstWhere(
      (s) => s.value == raw,
      orElse: () => QuestionnaireResponseStatus.draft,
    );
  }

  String get label {
    switch (this) {
      case QuestionnaireResponseStatus.draft:
        return 'Em andamento';
      case QuestionnaireResponseStatus.completed:
        return 'Concluído';
      case QuestionnaireResponseStatus.cancelled:
        return 'Cancelado';
    }
  }
}
