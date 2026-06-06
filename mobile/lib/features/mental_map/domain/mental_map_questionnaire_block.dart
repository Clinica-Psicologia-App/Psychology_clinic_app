import 'mental_map_score_highlight.dart';

class MentalMapQuestionnaireBlock {
  const MentalMapQuestionnaireBlock({
    required this.responseId,
    required this.questionnaireCode,
    required this.questionnaireName,
    this.completedAt,
    this.requiresTherapistReview = false,
    required this.highlights,
  });

  final String responseId;
  final String questionnaireCode;
  final String questionnaireName;
  final DateTime? completedAt;
  final bool requiresTherapistReview;
  final List<MentalMapScoreHighlight> highlights;

  bool get isEmpty => highlights.isEmpty;
}
