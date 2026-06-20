import '../../genogram/domain/genogram_data.dart';
import '../../genogram/domain/genogram_person.dart';
import '../../genogram/domain/genogram_relationship.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import 'mental_case_map_builder.dart';
import 'mental_map_history_links.dart';
import 'mental_map_questionnaire_block.dart';

const _attachmentCode = 'ATTACHMENT_STYLES_V1';
const _timelineLimit = 5;
const _peopleLimit = 4;
const _relationshipLimit = 3;
const _parentalLimit = 4;

MentalMapHistoryLinks buildMentalMapHistoryLinks({
  required List<PatientTimelineEvent> timelineEvents,
  required GenogramData genogramData,
  required List<MentalMapQuestionnaireBlock> questionnaires,
  List<MentalMapQuestionnaireContext> questionnaireContexts = const [],
}) {
  final parentalContext = _findQuestionnaireContext(
    questionnaireContexts,
    'PARENTAL_STYLES_V1',
  );
  final attachmentBlock = _findBlockByCode(questionnaires, _attachmentCode);

  final sortedTimeline = [...timelineEvents]..sort((a, b) {
      final byDate = b.eventDate?.compareTo(a.eventDate ?? DateTime(1900));
      if (byDate != null && byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });

  final peopleById = {
    for (final person in genogramData.people) person.id: person,
  };

  var sensitiveCount = 0;
  for (final event in sortedTimeline.take(_timelineLimit)) {
    if (event.isSensitive) sensitiveCount++;
  }
  for (final person in genogramData.people.take(_peopleLimit)) {
    if (person.isSensitive) sensitiveCount++;
  }
  for (final relationship
      in genogramData.relationships.take(_relationshipLimit)) {
    if (relationship.isSensitive) sensitiveCount++;
  }

  return MentalMapHistoryLinks(
    timelineEvents: sortedTimeline
        .take(_timelineLimit)
        .map(_toTimelineHighlight)
        .toList(growable: false),
    genogramPeople: genogramData.people
        .take(_peopleLimit)
        .map(_toPersonHighlight)
        .toList(growable: false),
    genogramRelationships: genogramData.relationships
        .take(_relationshipLimit)
        .map((relationship) => _toRelationshipHighlight(
              relationship,
              peopleById,
            ))
        .toList(growable: false),
    parentalFigures: _buildParentalFigures(parentalContext),
    topAttachmentStyle: _topAttachmentLabel(attachmentBlock),
    peopleCount: genogramData.people.length,
    relationshipCount: genogramData.relationships.length,
    sensitiveItemCount: sensitiveCount,
  );
}

MentalMapTimelineHighlight _toTimelineHighlight(PatientTimelineEvent event) {
  return MentalMapTimelineHighlight(
    id: event.id,
    displayTitle: event.isSensitive ? 'Evento sensível' : event.title.trim(),
    dateLabel: event.dateLabel,
    isSensitive: event.isSensitive,
    emotionalImpact: event.isSensitive ? null : event.emotionalImpact,
    subtitleLine: event.isSensitive ? 'Conteúdo protegido' : event.subtitleLine,
  );
}

MentalMapGenogramPersonHighlight _toPersonHighlight(GenogramPerson person) {
  return MentalMapGenogramPersonHighlight(
    id: person.id,
    displayName:
        person.isSensitive ? 'Pessoa sensível' : person.displayName.trim(),
    isSensitive: person.isSensitive,
    relationshipToPatient:
        person.isSensitive ? null : person.relationshipToPatient?.trim(),
    isDeceased: person.isDeceased,
  );
}

MentalMapGenogramRelationshipHighlight _toRelationshipHighlight(
  GenogramRelationship relationship,
  Map<String, GenogramPerson> peopleById,
) {
  if (relationship.isSensitive) {
    return MentalMapGenogramRelationshipHighlight(
      id: relationship.id,
      displayLabel: 'Relação sensível',
      isSensitive: true,
    );
  }

  final personA = peopleById[relationship.personAId];
  final personB = peopleById[relationship.personBId];
  final nameA = personA?.isSensitive == true
      ? 'Pessoa sensível'
      : (personA?.displayName ?? 'Pessoa A');
  final nameB = personB?.isSensitive == true
      ? 'Pessoa sensível'
      : (personB?.displayName ?? 'Pessoa B');

  return MentalMapGenogramRelationshipHighlight(
    id: relationship.id,
    displayLabel: relationship.labelBetween(nameA, nameB),
    isSensitive: false,
  );
}

List<MentalMapParentalFigureHighlight> _buildParentalFigures(
  MentalMapQuestionnaireContext? context,
) {
  if (context == null || context.figureSummaries.isEmpty) return const [];

  return context.figureSummaries.take(_parentalLimit).map((summary) {
    final parts = summary.split(' - ');
    if (parts.length >= 2) {
      return MentalMapParentalFigureHighlight(
        figureLabel: parts.first.trim(),
        dominantStyle: parts.sublist(1).join(' - ').trim(),
      );
    }
    return MentalMapParentalFigureHighlight(
      figureLabel: summary.trim(),
      dominantStyle: '-',
    );
  }).toList(growable: false);
}

String? _topAttachmentLabel(MentalMapQuestionnaireBlock? block) {
  if (block == null || block.highlights.isEmpty) return null;
  final top = block.highlights.first;
  if (top.score == null) return top.name.trim();
  return '${top.name.trim()} ${top.displayScore}';
}

MentalMapQuestionnaireBlock? _findBlockByCode(
  List<MentalMapQuestionnaireBlock> questionnaires,
  String code,
) {
  for (final block in questionnaires) {
    if (block.questionnaireCode.trim().toUpperCase() == code) {
      return block;
    }
  }
  return null;
}

MentalMapQuestionnaireContext? _findQuestionnaireContext(
  List<MentalMapQuestionnaireContext> contexts,
  String code,
) {
  for (final context in contexts) {
    if (context.questionnaireCode.trim().toUpperCase() == code) {
      return context;
    }
  }
  return null;
}
