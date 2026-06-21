/// Destaque numérico de esquema/modo/domínio com severidade opcional.
class MentalMapScoreHighlight {
  const MentalMapScoreHighlight({
    required this.name,
    required this.code,
    required this.kind,
    this.score,
    this.scoreLabel,
    this.severityColorKey,
  });

  final String name;
  final String code;

  /// `schema`, `domain` ou `category`.
  final String kind;
  final double? score;
  final String? scoreLabel;

  /// Chave de cor de severidade do backend: `green`, `yellow`, `amber`,
  /// `orange` ou `red`. Nulo quando não disponível.
  final String? severityColorKey;

  String get displayScore {
    if (scoreLabel != null && scoreLabel!.isNotEmpty) return scoreLabel!;
    if (score == null) return '-';
    return score!.toStringAsFixed(2);
  }
}
