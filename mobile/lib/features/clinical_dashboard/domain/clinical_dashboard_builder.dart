import '../../mental_map/domain/mental_map_aggregator.dart';
import '../../results/domain/patient_response_summary.dart';
import '../../results/domain/patient_result_detail.dart';
import '../../results/domain/questionnaire_response_status.dart';
import '../../results/domain/schema_activation.dart';
import '../../results/domain/scoring_schema_result.dart';
import 'clinical_dashboard_history_entry.dart';
import 'clinical_dashboard_score_row.dart';
import 'clinical_instrument_dashboard.dart';
import 'consolidated_schema_row.dart';

const ysqInstrumentMarker = 'YSQ';
const yamiInstrumentMarker = 'YAMI';
const attachmentInstrumentCode = 'ATTACHMENT_STYLES_V1';
const yciInstrumentCode = 'YCI_FOUNDATION_V1';
const yraiInstrumentCode = 'YRAI_FOUNDATION_V1';
const parentalInstrumentCode = 'PARENTAL_STYLES_V1';
const defaultTopScoreLimit = 8;

/// Última resposta concluída com resultados para o marcador textual.
PatientResponseSummary? latestStructuredResponse(
  List<PatientResponseSummary> responses,
  String marker,
) {
  final completed = responses
      .where(
        (r) =>
            r.status == QuestionnaireResponseStatus.completed &&
            r.hasResults &&
            r.questionnaireCode.toUpperCase().contains(marker),
      )
      .toList();

  PatientResponseSummary? latest;
  for (final r in completed) {
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

/// Última resposta concluída com resultados para um código exato.
PatientResponseSummary? latestStructuredResponseByCode(
  List<PatientResponseSummary> responses,
  String questionnaireCode,
) {
  final completed = responses
      .where(
        (r) =>
            r.status == QuestionnaireResponseStatus.completed &&
            r.hasResults &&
            r.questionnaireCode.trim().toUpperCase() ==
                questionnaireCode.trim().toUpperCase(),
      )
      .toList();

  PatientResponseSummary? latest;
  for (final r in completed) {
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

/// Esquemas/modos do snapshot, ordenados por score (maior primeiro).
List<ClinicalDashboardScoreRow> extractTopSchemaRows(
  PatientResultDetail detail, {
  int limit = defaultTopScoreLimit,
}) {
  final rows = <ClinicalDashboardScoreRow>[];
  final scoring = detail.scoringDemo;

  if (scoring != null) {
    for (final schema in scoring.schemas) {
      rows.add(_rowFromSchema(schema));
    }
  }

  if (rows.isEmpty) {
    final highlights = extractScoreHighlights(detail, limit: limit);
    for (final h in highlights) {
      if (h.score == null) continue;
      rows.add(
        ClinicalDashboardScoreRow(
          name: h.name,
          code: h.code,
          score: h.score!,
        ),
      );
    }
    return rows;
  }

  rows.sort((a, b) => b.score.compareTo(a.score));
  return rows.take(limit).toList();
}

ClinicalDashboardScoreRow _rowFromSchema(ScoringSchemaResult schema) {
  final score = schema.weightedScore ?? schema.averageScore ?? schema.rawScore;
  return ClinicalDashboardScoreRow(
    name: schema.name,
    code: schema.code,
    score: score ?? 0,
    averageScore: schema.averageScore,
    severityLabel:
        schema.severity?.hasLabel == true ? schema.severity!.label : null,
    severityColorKey: schema.severity?.colorKey,
  );
}

ClinicalInstrumentDashboard? buildInstrumentDashboard({
  required PatientResponseSummary summary,
  required PatientResultDetail detail,
  int topLimit = defaultTopScoreLimit,
}) {
  final topScores = extractTopSchemaRows(detail, limit: topLimit);
  if (topScores.isEmpty) return null;

  final allScores = extractTopSchemaRows(detail, limit: 9999);
  final domainRows = _extractDomainRows(detail);
  final scoring = detail.scoringDemo;
  return ClinicalInstrumentDashboard(
    responseId: summary.id,
    questionnaireCode: summary.questionnaireCode,
    questionnaireName: summary.questionnaireName,
    completedAt: summary.completedAt ?? detail.completedAt,
    topScores: topScores,
    allScores: allScores,
    domainRows: domainRows,
    scaleMax: scoring?.scaleMax?.toDouble(),
  );
}

List<ClinicalDashboardScoreRow> _extractDomainRows(PatientResultDetail detail) {
  final rows = <ClinicalDashboardScoreRow>[];
  final scoring = detail.scoringDemo;
  if (scoring == null) return rows;

  for (final domain in scoring.domains) {
    final score =
        domain.weightedScore ?? domain.averageScore ?? domain.rawScore;
    if (score == null) continue;
    rows.add(
      ClinicalDashboardScoreRow(
        name: domain.name,
        code: domain.code,
        score: score,
        severityLabel: domain.hasSeverity ? domain.severity!.label : null,
        severityColorKey: domain.severity?.colorKey,
      ),
    );
  }

  rows.sort((a, b) => b.score.compareTo(a.score));
  return rows;
}

List<ClinicalDashboardHistoryEntry> buildStructuredHistory(
  List<PatientResponseSummary> responses,
) {
  final entries = <ClinicalDashboardHistoryEntry>[];

  for (final r in responses) {
    final code = r.questionnaireCode.toUpperCase();
    if (!code.contains(ysqInstrumentMarker) &&
        !code.contains(yamiInstrumentMarker) &&
        code != attachmentInstrumentCode &&
        code != yciInstrumentCode &&
        code != yraiInstrumentCode &&
        code != parentalInstrumentCode) {
      continue;
    }
    if (r.status != QuestionnaireResponseStatus.completed) continue;

    entries.add(
      ClinicalDashboardHistoryEntry(
        responseId: r.id,
        questionnaireCode: r.questionnaireCode,
        questionnaireName: r.questionnaireName,
        completedAt: r.completedAt,
        hasResults: r.hasResults,
      ),
    );
  }

  entries.sort((a, b) {
    final da = a.completedAt;
    final db = b.completedAt;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });

  return entries;
}

bool patientHasStructuredDashboardResults(
    List<PatientResponseSummary> responses) {
  return latestStructuredResponse(responses, ysqInstrumentMarker) != null ||
      latestStructuredResponse(responses, yamiInstrumentMarker) != null ||
      latestStructuredResponseByCode(responses, yciInstrumentCode) != null ||
      latestStructuredResponseByCode(responses, yraiInstrumentCode) != null ||
      latestStructuredResponseByCode(responses, attachmentInstrumentCode) !=
          null;
}

/// Consolida schemas de todos os instrumentos numa lista única, com status
/// de ativação (auto ≥ 4.0 ou psi manual), ordenada por score descendente.
List<ConsolidatedSchemaRow> buildConsolidatedSchemas({
  required ClinicalInstrumentDashboard? ysq,
  required ClinicalInstrumentDashboard? yami,
  required ClinicalInstrumentDashboard? attachment,
  required ClinicalInstrumentDashboard? yci,
  required ClinicalInstrumentDashboard? yrai,
  required Map<String, List<SchemaActivation>> activationsByResponseId,
}) {
  final rows = <ConsolidatedSchemaRow>[];

  void addFrom(ClinicalInstrumentDashboard? dashboard) {
    if (dashboard == null || dashboard.isEmpty) return;
    final activations = activationsByResponseId[dashboard.responseId] ?? [];
    final psiMap = {for (final a in activations) a.schemaCode: a};

    for (final scoreRow in dashboard.allScores) {
      // A ativação automática usa a MÉDIA por item (mesma métrica da tela de
      // detalhe do questionário — SchemaAtivadosCard). O `score` de exibição
      // pode ser o weighted, que está em outra escala e não serve ao limiar.
      final activationScore = scoreRow.averageScore ?? 0;
      final isAuto = activationScore >= kSchemaActivationThreshold;
      final psi = psiMap[scoreRow.code];
      // Exibe a média quando disponível, para casar com o detalhe.
      final displayScore = scoreRow.averageScore ?? scoreRow.score;
      rows.add(ConsolidatedSchemaRow(
        name: scoreRow.name,
        code: scoreRow.code,
        score: displayScore,
        responseId: dashboard.responseId,
        isAutoActivated: isAuto,
        isPsiActivated: psi != null && !isAuto,
        psiObservation: psi?.psiObservation,
        instrumentName: dashboard.questionnaireName,
        instrumentCode: dashboard.questionnaireCode,
        severityLabel: scoreRow.severityLabel,
        severityColorKey: scoreRow.severityColorKey,
        scaleMax: dashboard.scaleMax,
      ));
    }
  }

  // Apenas YSQ (esquemas Young) e YAMI (modos) produzem dados de esquema
  // individuais. YRAI, YCI e Attachment geram apenas pontuações agregadas por
  // categoria e não pertencem ao perfil esquemático consolidado.
  addFrom(ysq);
  addFrom(yami);

  rows.sort((a, b) => b.score.compareTo(a.score));
  return rows;
}
