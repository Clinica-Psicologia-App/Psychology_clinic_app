import 'patient_timeline_event.dart';

class PatientTimelineEventInput {
  const PatientTimelineEventInput({
    required this.title,
    this.description,
    this.eventDate,
    this.periodLabel,
    this.category,
    this.emotionalImpact,
    this.isSensitive = false,
  });

  final String title;
  final String? description;
  final DateTime? eventDate;
  final String? periodLabel;
  final String? category;
  final int? emotionalImpact;
  final bool isSensitive;

  factory PatientTimelineEventInput.fromEvent(PatientTimelineEvent event) {
    return PatientTimelineEventInput(
      title: event.title,
      description: event.description,
      eventDate: event.eventDate,
      periodLabel: event.periodLabel,
      category: event.category,
      emotionalImpact: event.emotionalImpact,
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
      'is_sensitive': isSensitive,
    };
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
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
