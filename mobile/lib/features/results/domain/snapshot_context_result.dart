import 'scoring_schema_result.dart';
import 'scoring_summary.dart';

class SnapshotContextResult {
  const SnapshotContextResult({
    required this.id,
    required this.key,
    required this.label,
    required this.status,
    this.completedAt,
    this.answerCount,
    this.totalQuestions,
    this.completionRatio,
    this.summary = ScoringSummary.empty,
    this.schemas = const [],
  });

  final String id;
  final String key;
  final String label;
  final String status;
  final DateTime? completedAt;
  final int? answerCount;
  final int? totalQuestions;
  final double? completionRatio;
  final ScoringSummary summary;
  final List<ScoringSchemaResult> schemas;

  factory SnapshotContextResult.fromJson(Map<String, dynamic> json) {
    final schemasRaw = json['schemas'] as List? ?? [];
    return SnapshotContextResult(
      id: json['id'] as String? ?? '',
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? 'Figura parental',
      status: json['status'] as String? ?? 'draft',
      completedAt: _parseDateTime(json['completed_at']),
      answerCount: _asInt(json['answer_count']),
      totalQuestions: _asInt(json['total_questions']),
      completionRatio: _asDouble(json['completion_ratio']),
      summary: ScoringSummary.fromJson(json['summary']),
      schemas: schemasRaw
          .whereType<Map>()
          .map((item) => ScoringSchemaResult.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
