import 'questionnaire.dart';

class QuestionnaireAccessItem {
  const QuestionnaireAccessItem({
    required this.questionnaire,
    required this.isEnabled,
  });

  final Questionnaire questionnaire;
  final bool isEnabled;
}
