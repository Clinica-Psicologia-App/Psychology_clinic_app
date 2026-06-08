import '../../mental_map/domain/mental_map_aggregator.dart';
import '../../results/domain/patient_response_summary.dart';
import '../../results/domain/patient_result_detail.dart';
import '../../results/domain/questionnaire_response_status.dart';
import '../../results/domain/scoring_schema_result.dart';
import 'clinical_parental_dashboard_builder.dart';
import 'clinical_dashboard_history_entry.dart';
import 'clinical_dashboard_score_row.dart';
import 'clinical_instrument_dashboard.dart';

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

  final scoring = detail.scoringDemo;
  return ClinicalInstrumentDashboard(
    responseId: summary.id,
    questionnaireCode: summary.questionnaireCode,
    questionnaireName: summary.questionnaireName,
    completedAt: summary.completedAt ?? detail.completedAt,
    topScores: topScores,
    scaleMax: scoring?.scaleMax?.toDouble(),
  );
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
