class QuestionnaireResponseContext {
  const QuestionnaireResponseContext({
    required this.id,
    required this.type,
    required this.key,
    required this.label,
    required this.sortOrder,
    required this.status,
    this.completedAt,
  });

  final String id;
  final String type;
  final String key;
  final String label;
  final int sortOrder;
  final String status;
  final DateTime? completedAt;

  factory QuestionnaireResponseContext.fromJson(Map<String, dynamic> json) {
    return QuestionnaireResponseContext(
      id: json['id'] as String,
      type: json['context_type'] as String? ?? 'parental_figure',
      key: json['context_key'] as String? ?? '',
      label: json['context_label'] as String? ?? '',
      sortOrder: json['sort_order'] as int? ?? 0,
      status: json['status'] as String? ?? 'draft',
      completedAt: _parseDateTime(json['completed_at']),
    );
  }
}

class QuestionnaireContextInput {
  const QuestionnaireContextInput({
    required this.key,
    required this.label,
  });

  final String key;
  final String label;

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
      };
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
