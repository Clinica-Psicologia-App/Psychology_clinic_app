import 'mental_map_clinical_core.dart';
import 'mental_map_problem_summary.dart';
import 'mental_map_questionnaire_block.dart';
import 'mental_map_score_highlight.dart';

const _ysqMarker = 'YSQ';
const _yamiMarker = 'YAMI';
const _attachmentCode = 'ATTACHMENT_STYLES_V1';
const _yciCode = 'YCI_FOUNDATION_V1';
const _yraiCode = 'YRAI_FOUNDATION_V1';
const _coreItemLimit = 5;
const _problemLimit = 3;

MentalMapClinicalCore buildMentalMapClinicalCore({
  required List<MentalMapQuestionnaireBlock> questionnaires,
  required List<MentalMapProblemSummary> activeProblems,
}) {
  final ysqBlock = _findBlockByMarker(questionnaires, _ysqMarker);
  final yamiBlock = _findBlockByMarker(questionnaires, _yamiMarker);
  final attachmentBlock = _findBlockByCode(questionnaires, _attachmentCode);
  final yciBlock = _findBlockByCode(questionnaires, _yciCode);
  final yraiBlock = _findBlockByCode(questionnaires, _yraiCode);

  final copingHighlights = _mergeHighlights(
    _schemaHighlights(yciBlock, _coreItemLimit),
    _schemaHighlights(yraiBlock, _coreItemLimit),
    limit: _coreItemLimit,
  );

  DateTime? copingCompletedAt;
  for (final block in [yciBlock, yraiBlock]) {
    final candidate = block?.completedAt;
    if (candidate == null) continue;
    if (copingCompletedAt == null || candidate.isAfter(copingCompletedAt)) {
      copingCompletedAt = candidate;
    }
  }

  return MentalMapClinicalCore(
    topSchemas: _schemaHighlights(ysqBlock, _coreItemLimit),
    topModes: _schemaHighlights(yamiBlock, _coreItemLimit),
    topProblemsByIntensity: _topProblemsByIntensity(activeProblems),
    attachmentStyles: _schemaHighlights(attachmentBlock, _coreItemLimit),
    copingStyles: copingHighlights,
    ysqCompletedAt: ysqBlock?.completedAt,
    yamiCompletedAt: yamiBlock?.completedAt,
    attachmentCompletedAt: attachmentBlock?.completedAt,
    copingCompletedAt: copingCompletedAt,
  );
}

List<MentalMapProblemSummary> _topProblemsByIntensity(
  List<MentalMapProblemSummary> activeProblems,
) {
  final sorted = [...activeProblems]
    ..sort((a, b) {
      final ai = a.intensity ?? -1;
      final bi = b.intensity ?? -1;
      return bi.compareTo(ai);
    });
  return sorted.take(_problemLimit).toList(growable: false);
}

List<MentalMapScoreHighlight> _schemaHighlights(
  MentalMapQuestionnaireBlock? block,
  int limit,
) {
  if (block == null) return const [];

  final schemaOnly = block.highlights
      .where((highlight) => highlight.kind == 'schema')
      .toList(growable: false);
  final source = schemaOnly.isNotEmpty ? schemaOnly : block.highlights;

  return source.take(limit).toList(growable: false);
}

List<MentalMapScoreHighlight> _mergeHighlights(
  List<MentalMapScoreHighlight> first,
  List<MentalMapScoreHighlight> second, {
  required int limit,
}) {
  final merged = <MentalMapScoreHighlight>[];
  for (final highlight in [...first, ...second]) {
    if (merged.any((item) => item.code == highlight.code)) continue;
    merged.add(highlight);
    if (merged.length >= limit) break;
  }
  return merged;
}

MentalMapQuestionnaireBlock? _findBlockByMarker(
  List<MentalMapQuestionnaireBlock> questionnaires,
  String marker,
) {
  for (final block in questionnaires) {
    if (block.questionnaireCode.toUpperCase().contains(marker)) {
      return block;
    }
  }
  return null;
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
