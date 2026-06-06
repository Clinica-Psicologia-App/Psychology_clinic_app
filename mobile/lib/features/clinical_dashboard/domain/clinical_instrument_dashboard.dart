import 'clinical_dashboard_score_row.dart';

/// Painel de um instrumento (YSQ ou YAMI) com última resposta concluída.
class ClinicalInstrumentDashboard {
  const ClinicalInstrumentDashboard({
    required this.responseId,
    required this.questionnaireCode,
    required this.questionnaireName,
    this.completedAt,
    required this.topScores,
    this.scaleMax,
  });

  final String responseId;
  final String questionnaireCode;
  final String questionnaireName;
  final DateTime? completedAt;
  final List<ClinicalDashboardScoreRow> topScores;
  final double? scaleMax;

  bool get isEmpty => topScores.isEmpty;

  double get barMaxScore {
    if (scaleMax != null && scaleMax! > 0) return scaleMax!;
    if (topScores.isEmpty) return 6;
    return topScores.map((r) => r.score).reduce((a, b) => a > b ? a : b);
  }
}
