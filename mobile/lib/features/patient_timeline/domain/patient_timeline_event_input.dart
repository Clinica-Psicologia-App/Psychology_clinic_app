import 'patient_timeline_event.dart';

class PatientTimelineEventInput {
  const PatientTimelineEventInput({
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
    this.isSensitive = false,
  });

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

  factory PatientTimelineEventInput.fromEvent(PatientTimelineEvent event) {
    return PatientTimelineEventInput(
      title: event.title,
      description: event.description,
      eventDate: event.eventDate,
      periodLabel: event.periodLabel,
      category: event.category,
      emotionalImpact: event.emotionalImpact,
      emotionalNeedKeys: event.emotionalNeedKeys,
      emotionalNeedOther: event.emotionalNeedOther,
      emotionsFelt: event.emotionsFelt,
      selfMeaning: event.selfMeaning,
      othersMeaning: event.othersMeaning,
      worldMeaning: event.worldMeaning,
      copingKeys: event.copingKeys,
      copingOther: event.copingOther,
      presentInfluence: event.presentInfluence,
      presentAreaKeys: event.presentAreaKeys,
      presentReaction: event.presentReaction,
      isSensitive: event.isSensitive,
    );
  }

  String? validate() {
    if (title.trim().isEmpty) return 'Informe o título do evento.';
    if (title.trim().length > 200) {
      return 'Título muito longo (máx. 200 caracteres).';
    }
    if (emotionalImpact != null &&
        (emotionalImpact! < 0 || emotionalImpact! > 10)) {
      return 'Impacto emocional deve ser entre 0 e 10.';
    }
    if (presentInfluence != null &&
        (presentInfluence! < 0 || presentInfluence! > 10)) {
      return 'Influência atual deve ser entre 0 e 10.';
    }
    if (emotionalNeedKeys.contains('other') &&
        _nullableTrim(emotionalNeedOther) == null) {
      return 'Descreva a outra necessidade emocional.';
    }
    if (copingKeys.contains('other') && _nullableTrim(copingOther) == null) {
      return 'Descreva a outra forma de lidar.';
    }
    return null;
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title.trim(),
      'description': _nullableTrim(description),
      if (eventDate != null) 'event_date': _formatDate(eventDate!),
      'period_label': _nullableTrim(periodLabel),
      'category': _nullableTrim(category),
      if (emotionalImpact != null) 'emotional_impact': emotionalImpact,
      'emotional_need_keys': _cleanList(emotionalNeedKeys),
      'emotional_need_other': _nullableTrim(emotionalNeedOther),
      'emotions_felt': _nullableTrim(emotionsFelt),
      'self_meaning': _nullableTrim(selfMeaning),
      'others_meaning': _nullableTrim(othersMeaning),
      'world_meaning': _nullableTrim(worldMeaning),
      'coping_keys': _cleanList(copingKeys),
      'coping_other': _nullableTrim(copingOther),
      'present_influence': presentInfluence,
      'present_area_keys': _cleanList(presentAreaKeys),
      'present_reaction': _nullableTrim(presentReaction),
      'is_sensitive': isSensitive,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title.trim(),
      'description': _nullableTrim(description),
      'event_date': eventDate != null ? _formatDate(eventDate!) : null,
      'period_label': _nullableTrim(periodLabel),
      'category': _nullableTrim(category),
      'emotional_impact': emotionalImpact,
      'emotional_need_keys': _cleanList(emotionalNeedKeys),
      'emotional_need_other': _nullableTrim(emotionalNeedOther),
      'emotions_felt': _nullableTrim(emotionsFelt),
      'self_meaning': _nullableTrim(selfMeaning),
      'others_meaning': _nullableTrim(othersMeaning),
      'world_meaning': _nullableTrim(worldMeaning),
      'coping_keys': _cleanList(copingKeys),
      'coping_other': _nullableTrim(copingOther),
      'present_influence': presentInfluence,
      'present_area_keys': _cleanList(presentAreaKeys),
      'present_reaction': _nullableTrim(presentReaction),
      'is_sensitive': isSensitive,
    };
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  static List<String> _cleanList(List<String> values) {
    return values
        .map((value) => value.trim())
        .where((value) {
          return value.isNotEmpty;
        })
        .toSet()
        .toList()
      ..sort();
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Ordenação cronológica: data conhecida (mais recente primeiro), depois sem data por `created_at`.
List<PatientTimelineEvent> sortTimelineEventsChronologically(
  List<PatientTimelineEvent> events,
) {
  final copy = List<PatientTimelineEvent>.from(events);
  copy.sort(compareTimelineEventsChronologically);
  return copy;
}

int compareTimelineEventsChronologically(
  PatientTimelineEvent a,
  PatientTimelineEvent b,
) {
  final aHasDate = a.eventDate != null;
  final bHasDate = b.eventDate != null;

  if (aHasDate && bHasDate) {
    final byDate = b.eventDate!.compareTo(a.eventDate!);
    if (byDate != 0) return byDate;
    return b.createdAt.compareTo(a.createdAt);
  }
  if (aHasDate && !bHasDate) return -1;
  if (!aHasDate && bHasDate) return 1;

  final aPeriod = a.periodLabel?.trim() ?? '';
  final bPeriod = b.periodLabel?.trim() ?? '';
  if (aPeriod.isNotEmpty && bPeriod.isNotEmpty) {
    final byPeriod = bPeriod.compareTo(aPeriod);
    if (byPeriod != 0) return byPeriod;
  }

  return b.createdAt.compareTo(a.createdAt);
}
