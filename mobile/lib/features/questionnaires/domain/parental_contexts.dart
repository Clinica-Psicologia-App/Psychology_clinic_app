import 'questionnaire_response_context.dart';

List<QuestionnaireContextInput> buildParentalContextInputs({
  required bool includeMother,
  required bool includeFather,
  required bool includeOther,
  String? otherLabel,
}) {
  final contexts = <QuestionnaireContextInput>[
    if (includeMother)
      const QuestionnaireContextInput(key: 'mother', label: 'Mãe'),
    if (includeFather)
      const QuestionnaireContextInput(key: 'father', label: 'Pai'),
    if (includeOther)
      QuestionnaireContextInput(
        key: 'other',
        label: otherLabel?.trim() ?? '',
      ),
  ];
  return contexts;
}

String? validateParentalContextSelection({
  required bool includeMother,
  required bool includeFather,
  required bool includeOther,
  String? otherLabel,
}) {
  if (!includeMother && !includeFather && !includeOther) {
    return 'Selecione pelo menos uma figura parental.';
  }
  if (includeOther && (otherLabel == null || otherLabel.trim().isEmpty)) {
    return 'Informe quem sera respondido em "Outro".';
  }
  if (includeOther && otherLabel!.trim().toLowerCase() == 'outro') {
    return 'Descreva a figura parental em "Outro".';
  }
  return null;
}

String normalizeParentalQuestionText(String text) {
  final idx = text.indexOf(':');
  if (idx <= 0) return text.trim();
  return text.substring(idx + 1).trim();
}

double progressForContext({
  required String contextId,
  required Map<String, int> answers,
  required int totalQuestions,
}) {
  if (totalQuestions <= 0) return 0;
  final answered =
      answers.keys.where((key) => key.startsWith('$contextId::')).length;
  return answered / totalQuestions;
}
