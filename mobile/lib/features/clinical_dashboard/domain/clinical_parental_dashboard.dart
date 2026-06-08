import 'clinical_dashboard_score_row.dart';

class ClinicalParentalDashboard {
  const ClinicalParentalDashboard({
    required this.responseId,
    required this.questionnaireCode,
    required this.questionnaireName,
    this.completedAt,
    required this.figures,
  });

  final String responseId;
  final String questionnaireCode;
  final String questionnaireName;
  final DateTime? completedAt;
  final List<ClinicalParentalFigurePanel> figures;

  bool get isEmpty => figures.isEmpty;

  bool get hasContent => figures.any((figure) => figure.hasScores);
}

class ClinicalParentalFigurePanel {
  const ClinicalParentalFigurePanel({
    required this.id,
    required this.key,
    required this.label,
    this.answerCount,
    this.totalQuestions,
    this.completionRatio,
    required this.topScores,
    this.summaryLine,
  });

  final String id;
  final String key;
  final String label;
  final int? answerCount;
  final int? totalQuestions;
  final double? completionRatio;
  final List<ClinicalDashboardScoreRow> topScores;
  final String? summaryLine;

  bool get hasScores => topScores.isNotEmpty;

  String get answeredItemsLabel {
    if (answerCount != null && totalQuestions != null && totalQuestions! > 0) {
      return '$answerCount de $totalQuestions itens';
    }
    if (answerCount != null) {
      return '$answerCount itens respondidos';
    }
    return 'Respostas registradas';
  }
}
