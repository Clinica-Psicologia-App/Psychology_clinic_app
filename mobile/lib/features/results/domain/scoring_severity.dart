import '../utils/json_parsing.dart';

/// Faixa de severidade DEMO (sem interpretação clínica).
class ScoringSeverity {
  const ScoringSeverity({
    required this.label,
    this.colorKey,
    this.minScore,
    this.maxScore,
  });

  final String label;
  final String? colorKey;
  final double? minScore;
  final double? maxScore;

  factory ScoringSeverity.fromJson(dynamic raw) {
    if (raw is! Map) return const ScoringSeverity(label: '—');

    final map = Map<String, dynamic>.from(raw);
    final label = map['label'] as String?;
    if (label == null || label.trim().isEmpty) {
      return const ScoringSeverity(label: '—');
    }

    return ScoringSeverity(
      label: label,
      colorKey: map['color_key'] as String?,
      minScore: asDouble(map['min_score']),
      maxScore: asDouble(map['max_score']),
    );
  }

  bool get hasLabel => label != '—' && label.isNotEmpty;
}
