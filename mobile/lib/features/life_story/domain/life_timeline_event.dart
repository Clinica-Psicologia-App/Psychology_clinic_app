import 'life_story_deepen_enums.dart';
import 'life_story_enums.dart';

/// Um acontecimento da Linha do Tempo do paciente (etapa Conhecer, Tela 2).
///
/// Núcleo (sempre preenchido): quando, o quê, quem, como se sentiu.
/// Aprofundar (opcional, depois): evento/período, área, do que precisava,
/// significado, e hoje.
class LifeTimelineEvent {
  const LifeTimelineEvent({
    required this.id,
    required this.patientId,
    required this.title,
    this.description,
    this.lifeChapter,
    this.ageAtEvent,
    this.agePrecision,
    this.emotions = const [],
    this.emotionOther,
    this.emotionalImpact,
    this.peopleIds = const [],
    // Aprofundar
    this.eventRecurrence,
    this.ageFrom,
    this.ageTo,
    this.categories = const [],
    this.needs = const [],
    this.needOther,
    this.needWasMet,
    this.meaning,
    this.presentInfluence,
    this.stillInfluences,
    this.presentAreas = const [],
    this.createdAt,
  });

  final String id;
  final String patientId;

  // ── Núcleo ─────────────────────────────────────────────────────────────
  final String title;
  final String? description;
  final LifeChapter? lifeChapter;
  final int? ageAtEvent;
  final AgePrecision? agePrecision;
  final List<TimelineEmotion> emotions;
  final String? emotionOther;
  final int? emotionalImpact;
  final List<String> peopleIds;

  // ── Aprofundar ─────────────────────────────────────────────────────────
  /// Etapa 3 (§6) — evento pontual ou período prolongado.
  final EventRecurrence? eventRecurrence;
  final int? ageFrom;
  final int? ageTo;

  /// Etapa 4 (§7) — área(s) da vida, até 2.
  final List<LifeCategory> categories;

  /// Etapa 7 (§10) — do que precisava e se recebeu.
  final List<EmotionalNeed> needs;
  final String? needOther;
  final NeedWasMet? needWasMet;

  /// Etapa 8 (§11) — significado atribuído (campo aberto único).
  final String? meaning;

  /// Etapa 9 (§12) — repercussão atual.
  final int? presentInfluence;
  final StillInfluences? stillInfluences;
  final List<PresentArea> presentAreas;

  final DateTime? createdAt;

  bool get hasDeepenData =>
      eventRecurrence != null ||
      categories.isNotEmpty ||
      needs.isNotEmpty ||
      (meaning ?? '').trim().isNotEmpty ||
      presentInfluence != null ||
      stillInfluences != null;

  factory LifeTimelineEvent.fromJson(
    Map<String, dynamic> json, {
    List<String> peopleIds = const [],
  }) {
    List<T> mapKeys<T>(String col, T? Function(String?) from) => [
          for (final k in (json[col] as List?) ?? const [])
            if (from(k as String?) case final v?) v,
        ];

    return LifeTimelineEvent(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      lifeChapter: lifeChapterFromKey(json['life_chapter'] as String?),
      ageAtEvent: (json['age_at_event'] as num?)?.toInt(),
      agePrecision: agePrecisionFromKey(json['age_precision'] as String?),
      emotions: mapKeys('emotion_keys', timelineEmotionFromKey),
      emotionOther: json['emotion_other'] as String?,
      emotionalImpact: (json['emotional_impact'] as num?)?.toInt(),
      peopleIds: peopleIds,
      eventRecurrence:
          eventRecurrenceFromKey(json['event_recurrence'] as String?),
      ageFrom: (json['age_from'] as num?)?.toInt(),
      ageTo: (json['age_to'] as num?)?.toInt(),
      categories: mapKeys('category_keys', lifeCategoryFromKey),
      needs: mapKeys('emotional_need_keys', emotionalNeedFromKey),
      needOther: json['emotional_need_other'] as String?,
      needWasMet: needWasMetFromKey(json['need_was_met'] as String?),
      meaning: json['meaning'] as String?,
      presentInfluence: (json['present_influence'] as num?)?.toInt(),
      stillInfluences:
          stillInfluencesFromKey(json['still_influences'] as String?),
      presentAreas: mapKeys('present_area_keys', presentAreaFromKey),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toRow() => {
        'title': title.trim(),
        'description': description,
        'life_chapter': lifeChapter?.key,
        'age_at_event': ageAtEvent,
        'age_precision': agePrecision?.key,
        'emotion_keys': emotions.map((e) => e.key).toList(),
        'emotion_other': emotionOther,
        'emotional_impact': emotionalImpact,
        // Aprofundar
        'event_recurrence': eventRecurrence?.key,
        'age_from': ageFrom,
        'age_to': ageTo,
        'category_keys': categories.map((c) => c.key).toList(),
        'emotional_need_keys': needs.map((n) => n.key).toList(),
        'emotional_need_other': needOther,
        'need_was_met': needWasMet?.key,
        'meaning': meaning,
        'present_influence': presentInfluence,
        'still_influences': stillInfluences?.key,
        'present_area_keys': presentAreas.map((a) => a.key).toList(),
      };
}
