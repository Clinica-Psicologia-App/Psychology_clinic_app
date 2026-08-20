import 'life_story_enums.dart';

/// Um acontecimento da Linha do Tempo do paciente — núcleo do fluxo Conhecer.
///
/// Cobre as 4 etapas essenciais: quando (período + idade), o quê (título +
/// relato), quem (pessoas via junção) e como se sentiu (emoções + impacto).
/// Os campos de "aprofundar" (área, necessidade, significado, hoje) não fazem
/// parte deste núcleo e entram depois.
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
    this.createdAt,
  });

  final String id;
  final String patientId;

  /// Etapa 2 (§5) — título curto (vira o rótulo do marco) e relato livre.
  final String title;
  final String? description;

  /// Etapa 1 (§4) — período da vida, idade e precisão da idade.
  final LifeChapter? lifeChapter;
  final int? ageAtEvent;
  final AgePrecision? agePrecision;

  /// Etapa 6 (§9) — emoções sentidas (até 3) e intensidade na época (0–10).
  final List<TimelineEmotion> emotions;
  final String? emotionOther;
  final int? emotionalImpact;

  /// Etapa 5 (§8) — ids das pessoas que participaram (junção com genograma).
  final List<String> peopleIds;

  final DateTime? createdAt;

  factory LifeTimelineEvent.fromJson(
    Map<String, dynamic> json, {
    List<String> peopleIds = const [],
  }) {
    final rawEmotions = (json['emotion_keys'] as List?) ?? const [];
    return LifeTimelineEvent(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      lifeChapter: lifeChapterFromKey(json['life_chapter'] as String?),
      ageAtEvent: (json['age_at_event'] as num?)?.toInt(),
      agePrecision: agePrecisionFromKey(json['age_precision'] as String?),
      emotions: [
        for (final k in rawEmotions)
          if (timelineEmotionFromKey(k as String?) case final e?) e,
      ],
      emotionOther: json['emotion_other'] as String?,
      emotionalImpact: (json['emotional_impact'] as num?)?.toInt(),
      peopleIds: peopleIds,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
    );
  }

  /// Payload para inserir/atualizar em `patient_timeline_events` (sem as
  /// pessoas, que vão na tabela de junção separadamente).
  Map<String, dynamic> toRow() => {
        'title': title.trim(),
        'description': description,
        'life_chapter': lifeChapter?.key,
        'age_at_event': ageAtEvent,
        'age_precision': agePrecision?.key,
        'emotion_keys': emotions.map((e) => e.key).toList(),
        'emotion_other': emotionOther,
        'emotional_impact': emotionalImpact,
      };
}
