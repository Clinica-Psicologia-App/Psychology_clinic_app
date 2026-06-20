import '../../mental_map/domain/mental_map_data.dart';
import 'patient_resource_access.dart';
import 'therapy_resource.dart';
import 'therapy_resource_recommendation.dart';

const _attachmentCode = 'ATTACHMENT_STYLES_V1';
const _parentalCode = 'PARENTAL_STYLES_V1';
const _yciCode = 'YCI_FOUNDATION_V1';
const _yraiCode = 'YRAI_FOUNDATION_V1';

List<TherapyResourceRecommendation> buildTherapyResourceRecommendations({
  required MentalMapData mentalMap,
  required List<TherapyResource> library,
  required List<PatientResourceAccess> assigned,
}) {
  final activeAccessByResource = {
    for (final access in assigned)
      if (access.isActive) access.resourceId: access,
  };

  final results = <TherapyResourceRecommendation>[];
  for (final resource in library) {
    final reasons = _matchReasons(resource: resource, mentalMap: mentalMap);
    if (reasons.isEmpty) continue;

    results.add(
      TherapyResourceRecommendation(
        resource: resource,
        reasons: reasons,
        score: reasons.length,
        activeAccess: activeAccessByResource[resource.id],
      ),
    );
  }

  results.sort((a, b) {
    final scoreCompare = b.score.compareTo(a.score);
    if (scoreCompare != 0) return scoreCompare;

    final assignedCompare = a.isAlreadyAssigned == b.isAlreadyAssigned
        ? 0
        : (a.isAlreadyAssigned ? 1 : -1);
    if (assignedCompare != 0) return assignedCompare;

    return a.resource.title.compareTo(b.resource.title);
  });

  return results.take(3).toList();
}

List<String> _matchReasons({
  required TherapyResource resource,
  required MentalMapData mentalMap,
}) {
  final text = _normalize(
    [
      resource.title,
      resource.description,
    ].whereType<String>().join(' '),
  );

  final signals = _normalize(
    [
      mentalMap.caseSummary.intakeSummary,
      mentalMap.caseSummary.currentLifeContext,
      mentalMap.caseSummary.therapyDemands,
      ...mentalMap.caseSummary.centralHypotheses,
      ...mentalMap.caseSummary.currentFocuses,
      ...mentalMap.activeProblems.map((p) => p.title),
      ...mentalMap.activeGoals.map((g) => g.title),
      ...mentalMap.recentMonitors.map((m) => m.summaryLine),
    ].whereType<String>().join(' '),
  );

  final reasons = <String>[];
  final questionnaireCodes = mentalMap.questionnaires
      .map((block) => block.questionnaireCode.trim().toUpperCase())
      .toSet();
  final attachmentHighlights = _highlightsFor(mentalMap, _attachmentCode);
  final parentalHighlights = _highlightsFor(mentalMap, _parentalCode);
  final yciHighlights = _highlightsFor(mentalMap, _yciCode);
  final yraiHighlights = _highlightsFor(mentalMap, _yraiCode);

  if (text.contains('esquema') &&
      (mentalMap.caseSummary.centralHypotheses.isNotEmpty ||
          mentalMap.questionnaires.isNotEmpty)) {
    reasons
        .add('Ajuda a psicoeducar os esquemas e organizar a leitura clínica.');
  }

  if ((text.contains('registro emocional') || text.contains('emocional')) &&
      _containsAny(
        signals,
        const ['ansied', 'emoc', 'humor', 'gatilh', 'sobrecarg', 'crise'],
      )) {
    reasons
        .add('Apoia o rastreio de emoções, gatilhos e padrões do dia a dia.');
  }

  if ((text.contains('grounding') || text.contains('ancoragem')) &&
      (_containsAny(
            signals,
            const ['ansied', 'crise', 'sobrecarg', 'ativac', 'gatilh'],
          ) ||
          _hasElevatedDistress(mentalMap))) {
    reasons
        .add('Pode ajudar na regulação imediata quando há ativação emocional.');
  }

  if (reasons.isEmpty &&
      text.contains('esquema') &&
      mentalMap.caseSummary.hasContent) {
    reasons
        .add('Material introdutório útil para alinhar linguagem terapêutica.');
  }

  if ((text.contains('emocional') || text.contains('grounding')) &&
      questionnaireCodes.contains(_attachmentCode) &&
      _containsAny(
        attachmentHighlights,
        const ['ansioso', 'evitante'],
      )) {
    reasons
        .add('Pode apoiar a regulação quando o apego aparece mais inseguro.');
  }

  if ((text.contains('esquema') || text.contains('emocional')) &&
      questionnaireCodes.contains(_parentalCode) &&
      _containsAny(
        parentalHighlights,
        const ['abandono', 'privacao', 'postura punitiva', 'desconfianca'],
      )) {
    reasons.add(
      'Conversa com padrões parentais percebidos e ajuda na formulação do caso.',
    );
  }

  if ((text.contains('registro emocional') || text.contains('emocional')) &&
      questionnaireCodes.contains(_yciCode) &&
      _containsAny(
        yciHighlights,
        const ['evit', 'submiss', 'hipercompens'],
      )) {
    reasons.add(
        'Ajuda a observar estilos de enfrentamento e respostas automáticas.');
  }

  if ((text.contains('grounding') || text.contains('esquema')) &&
      questionnaireCodes.contains(_yraiCode) &&
      _containsAny(
        yraiHighlights,
        const ['evit', 'vulner', 'crit', 'control'],
      )) {
    reasons.add(
      'Pode ser útil para monitorar reações interpessoais ativadas no vínculo.',
    );
  }

  return reasons;
}

bool _hasElevatedDistress(MentalMapData mentalMap) {
  final checkIn = mentalMap.recentCheckIn;
  if (checkIn == null) return false;

  return (checkIn.anxietyScore ?? 0) >= 6 ||
      (checkIn.problemIntensityScore ?? 0) >= 6 ||
      (checkIn.moodScore != null && checkIn.moodScore! <= 4);
}

bool _containsAny(String haystack, List<String> needles) {
  for (final needle in needles) {
    if (haystack.contains(needle)) return true;
  }
  return false;
}

String _highlightsFor(MentalMapData mentalMap, String questionnaireCode) {
  for (final block in mentalMap.questionnaires) {
    if (block.questionnaireCode.trim().toUpperCase() != questionnaireCode) {
      continue;
    }
    return _normalize(
      block.highlights.map((item) => '${item.name} ${item.code}').join(' '),
    );
  }
  return '';
}

String _normalize(String raw) {
  return raw
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('â', 'a')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');
}
