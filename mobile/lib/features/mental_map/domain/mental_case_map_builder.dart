import '../../genogram/domain/genogram_data.dart';
import 'mental_case_map.dart';
import 'mental_map_check_in_summary.dart';
import 'mental_map_goal_summary.dart';
import 'mental_map_problem_summary.dart';
import 'mental_map_questionnaire_block.dart';
import 'mental_map_score_highlight.dart';
import 'mental_map_timeline_summary.dart';

const _ysqCodeMarker = 'YSQ';
const _yamiCodeMarker = 'YAMI';
const _attachmentCode = 'ATTACHMENT_STYLES_V1';
const _parentalCode = 'PARENTAL_STYLES_V1';
const _yciCode = 'YCI_FOUNDATION_V1';
const _yraiCode = 'YRAI_FOUNDATION_V1';
const _nodeItemLimit = 3;

/// Metadados extras por questionário (ex.: figuras parentais).
class MentalMapQuestionnaireContext {
  const MentalMapQuestionnaireContext({
    required this.responseId,
    required this.questionnaireCode,
    this.completedAt,
    this.figureSummaries = const [],
  });

  final String responseId;
  final String questionnaireCode;
  final DateTime? completedAt;
  final List<String> figureSummaries;
}

MentalCaseMap buildMentalCaseMap({
  required String patientName,
  String patientInitials = 'P',
  MentalCaseMapAvatarType patientAvatarType = MentalCaseMapAvatarType.initials,
  String? patientPhotoUrl,
  Map<String, dynamic>? patientAvatarConfig,
  required List<MentalMapQuestionnaireBlock> questionnaires,
  required List<MentalMapProblemSummary> activeProblems,
  required List<MentalMapGoalSummary> activeGoals,
  required MentalMapCheckInSummary? recentCheckIn,
  required List<MentalMapTimelineSummary> timelineEvents,
  required GenogramData genogramData,
  List<MentalMapQuestionnaireContext> questionnaireContexts = const [],
}) {
  final parentalContext = _findQuestionnaireContext(
    questionnaireContexts,
    _parentalCode,
  );
  final ysqBlock = _findQuestionnaireBlock(questionnaires, _ysqCodeMarker);
  final yamiBlock = _findQuestionnaireBlock(questionnaires, _yamiCodeMarker);
  final attachmentBlock =
      _findQuestionnaireBlockByCode(questionnaires, _attachmentCode);

  return MentalCaseMap(
    center: MentalCaseMapCenter(
      patientName: patientName,
      initials: patientInitials,
      avatarType: patientAvatarType,
      photoUrl: patientPhotoUrl,
      avatarConfig: patientAvatarConfig,
      activeProblemsLabel: _buildProblemsLabel(activeProblems.length),
      activeGoalsLabel: _buildGoalsLabel(activeGoals.length),
      lastCheckInLabel: _buildCheckInLabel(recentCheckIn),
    ),
    primaryNodes: [
      _buildSchemaNode(questionnaires, ysqBlock),
      _buildModeNode(questionnaires, yamiBlock),
      _buildProblemsNode(activeProblems),
      _buildGoalsNode(activeGoals),
    ],
    contextNodes: [
      _buildAttachmentNode(questionnaires, attachmentBlock),
      _buildCopingNode(questionnaires),
      _buildParentalNode(questionnaires, parentalContext),
      _buildHistoryNode(timelineEvents, genogramData),
    ],
  );
}

MentalCaseMapNode _buildSchemaNode(
  List<MentalMapQuestionnaireBlock> questionnaires,
  MentalMapQuestionnaireBlock? block,
) {
  final items = _topHighlightItems(questionnaires, _ysqCodeMarker);
  return MentalCaseMapNode(
    id: 'schemas',
    title: 'Esquemas',
    shortLabel: _buildFilledStatusLabel(items.isNotEmpty),
    items: items,
    emptyLabel: 'Pendente',
    dataSource: 'YSQ - última resposta concluída',
    lastUpdatedAt: block?.completedAt,
    responseId: block?.responseId,
    aggregateSeverityColorKey:
        _worstSeverityByMarker(questionnaires, _ysqCodeMarker),
  );
}

MentalCaseMapNode _buildModeNode(
  List<MentalMapQuestionnaireBlock> questionnaires,
  MentalMapQuestionnaireBlock? block,
) {
  final items = _topHighlightItems(questionnaires, _yamiCodeMarker);
  return MentalCaseMapNode(
    id: 'modes',
    title: 'Modos',
    shortLabel: _buildFilledStatusLabel(items.isNotEmpty),
    items: items,
    emptyLabel: 'Pendente',
    dataSource: 'YAMI - última resposta concluída',
    lastUpdatedAt: block?.completedAt,
    responseId: block?.responseId,
    aggregateSeverityColorKey:
        _worstSeverityByMarker(questionnaires, _yamiCodeMarker),
  );
}

MentalCaseMapNode _buildProblemsNode(
    List<MentalMapProblemSummary> activeProblems) {
  final items = activeProblems
      .take(_nodeItemLimit)
      .map((problem) => problem.title.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  return MentalCaseMapNode(
    id: 'problems',
    title: 'Problemas',
    shortLabel: _buildCountLabel(
      activeProblems.length,
      singular: 'ativo',
      plural: 'ativos',
    ),
    items: items,
    emptyLabel: 'Pendente',
    dataSource: 'Problemas registrados pelo paciente/equipe',
    aggregateSeverityColorKey: _problemsSeverityKey(activeProblems),
  );
}

MentalCaseMapNode _buildGoalsNode(List<MentalMapGoalSummary> activeGoals) {
  final items = activeGoals
      .take(_nodeItemLimit)
      .map((goal) => goal.title.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  return MentalCaseMapNode(
    id: 'goals',
    title: 'Objetivos',
    shortLabel: _buildCountLabel(
      activeGoals.length,
      singular: 'ativo',
      plural: 'ativos',
    ),
    items: items,
    emptyLabel: 'Pendente',
    dataSource: 'Objetivos terapêuticos ativos',
  );
}

MentalCaseMapNode _buildAttachmentNode(
  List<MentalMapQuestionnaireBlock> questionnaires,
  MentalMapQuestionnaireBlock? block,
) {
  final items = _topHighlightItemsForCode(questionnaires, _attachmentCode);
  return MentalCaseMapNode(
    id: 'attachment',
    title: 'Apego',
    shortLabel: _buildFilledStatusLabel(items.isNotEmpty),
    items: items,
    emptyLabel: 'Pendente',
    dataSource: 'ATTACHMENT_STYLES_V1 - snapshot estruturado',
    lastUpdatedAt: block?.completedAt,
    responseId: block?.responseId,
    aggregateSeverityColorKey:
        _worstSeverityByCodes(questionnaires, [_attachmentCode]),
  );
}

MentalCaseMapNode _buildCopingNode(
    List<MentalMapQuestionnaireBlock> questionnaires) {
  final yci = _findQuestionnaireBlockByCode(questionnaires, _yciCode);
  final yrai = _findQuestionnaireBlockByCode(questionnaires, _yraiCode);
  final items =
      _topHighlightItemsForCodes(questionnaires, [_yciCode, _yraiCode]);
  DateTime? latest;
  for (final block in [yci, yrai]) {
    final candidate = block?.completedAt;
    if (candidate == null) continue;
    if (latest == null || candidate.isAfter(latest)) {
      latest = candidate;
    }
  }

  return MentalCaseMapNode(
    id: 'coping',
    title: 'Enfrentamento',
    shortLabel: _buildFilledStatusLabel(items.isNotEmpty),
    items: items,
    emptyLabel: 'Pendente',
    dataSource: 'YCI / YRAI - snapshots estruturados',
    lastUpdatedAt: latest,
    responseId: yci?.responseId ?? yrai?.responseId,
    aggregateSeverityColorKey:
        _worstSeverityByCodes(questionnaires, [_yciCode, _yraiCode]),
  );
}

MentalCaseMapNode _buildParentalNode(
  List<MentalMapQuestionnaireBlock> questionnaires,
  MentalMapQuestionnaireContext? context,
) {
  final block = _findQuestionnaireBlockByCode(questionnaires, _parentalCode);
  final figureItems = context?.figureSummaries ?? const [];
  final fallbackItems =
      _topHighlightItemsForCode(questionnaires, _parentalCode);
  final items = figureItems.isNotEmpty ? figureItems : fallbackItems;

  return MentalCaseMapNode(
    id: 'parental',
    title: 'Parentais',
    shortLabel: _buildFilledStatusLabel(items.isNotEmpty),
    items: items.take(_nodeItemLimit).toList(growable: false),
    emptyLabel: 'Pendente',
    dataSource: 'PARENTAL_STYLES_V1 - figuras parentais',
    lastUpdatedAt: context?.completedAt ?? block?.completedAt,
    responseId: context?.responseId ?? block?.responseId,
    aggregateSeverityColorKey:
        _worstSeverityByCodes(questionnaires, [_parentalCode]),
  );
}

MentalCaseMapNode _buildHistoryNode(
  List<MentalMapTimelineSummary> timelineEvents,
  GenogramData genogramData,
) {
  final items = <String>[];
  for (final event in timelineEvents.take(2)) {
    final title = event.title.trim();
    if (title.isNotEmpty) items.add(title);
  }
  if (genogramData.people.isNotEmpty) {
    items.add('${genogramData.people.length} pessoa(s) no genograma');
  }
  if (genogramData.relationships.isNotEmpty && items.length < _nodeItemLimit) {
    items.add('${genogramData.relationships.length} relação(ões)');
  }

  return MentalCaseMapNode(
    id: 'history',
    title: 'História / Vínculos',
    shortLabel: _buildFilledStatusLabel(items.isNotEmpty),
    items: items.take(_nodeItemLimit).toList(growable: false),
    emptyLabel: 'Pendente',
    dataSource: 'Linha do tempo + genograma',
  );
}

MentalMapQuestionnaireBlock? _findQuestionnaireBlock(
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

MentalMapQuestionnaireBlock? _findQuestionnaireBlockByCode(
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

String _buildFilledStatusLabel(bool filled) {
  return filled ? 'Preenchido' : 'Pendente';
}

List<String> _topHighlightItems(
  List<MentalMapQuestionnaireBlock> questionnaires,
  String marker,
) {
  final selected = _findQuestionnaireBlock(questionnaires, marker);
  if (selected == null) return const [];

  final schemaOnly = selected.highlights
      .where((highlight) => highlight.kind == 'schema')
      .toList(growable: false);
  final source = schemaOnly.isNotEmpty ? schemaOnly : selected.highlights;

  return source
      .take(_nodeItemLimit)
      .map(_highlightLabel)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _topHighlightItemsForCode(
  List<MentalMapQuestionnaireBlock> questionnaires,
  String questionnaireCode,
) {
  final selected =
      _findQuestionnaireBlockByCode(questionnaires, questionnaireCode);
  if (selected == null) return const [];

  final schemaOnly = selected.highlights
      .where((highlight) => highlight.kind == 'schema')
      .toList(growable: false);
  final source = schemaOnly.isNotEmpty ? schemaOnly : selected.highlights;

  return source
      .take(_nodeItemLimit)
      .map(_highlightLabel)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _topHighlightItemsForCodes(
  List<MentalMapQuestionnaireBlock> questionnaires,
  List<String> questionnaireCodes,
) {
  final items = <String>[];
  for (final questionnaireCode in questionnaireCodes) {
    for (final item
        in _topHighlightItemsForCode(questionnaires, questionnaireCode)) {
      if (item.trim().isEmpty || items.contains(item)) continue;
      items.add(item);
      if (items.length >= _nodeItemLimit) {
        return items;
      }
    }
  }
  return items;
}

String _highlightLabel(MentalMapScoreHighlight highlight) {
  final name = highlight.name.trim();
  if (name.isEmpty) return '';
  if (highlight.score == null) return name;
  return '$name ${highlight.displayScore}';
}

String _buildProblemsLabel(int count) {
  if (count == 0) return 'Sem problemas ativos';
  if (count == 1) return '1 problema ativo';
  return '$count problemas ativos';
}

String _buildGoalsLabel(int count) {
  if (count == 0) return 'Sem objetivos ativos';
  if (count == 1) return '1 objetivo ativo';
  return '$count objetivos ativos';
}

String _buildCheckInLabel(MentalMapCheckInSummary? recentCheckIn) {
  if (recentCheckIn == null) return 'Sem check-in';
  final parts = <String>[];
  if (recentCheckIn.moodScore != null) {
    parts.add('Humor ${recentCheckIn.moodScore}');
  }
  if (recentCheckIn.anxietyScore != null) {
    parts.add('Ans. ${recentCheckIn.anxietyScore}');
  }
  if (parts.isEmpty) return 'Check-in registrado';
  return parts.join(' · ');
}

String _buildCountLabel(
  int count, {
  required String singular,
  required String plural,
}) {
  if (count == 0) return 'Pendente';
  if (count == 1) return '1 $singular';
  return '$count $plural';
}

// ---------------------------------------------------------------------------
// Severity helpers
// ---------------------------------------------------------------------------

/// Ordena severidades: red=4 > orange=3 > amber/yellow=2 > green=1 > null=0.
int _severityOrder(String? key) => switch (key?.toLowerCase()) {
      'red' => 4,
      'orange' => 3,
      'amber' => 2,
      'yellow' => 2,
      'green' => 1,
      _ => 0,
    };

/// Pior severidade entre os highlights de um bloco.
String? _worstSeverityFromBlock(MentalMapQuestionnaireBlock? block) {
  if (block == null) return null;
  String? worst;
  for (final h in block.highlights) {
    if (_severityOrder(h.severityColorKey) > _severityOrder(worst)) {
      worst = h.severityColorKey;
    }
  }
  return worst;
}

/// Pior severidade entre múltiplos blocos (por marker de código).
String? _worstSeverityByMarker(
  List<MentalMapQuestionnaireBlock> questionnaires,
  String marker,
) {
  final block = _findQuestionnaireBlock(questionnaires, marker);
  return _worstSeverityFromBlock(block);
}

/// Pior severidade entre múltiplos blocos (por código exato).
String? _worstSeverityByCodes(
  List<MentalMapQuestionnaireBlock> questionnaires,
  List<String> codes,
) {
  String? worst;
  for (final code in codes) {
    final block = _findQuestionnaireBlockByCode(questionnaires, code);
    final key = _worstSeverityFromBlock(block);
    if (_severityOrder(key) > _severityOrder(worst)) worst = key;
  }
  return worst;
}

/// Severidade derivada da intensidade máxima dos problemas ativos.
String? _problemsSeverityKey(List<MentalMapProblemSummary> problems) {
  var maxIntensity = 0;
  for (final p in problems) {
    final i = p.intensity ?? 0;
    if (i > maxIntensity) maxIntensity = i;
  }
  if (maxIntensity == 0) return null;
  if (maxIntensity <= 3) return 'green';
  if (maxIntensity <= 6) return 'amber';
  return 'red';
}
