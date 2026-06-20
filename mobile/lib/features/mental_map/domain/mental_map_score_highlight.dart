/// Destaque numérico de esquema/modo/domínio (sem interpretação clínica).
class MentalMapScoreHighlight {
  const MentalMapScoreHighlight({
    required this.name,
    required this.code,
    required this.kind,
    this.score,
    this.scoreLabel,
  });

  final String name;
  final String code;

  /// `schema`, `domain` ou `category`.
  final String kind;
  final double? score;
  final String? scoreLabel;

  String get displayScore {
    if (scoreLabel != null && scoreLabel!.isNotEmpty) return scoreLabel!;
    if (score == null) return '-';
    return score!.toStringAsFixed(2);
  }
}
