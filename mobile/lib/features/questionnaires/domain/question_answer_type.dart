/// Tipos de resposta do schema (`question_answer_type`).
enum QuestionAnswerType {
  likertScale('likert_scale'),
  numericScale('numeric_scale'),
  singleChoice('single_choice'),
  text('text');

  const QuestionAnswerType(this.value);

  final String value;

  static QuestionAnswerType fromString(String raw) {
    return QuestionAnswerType.values.firstWhere(
      (t) => t.value == raw,
      orElse: () => QuestionAnswerType.likertScale,
    );
  }

  bool get supportsNumericSubmission => this != QuestionAnswerType.text;
}
