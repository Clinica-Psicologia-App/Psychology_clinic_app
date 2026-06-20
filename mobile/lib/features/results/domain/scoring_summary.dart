import '../utils/json_parsing.dart';

/// Resumo geral da apuração DEMO (`snapshot.summary`).
class ScoringSummary {
  const ScoringSummary({
    this.rawScore,
    this.weightedScore,
    this.averageScore,
    this.answeredItems,
    this.maxPossibleScore,
  });

  final double? rawScore;
  final double? weightedScore;
  final double? averageScore;
  final int? answeredItems;
  final double? maxPossibleScore;

  static const empty = ScoringSummary();

  factory ScoringSummary.fromJson(dynamic raw) {
    if (raw is! Map) return ScoringSummary.empty;

    final map = Map<String, dynamic>.from(raw);
    return ScoringSummary(
      rawScore: asDouble(map['raw_score']),
      weightedScore: asDouble(map['weighted_score']),
      averageScore: asDouble(map['average_score']),
      answeredItems: asInt(map['answered_items']),
      maxPossibleScore: asDouble(map['max_possible_score']),
    );
  }

  bool get hasContent =>
      rawScore != null ||
      weightedScore != null ||
      averageScore != null ||
      answeredItems != null;
}
