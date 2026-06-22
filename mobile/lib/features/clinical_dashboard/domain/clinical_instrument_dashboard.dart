import 'clinical_dashboard_score_row.dart';

/// Painel de um instrumento (YSQ ou YAMI) com última resposta concluída.
class ClinicalInstrumentDashboard {
  const ClinicalInstrumentDashboard({
    required this.responseId,
    required this.questionnaireCode,
    required this.questionnaireName,
    this.completedAt,
    required this.topScores,
    this.allScores = const [],
    this.domainRows = const [],
    this.scaleMax,
  });

  final String responseId;
  final String questionnaireCode;
  final String questionnaireName;
  final DateTime? completedAt;

  /// Top N scores (padrão: 8), mostrados por padrão.
  final List<ClinicalDashboardScoreRow> topScores;

  /// Todos os scores do instrumento ordenados por score (D2).
  final List<ClinicalDashboardScoreRow> allScores;

  /// Scores agrupados por domínio clínico (D5 — YSQ com snapshot demo).
  final List<ClinicalDashboardScoreRow> domainRows;

  final double? scaleMax;

  bool get isEmpty => topScores.isEmpty;
  bool get hasMoreScores => allScores.length > topScores.length;
  bool get hasDomains => domainRows.isNotEmpty;

  double get barMaxScore {
    if (scaleMax != null && scaleMax! > 0) return scaleMax!;
    final scores = allScores.isNotEmpty ? allScores : topScores;
    if (scores.isEmpty) return 6;
    return scores.map((r) => r.score).reduce((a, b) => a > b ? a : b);
  }
}
