import 'life_chapter.dart';
import 'timeline_belief.dart';

/// Um evento da Linha do Tempo na visão da Tela 2 (Minha História).
/// Lê `patient_timeline_events`; o `clinicalComment` (staff-only) vem mesclado
/// de `patient_timeline_event_notes`.
class TimelineEntry {
  const TimelineEntry({
    required this.id,
    required this.patientId,
    this.lifeChapter,
    required this.title,
    this.description,
    this.ageAtEvent,
    this.emotionalImpact,
    this.beliefs = const [],
    this.beliefOther,
    this.isSensitive = false,
    this.clinicalComment,
    this.filledByRole,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final LifeChapter? lifeChapter;
  final String title;
  final String? description;
  final int? ageAtEvent;
  final int? emotionalImpact; // 0–10
  final List<TimelineBelief> beliefs;
  final String? beliefOther;
  final bool isSensitive;

  /// Comentário clínico do terapeuta (staff-only).
  final String? clinicalComment;
  final String? filledByRole;
  final DateTime? createdAt;

  factory TimelineEntry.fromJson(Map<String, dynamic> json) {
    return TimelineEntry(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      lifeChapter: lifeChapterFromKey(json['life_chapter'] as String?),
      title: json['title'] as String,
      description: json['description'] as String?,
      ageAtEvent: (json['age_at_event'] as num?)?.toInt(),
      emotionalImpact: (json['emotional_impact'] as num?)?.toInt(),
      beliefs: timelineBeliefsFromKeys(json['belief_keys']),
      beliefOther: json['belief_other'] as String?,
      isSensitive: json['is_sensitive'] as bool? ?? false,
      filledByRole: json['filled_by_role'] as String?,
      createdAt: _parse(json['created_at']),
    );
  }

  TimelineEntry copyWith({String? clinicalComment}) {
    return TimelineEntry(
      id: id,
      patientId: patientId,
      lifeChapter: lifeChapter,
      title: title,
      description: description,
      ageAtEvent: ageAtEvent,
      emotionalImpact: emotionalImpact,
      beliefs: beliefs,
      beliefOther: beliefOther,
      isSensitive: isSensitive,
      clinicalComment: clinicalComment ?? this.clinicalComment,
      filledByRole: filledByRole,
      createdAt: createdAt,
    );
  }

  static DateTime? _parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
