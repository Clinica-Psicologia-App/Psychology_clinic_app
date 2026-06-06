class PatientTimelineEvent {
  const PatientTimelineEvent({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.createdBy,
    required this.title,
    this.description,
    this.eventDate,
    this.periodLabel,
    this.category,
    this.emotionalImpact,
    required this.isSensitive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? createdBy;
  final String title;
  final String? description;
  final DateTime? eventDate;
  final String? periodLabel;
  final String? category;
  final int? emotionalImpact;
  final bool isSensitive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get dateLabel {
    if (eventDate != null) {
      final d = eventDate!;
      final day = d.day.toString().padLeft(2, '0');
      final month = d.month.toString().padLeft(2, '0');
      return '$day/$month/${d.year}';
    }
    if (periodLabel != null && periodLabel!.trim().isNotEmpty) {
      return periodLabel!.trim();
    }
    return 'Data não informada';
  }

  String? get subtitleLine {
    final parts = <String>[];
    if (category != null && category!.trim().isNotEmpty) {
      parts.add(category!.trim());
    }
    if (emotionalImpact != null) {
      parts.add('Impacto $emotionalImpact/10');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  factory PatientTimelineEvent.fromJson(Map<String, dynamic> json) {
    return PatientTimelineEvent(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      createdBy: json['created_by'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: _parseDate(json['event_date']),
      periodLabel: json['period_label'] as String?,
      category: json['category'] as String?,
      emotionalImpact: json['emotional_impact'] as int?,
      isSensitive: json['is_sensitive'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value as String;
    final parts = s.split('-');
    if (parts.length != 3) return DateTime.parse(s).toLocal();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
