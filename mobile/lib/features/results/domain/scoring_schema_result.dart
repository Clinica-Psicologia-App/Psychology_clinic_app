import '../utils/json_parsing.dart';
import 'scoring_severity.dart';

/// Agregação DEMO por esquema (`snapshot.schemas[]`).
class ScoringSchemaResult {
  const ScoringSchemaResult({
    required this.id,
    required this.code,
    required this.name,
    this.rawScore,
    this.weightedScore,
    this.averageScore,
    this.answeredItems,
    this.maxPossibleScore,
    this.severity,
    this.professionalAverageScore,
  });

  final String id;
  final String code;
  final String name;
  final double? rawScore;
  final double? weightedScore;
  final double? averageScore;
  final int? answeredItems;
  final double? maxPossibleScore;
  final ScoringSeverity? severity;
  final double? professionalAverageScore;

  factory ScoringSchemaResult.fromJson(Map<String, dynamic> json) {
    final severityRaw = json['severity'];
    return ScoringSchemaResult(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '-',
      name: json['name'] as String? ?? '-',
      rawScore: asDouble(json['raw_score']),
      weightedScore: asDouble(json['weighted_score']),
      averageScore: asDouble(json['average_score']),
      answeredItems: asInt(json['answered_items']),
      maxPossibleScore: asDouble(json['max_possible_score']),
      severity:
          severityRaw != null ? ScoringSeverity.fromJson(severityRaw) : null,
      professionalAverageScore: asDouble(json['professional_average_score']),
    );
  }

  bool get hasSeverity => severity?.hasLabel ?? false;
}
