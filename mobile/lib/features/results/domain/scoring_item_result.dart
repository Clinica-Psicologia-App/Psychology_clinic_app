import '../utils/json_parsing.dart';

/// Item respondido com apuração DEMO (`snapshot.items[]` enriquecido).
class ScoringItemResult {
  const ScoringItemResult({
    this.questionId,
    this.answerValue,
    this.rawScore,
    this.adjustedScore,
    this.weight,
    this.weightedScore,
    this.reverseScore = false,
    this.schemaCode,
    this.schemaName,
    this.domainCode,
    this.domainName,
  });

  final String? questionId;
  final double? answerValue;
  final double? rawScore;
  final double? adjustedScore;
  final double? weight;
  final double? weightedScore;
  final bool reverseScore;
  final String? schemaCode;
  final String? schemaName;
  final String? domainCode;
  final String? domainName;

  factory ScoringItemResult.fromJson(Map<String, dynamic> json) {
    return ScoringItemResult(
      questionId: json['question_id'] as String?,
      answerValue: asDouble(json['answer_value']),
      rawScore: asDouble(json['raw_score']),
      adjustedScore: asDouble(json['adjusted_score']),
      weight: asDouble(json['weight']),
      weightedScore: asDouble(json['weighted_score']),
      reverseScore: json['reverse_score'] == true,
      schemaCode: json['schema_code'] as String?,
      schemaName: json['schema_name'] as String?,
      domainCode: json['domain_code'] as String?,
      domainName: json['domain_name'] as String?,
    );
  }

  bool get hasScoringFields =>
      adjustedScore != null || schemaCode != null || domainCode != null;
}
