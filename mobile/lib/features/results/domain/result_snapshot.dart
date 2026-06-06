import '../utils/json_parsing.dart';
import 'scoring_snapshot.dart';
import 'snapshot_context_result.dart';

/// Snapshot JSONB de `questionnaire_results` (finish-questionnaire).
class ResultSnapshot {
  const ResultSnapshot({
    this.version,
    this.categoryCode,
    this.categoryName,
    this.answerCount,
    this.totalWeightedScore,
    this.averageScore,
    this.note,
    this.items = const [],
    this.scoring,
    this.contexts = const [],
  });

  final String? version;
  final String? categoryCode;
  final String? categoryName;
  final int? answerCount;
  final double? totalWeightedScore;
  final double? averageScore;
  final String? note;
  final List<SnapshotItem> items;
  final ScoringSnapshot? scoring;
  final List<SnapshotContextResult> contexts;

  static const empty = ResultSnapshot();

  factory ResultSnapshot.fromJson(dynamic raw) {
    if (raw is! Map) return ResultSnapshot.empty;

    final map = Map<String, dynamic>.from(raw);
    final version = map['version'] as String?;

    final itemsRaw = map['items'];
    final items = <SnapshotItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) {
          items.add(SnapshotItem.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    ScoringSnapshot? scoring;
    if (ScoringSnapshot.isDemoVersion(version) ||
        map['summary'] != null ||
        map['schemas'] != null) {
      final parsed = ScoringSnapshot.fromJsonMap(map);
      if (parsed.hasEngineData || ScoringSnapshot.isDemoVersion(version)) {
        scoring = parsed;
      }
    }

    final contextsRaw = map['contexts'] as List? ?? [];
    final contexts = contextsRaw
        .whereType<Map>()
        .map(
          (entry) => SnapshotContextResult.fromJson(
            Map<String, dynamic>.from(entry),
          ),
        )
        .toList();

    return ResultSnapshot(
      version: version,
      categoryCode: map['category_code'] as String?,
      categoryName: map['category_name'] as String?,
      answerCount: asInt(map['answer_count']),
      totalWeightedScore: asDouble(map['total_weighted_score']),
      averageScore: asDouble(map['average_score']),
      note: map['note'] as String?,
      items: items,
      scoring: scoring,
      contexts: contexts,
    );
  }

  bool get isScoringDemo =>
      ScoringSnapshot.isDemoVersion(version) &&
      (scoring?.hasEngineData ?? false);

  bool get hasContent =>
      categoryCode != null ||
      categoryName != null ||
      totalWeightedScore != null ||
      items.isNotEmpty ||
      contexts.isNotEmpty ||
      isScoringDemo;
}

class SnapshotItem {
  const SnapshotItem({
    this.questionId,
    this.answerValue,
    this.weight,
    this.weightedScore,
  });

  final String? questionId;
  final double? answerValue;
  final double? weight;
  final double? weightedScore;

  factory SnapshotItem.fromJson(Map<String, dynamic> json) {
    return SnapshotItem(
      questionId: json['question_id'] as String?,
      answerValue: asDouble(json['answer_value']),
      weight: asDouble(json['weight']),
      weightedScore: asDouble(json['weighted_score']),
    );
  }
}
