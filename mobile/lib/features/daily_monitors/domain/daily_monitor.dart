/// Registro em `daily_monitors` (humor, sono, atividade, emoções).
class DailyMonitor {
  const DailyMonitor({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.moodNotes,
    this.sleepNotes,
    this.activityNotes,
    this.emotionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? moodNotes;
  final String? sleepNotes;
  final String? activityNotes;
  final String? emotionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Humor / estado emocional.
  String? get moodState => moodNotes?.trim().isEmpty == true ? null : moodNotes?.trim();

  /// Observações gerais (inclui sono quando informado).
  String? get observations =>
      sleepNotes?.trim().isEmpty == true ? null : sleepNotes?.trim();

  /// Comportamentos / atividades.
  String? get behaviors =>
      activityNotes?.trim().isEmpty == true ? null : activityNotes?.trim();

  /// Gatilhos e intensidade (parse de `emotion_notes`).
  ({int? intensity, String? triggers}) get emotionPayload =>
      parseEmotionNotes(emotionNotes);

  bool get isEditableToday {
    final now = DateTime.now();
    final localCreated = createdAt.toLocal();
    return localCreated.year == now.year &&
        localCreated.month == now.month &&
        localCreated.day == now.day;
  }

  String get summaryLine {
    final mood = moodState;
    if (mood != null && mood.isNotEmpty) {
      final short = mood.length > 60 ? '${mood.substring(0, 60)}…' : mood;
      return short;
    }
    final intensity = emotionPayload.intensity;
    if (intensity != null) return 'Intensidade $intensity/10';
    return 'Registro diário';
  }

  factory DailyMonitor.fromJson(Map<String, dynamic> json) {
    return DailyMonitor(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      moodNotes: json['mood_notes'] as String?,
      sleepNotes: json['sleep_notes'] as String?,
      activityNotes: json['activity_notes'] as String?,
      emotionNotes: json['emotion_notes'] as String?,
      createdAt: parseDateTime(json['created_at'])!,
      updatedAt: parseDateTime(json['updated_at'])!,
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        'mood_notes': moodNotes,
        'sleep_notes': sleepNotes,
        'activity_notes': activityNotes,
        'emotion_notes': emotionNotes,
      };
}

DateTime? parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

/// Monta `emotion_notes` com intensidade + gatilhos.
String? buildEmotionNotes({int? intensity, String? triggers}) {
  final parts = <String>[];
  if (intensity != null) {
    parts.add('Intensidade: $intensity/10');
  }
  final t = triggers?.trim();
  if (t != null && t.isNotEmpty) {
    parts.add('Gatilhos: $t');
  }
  if (parts.isEmpty) return null;
  return parts.join('\n');
}

/// Extrai intensidade e gatilhos de `emotion_notes`.
({int? intensity, String? triggers}) parseEmotionNotes(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return (intensity: null, triggers: null);
  }

  int? intensity;
  final lines = raw.split('\n');
  final triggerLines = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    final intensityMatch = RegExp(
      r'^Intensidade:\s*(\d{1,2})\s*/\s*10\s*$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (intensityMatch != null) {
      intensity = int.tryParse(intensityMatch.group(1)!);
      continue;
    }
    final triggerMatch = RegExp(
      r'^Gatilhos:\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(trimmed);
    if (triggerMatch != null) {
      final rest = triggerMatch.group(1)!.trim();
      if (rest.isNotEmpty) triggerLines.add(rest);
      continue;
    }
    if (trimmed.isNotEmpty) triggerLines.add(trimmed);
  }

  final triggers =
      triggerLines.isEmpty ? null : triggerLines.join('\n').trim();

  return (intensity: intensity, triggers: triggers);
}
