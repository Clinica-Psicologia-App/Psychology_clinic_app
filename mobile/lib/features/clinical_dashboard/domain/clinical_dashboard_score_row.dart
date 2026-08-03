/// Linha de score para gráfico horizontal (sem interpretação clínica).
class ClinicalDashboardScoreRow {
  const ClinicalDashboardScoreRow({
    required this.name,
    required this.code,
    required this.score,
    this.averageScore,
    this.severityLabel,
    this.severityColorKey,
  });

  final String name;
  final String code;

  /// Score de exibição (weighted → average → raw), usado nas barras.
  final double score;

  /// Média por item do esquema — métrica calibrada para o limiar de ativação
  /// (`kSchemaActivationThreshold`). Mantida separada de [score] porque a
  /// exibição usa o weighted, mas a ativação precisa da média (mesma regra da
  /// tela de detalhe do questionário).
  final double? averageScore;

  final String? severityLabel;
  final String? severityColorKey;

  bool get hasSeverity =>
      severityLabel != null && severityLabel!.trim().isNotEmpty;
}
