/// Evento resumido para M3 (timeline).
class MentalMapTimelineHighlight {
  const MentalMapTimelineHighlight({
    required this.id,
    required this.displayTitle,
    required this.dateLabel,
    required this.isSensitive,
    this.emotionalImpact,
    this.subtitleLine,
  });

  final String id;
  final String displayTitle;
  final String dateLabel;
  final bool isSensitive;
  final int? emotionalImpact;
  final String? subtitleLine;
}

/// Pessoa resumida do genograma para M3.
class MentalMapGenogramPersonHighlight {
  const MentalMapGenogramPersonHighlight({
    required this.id,
    required this.displayName,
    required this.isSensitive,
    this.relationshipToPatient,
    this.isDeceased = false,
  });

  final String id;
  final String displayName;
  final bool isSensitive;
  final String? relationshipToPatient;
  final bool isDeceased;
}

/// Relação resumida do genograma para M3.
class MentalMapGenogramRelationshipHighlight {
  const MentalMapGenogramRelationshipHighlight({
    required this.id,
    required this.displayLabel,
    required this.isSensitive,
  });

  final String id;
  final String displayLabel;
  final bool isSensitive;
}

/// Figura parental com estilo dominante (M3).
class MentalMapParentalFigureHighlight {
  const MentalMapParentalFigureHighlight({
    required this.figureLabel,
    required this.dominantStyle,
  });

  final String figureLabel;
  final String dominantStyle;
}

/// Camada M3 — história e vínculos.
class MentalMapHistoryLinks {
  const MentalMapHistoryLinks({
    required this.timelineEvents,
    required this.genogramPeople,
    required this.genogramRelationships,
    required this.parentalFigures,
    this.topAttachmentStyle,
    this.peopleCount = 0,
    this.relationshipCount = 0,
    this.sensitiveItemCount = 0,
  });

  static const empty = MentalMapHistoryLinks(
    timelineEvents: [],
    genogramPeople: [],
    genogramRelationships: [],
    parentalFigures: [],
  );

  final List<MentalMapTimelineHighlight> timelineEvents;
  final List<MentalMapGenogramPersonHighlight> genogramPeople;
  final List<MentalMapGenogramRelationshipHighlight> genogramRelationships;
  final List<MentalMapParentalFigureHighlight> parentalFigures;
  final String? topAttachmentStyle;
  final int peopleCount;
  final int relationshipCount;
  final int sensitiveItemCount;

  bool get hasTimeline => timelineEvents.isNotEmpty;

  bool get hasGenogram => peopleCount > 0 || relationshipCount > 0;

  bool get hasParentalFigures => parentalFigures.isNotEmpty;

  bool get hasAttachment => topAttachmentStyle != null;

  bool get hasContent =>
      hasTimeline || hasGenogram || hasParentalFigures || hasAttachment;
}
