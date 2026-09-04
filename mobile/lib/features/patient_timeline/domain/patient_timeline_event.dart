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
    this.emotionalNeedKeys = const [],
    this.emotionalNeedOther,
    this.emotionsFelt,
    this.selfMeaning,
    this.othersMeaning,
    this.worldMeaning,
    this.copingKeys = const [],
    this.copingOther,
    this.presentInfluence,
    this.presentAreaKeys = const [],
    this.presentReaction,
    required this.isSensitive,
    this.relatedPersonIds = const [],
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
  final List<String> emotionalNeedKeys;
  final String? emotionalNeedOther;
  final String? emotionsFelt;
  final String? selfMeaning;
  final String? othersMeaning;
  final String? worldMeaning;
  final List<String> copingKeys;
  final String? copingOther;
  final int? presentInfluence;
  final List<String> presentAreaKeys;
  final String? presentReaction;
  final bool isSensitive;

  /// Pessoas do genograma relacionadas a este evento (junção
  /// `timeline_event_people`) — o elo que permite navegar do genograma
  /// direto para o(s) evento(s) daquela pessoa.
  final List<String> relatedPersonIds;
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
    if (presentInfluence != null) {
      parts.add('Influência atual $presentInfluence/10');
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
      emotionalNeedKeys: _parseStringList(json['emotional_need_keys']),
      emotionalNeedOther: json['emotional_need_other'] as String?,
      emotionsFelt: json['emotions_felt'] as String?,
      selfMeaning: json['self_meaning'] as String?,
      othersMeaning: json['others_meaning'] as String?,
      worldMeaning: json['world_meaning'] as String?,
      copingKeys: _parseStringList(json['coping_keys']),
      copingOther: json['coping_other'] as String?,
      presentInfluence: json['present_influence'] as int?,
      presentAreaKeys: _parseStringList(json['present_area_keys']),
      presentReaction: json['present_reaction'] as String?,
      isSensitive: json['is_sensitive'] as bool? ?? false,
      relatedPersonIds: [
        for (final j in (json['timeline_event_people'] as List? ?? []))
          (j as Map)['person_id'] as String,
      ],
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

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const [];
  }
}
