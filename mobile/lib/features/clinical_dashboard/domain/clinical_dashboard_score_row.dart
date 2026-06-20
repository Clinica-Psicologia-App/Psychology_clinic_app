/// Linha de score para gráfico horizontal (sem interpretação clínica).
class ClinicalDashboardScoreRow {
  const ClinicalDashboardScoreRow({
    required this.name,
    required this.code,
    required this.score,
    this.severityLabel,
    this.severityColorKey,
  });

  final String name;
  final String code;
  final double score;
  final String? severityLabel;
  final String? severityColorKey;

  bool get hasSeverity =>
      severityLabel != null && severityLabel!.trim().isNotEmpty;
}
