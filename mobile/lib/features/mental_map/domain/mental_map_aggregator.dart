import '../../patients/domain/patient.dart';
import '../../results/domain/category_result.dart';
import '../../results/domain/patient_response_summary.dart';
import '../../results/domain/patient_result_detail.dart';
import '../../results/domain/questionnaire_response_status.dart';
import '../../results/domain/scoring_domain_result.dart';
import '../../results/domain/scoring_schema_result.dart';
import 'mental_map_case_summary.dart';
import 'mental_map_data.dart';
import 'mental_map_goal_summary.dart';
import 'mental_map_problem_summary.dart';
import 'mental_map_questionnaire_block.dart';
import 'mental_map_score_highlight.dart';
import 'mental_map_validation_summary.dart';

const _ysqMarker = 'YSQ';
const _yamiMarker = 'YAMI';
const _attachmentCode = 'ATTACHMENT_STYLES_V1';
const _parentalCode = 'PARENTAL_STYLES_V1';
const _yciCode = 'YCI_FOUNDATION_V1';
const _yraiCode = 'YRAI_FOUNDATION_V1';
const _defaultHighlightLimit = 5;

/// Monta blocos clínicos a partir das respostas concluídas mais recentes.
List<MentalMapQuestionnaireBlock> buildQuestionnaireBlocks({
  required List<PatientResponseSummary> responses,
}) {
  final completed = responses
      .where(
        (r) =>
            r.status == QuestionnaireResponseStatus.completed && r.hasResults,
      )
      .toList();

  final ysq = _latestForMarker(completed, _ysqMarker);
  final yami = _latestForMarker(completed, _yamiMarker);
  final attachment = _latestForCode(completed, _attachmentCode);
  final parental = _latestForCode(completed, _parentalCode);
  final yci = _latestForCode(completed, _yciCode);
  final yrai = _latestForCode(completed, _yraiCode);

  return [
    if (ysq != null) _toBlock(ysq),
    if (yami != null) _toBlock(yami),
    if (attachment != null) _toBlock(attachment),
    if (parental != null) _toBlock(parental),
    if (yci != null) _toBlock(yci),
    if (yrai != null) _toBlock(yrai),
  ];
}

MentalMapQuestionnaireBlock _toBlock(PatientResponseSummary summary) {
  return MentalMapQuestionnaireBlock(
    responseId: summary.id,
    questionnaireCode: summary.questionnaireCode,
    questionnaireName: summary.questionnaireName,
    completedAt: summary.completedAt,
    highlights: const [],
  );
}

PatientResponseSummary? _latestForMarker(
  List<PatientResponseSummary> responses,
  String marker,
) {
  PatientResponseSummary? latest;
  for (final r in responses) {
    if (!r.questionnaireCode.toUpperCase().contains(marker)) continue;
    if (latest == null) {
      latest = r;
      continue;
    }
    final a = r.completedAt ?? r.startedAt;
    final b = latest.completedAt ?? latest.startedAt;
    if (a != null && (b == null || a.isAfter(b))) {
      latest = r;
    }
  }
  return latest;
}

PatientResponseSummary? _latestForCode(
  List<PatientResponseSummary> responses,
  String code,
) {
  PatientResponseSummary? latest;
  for (final r in responses) {
    if (r.questionnaireCode.trim().toUpperCase() != code) continue;
    if (latest == null) {
      latest = r;
      continue;
    }
    final a = r.completedAt ?? r.startedAt;
    final b = latest.completedAt ?? latest.startedAt;
    if (a != null && (b == null || a.isAfter(b))) {
      latest = r;
    }
  }
  return latest;
}

/// Preenche highlights após carregar detalhe da resposta.
MentalMapQuestionnaireBlock blockWithHighlights(
  MentalMapQuestionnaireBlock block,
  PatientResultDetail detail, {
  int limit = _defaultHighlightLimit,
}) {
  return MentalMapQuestionnaireBlock(
    responseId: block.responseId,
    questionnaireCode: block.questionnaireCode,
    questionnaireName: block.questionnaireName,
    completedAt: block.completedAt ?? detail.completedAt,
    requiresTherapistReview: detail.requiresTherapistReview,
    highlights: extractScoreHighlights(detail, limit: limit),
  );
}

/// Resumos por figura parental a partir de `snapshot.contexts[]`.
List<String> extractParentalFigureSummaries(
  PatientResultDetail detail, {
  int limit = 3,
}) {
  final contexts = detail.snapshotContexts;
  if (contexts.isEmpty) return const [];

  final items = <String>[];
  for (final context in contexts) {
    final label = context.label.trim();
    if (label.isEmpty) continue;

    final schemas = [...context.schemas]..sort((a, b) {
        final sa = a.weightedScore ?? a.averageScore ?? a.rawScore ?? -1;
        final sb = b.weightedScore ?? b.averageScore ?? b.rawScore ?? -1;
        return sb.compareTo(sa);
      });

    if (schemas.isNotEmpty) {
      items.add('$label - ${schemas.first.name.trim()}');
    } else {
      items.add(label);
    }

    if (items.length >= limit) break;
  }

  return items;
}

/// Principais esquemas/modos por score ponderado ou médio (ordem decrescente).
List<MentalMapScoreHighlight> extractScoreHighlights(
  PatientResultDetail detail, {
  int limit = _defaultHighlightLimit,
}) {
  final highlights = <MentalMapScoreHighlight>[];

  final scoring = detail.scoringDemo;
  if (scoring != null) {
    for (final schema in scoring.schemas) {
      highlights.add(_fromSchema(schema));
    }
    for (final domain in scoring.domains) {
      highlights.add(_fromDomain(domain));
    }
  }

  if (highlights.isEmpty) {
    for (final category in detail.categoryResults) {
      highlights.add(_fromCategory(category));
    }
  }

  highlights.sort(_compareHighlights);
  return highlights.take(limit).toList();
}

MentalMapScoreHighlight _fromSchema(ScoringSchemaResult schema) {
  final score = schema.weightedScore ?? schema.averageScore ?? schema.rawScore;
  return MentalMapScoreHighlight(
    name: schema.name,
    code: schema.code,
    kind: 'schema',
    score: score,
    scoreLabel: score != null ? null : '-',
  );
}

MentalMapScoreHighlight _fromDomain(ScoringDomainResult domain) {
  final score = domain.weightedScore ?? domain.averageScore ?? domain.rawScore;
  return MentalMapScoreHighlight(
    name: domain.name,
    code: domain.code,
    kind: 'domain',
    score: score,
  );
}

MentalMapScoreHighlight _fromCategory(CategoryResult category) {
  final score = category.averageScore ?? category.totalScore;
  return MentalMapScoreHighlight(
    name: category.categoryName ?? category.categoryCode ?? 'Categoria',
    code: category.categoryCode ?? '-',
    kind: 'category',
    score: score,
  );
}

int _compareHighlights(MentalMapScoreHighlight a, MentalMapScoreHighlight b) {
  final sa = a.score ?? -1;
  final sb = b.score ?? -1;
  return sb.compareTo(sa);
}

/// Indica se há ao menos um dado clínico para exibir no mapa / trilha.
bool mentalMapHasRelevantData(MentalMapData data) {
  if (data.caseSummary.hasContent) return true;
  if (data.questionnaires.isNotEmpty) return true;
  if (data.activeProblems.isNotEmpty) return true;
  if (data.activeGoals.isNotEmpty) return true;
  if (data.recentCheckIn != null) return true;
  if (data.recentMonitors.isNotEmpty) return true;
  if (data.recentTimelineEvents.isNotEmpty) return true;
  if (data.genogram.hasContent) return true;
  return false;
}

MentalMapCaseSummary buildCaseSummary({
  required Patient patient,
  required List<MentalMapQuestionnaireBlock> questionnaires,
  required List<MentalMapProblemSummary> activeProblems,
  required List<MentalMapGoalSummary> activeGoals,
}) {
  final hypotheses = <String>[];
  final seenHypotheses = <String>{};
  for (final block in questionnaires) {
    for (final highlight in block.highlights) {
      final label = highlight.name.trim();
      if (label.isEmpty || !seenHypotheses.add(label)) continue;
      hypotheses.add(label);
      if (hypotheses.length >= 4) break;
    }
    if (hypotheses.length >= 4) break;
  }

  final focuses = <String>[];
  final seenFocuses = <String>{};
  final demand = _nullableText(patient.therapyDemands);
  if (demand != null) {
    for (final chunk in _splitFocusLines(demand)) {
      if (seenFocuses.add(chunk)) {
        focuses.add(chunk);
      }
      if (focuses.length >= 4) break;
    }
  }

  for (final goal in activeGoals) {
    final label = goal.title.trim();
    if (label.isEmpty || !seenFocuses.add(label)) continue;
    focuses.add(label);
    if (focuses.length >= 4) break;
  }

  for (final problem in activeProblems) {
    final label = problem.title.trim();
    if (label.isEmpty || !seenFocuses.add(label)) continue;
    focuses.add(label);
    if (focuses.length >= 4) break;
  }

  return MentalMapCaseSummary(
    intakeSummary: _nullableText(patient.intakeSummary),
    currentLifeContext: _nullableText(patient.currentLifeContext),
    therapyDemands: demand,
    centralHypotheses: hypotheses,
    currentFocuses: focuses,
  );
}

MentalMapValidationSummary buildValidationSummary({
  required Patient patient,
  required List<MentalMapQuestionnaireBlock> questionnaires,
  required List<MentalMapProblemSummary> activeProblems,
  required List<MentalMapGoalSummary> activeGoals,
  required MentalMapCaseSummary caseSummary,
}) {
  final pendingReviews =
      questionnaires.where((item) => item.requiresTherapistReview).length;
  final hasTherapistInputs = _nullableText(patient.intakeSummary) != null ||
      _nullableText(patient.currentLifeContext) != null ||
      _nullableText(patient.therapyDemands) != null ||
      activeProblems.isNotEmpty ||
      activeGoals.isNotEmpty;

  return MentalMapValidationSummary(
    pendingQuestionnaireReviewCount: pendingReviews,
    hasTherapistInputs: hasTherapistInputs,
    hasClinicalSynthesis: caseSummary.hasContent,
  );
}

String? _nullableText(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

Iterable<String> _splitFocusLines(String raw) sync* {
  final normalized = raw.replaceAll('\r', '\n');
  for (final piece in normalized.split('\n')) {
    final trimmed = piece.replaceFirst(RegExp(r'^[\-\u2022\s]+'), '').trim();
    if (trimmed.isNotEmpty) {
      yield trimmed;
    }
  }
}

/// Versão leve para trilha (contagens já agregadas no progresso).
bool journeyHasMentalMapRelevantData({
  required int completedQuestionnaireCount,
  required int openProblemCount,
  required int activeTherapyGoalCount,
  required int checkInCount,
  required int dailyMonitorCount,
  required int timelineEventCount,
  required int genogramPeopleCount,
  required int genogramRelationshipCount,
}) {
  return completedQuestionnaireCount > 0 ||
      openProblemCount > 0 ||
      activeTherapyGoalCount > 0 ||
      checkInCount > 0 ||
      dailyMonitorCount > 0 ||
      timelineEventCount > 0 ||
      genogramPeopleCount > 0 ||
      genogramRelationshipCount > 0;
}
