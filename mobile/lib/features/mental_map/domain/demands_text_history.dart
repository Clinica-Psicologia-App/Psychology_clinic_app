/// Histórico das versões anteriores dos quatro textos de "Demandas
/// terapêuticas" (motivos e impressões, inicial e atual). Fica em
/// `case_conceptualizations.demands_history` (coluna opcional).
library;

/// Chaves dos textos versionados.
abstract final class DemandsTextField {
  static const reasonsInitial = 'motivo_initial';
  static const reasonsCurrent = 'motivo_current';
  static const impressionsInitial = 'impressions_initial';
  static const impressionsCurrent = 'impressions_current';
}

class TextRevision {
  const TextRevision({required this.text, required this.savedAt, this.savedBy});

  /// Texto que foi substituído.
  final String text;

  /// Quando esta versão deixou de valer (ISO-8601, UTC).
  final String savedAt;
  final String? savedBy;

  factory TextRevision.fromJson(Map<String, dynamic> j) => TextRevision(
        text: (j['text'] as String?) ?? '',
        savedAt: (j['saved_at'] as String?) ?? '',
        savedBy: j['saved_by'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'text': text,
        'saved_at': savedAt,
        if ((savedBy ?? '').trim().isNotEmpty) 'saved_by': savedBy,
      };
}

class DemandsTextHistory {
  const DemandsTextHistory([this.byField = const {}]);

  final Map<String, List<TextRevision>> byField;

  static const empty = DemandsTextHistory();

  List<TextRevision> revisionsOf(String field) => byField[field] ?? const [];

  bool get isEmpty => byField.values.every((l) => l.isEmpty);

  /// Devolve um novo histórico com [previousText] (se houver e se mudou)
  /// guardado como versão anterior de [field]. Mais recente primeiro.
  DemandsTextHistory withReplaced(
    String field, {
    required String? previousText,
    required String? newText,
    required DateTime now,
    String? author,
  }) {
    final prev = (previousText ?? '').trim();
    if (prev.isEmpty || prev == (newText ?? '').trim()) return this;
    return DemandsTextHistory({
      ...byField,
      field: [
        TextRevision(
          text: prev,
          savedAt: now.toUtc().toIso8601String(),
          savedBy: author,
        ),
        ...revisionsOf(field),
      ],
    });
  }

  factory DemandsTextHistory.fromJson(Map<String, dynamic> j) =>
      DemandsTextHistory({
        for (final e in j.entries)
          if (e.value is List)
            e.key: [
              for (final r in e.value as List)
                if (r is Map)
                  TextRevision.fromJson(Map<String, dynamic>.from(r)),
            ],
      });

  Map<String, dynamic> toJson() => {
        for (final e in byField.entries)
          if (e.value.isNotEmpty) e.key: [for (final r in e.value) r.toJson()],
      };
}
