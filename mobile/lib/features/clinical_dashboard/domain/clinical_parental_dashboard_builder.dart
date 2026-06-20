import '../../results/domain/patient_response_summary.dart';
import '../../results/domain/patient_result_detail.dart';
import '../../results/domain/scoring_schema_result.dart';
import '../../results/domain/snapshot_context_result.dart';
import 'clinical_dashboard_score_row.dart';
import 'clinical_parental_dashboard.dart';

ClinicalParentalDashboard? buildParentalDashboard({
  required PatientResponseSummary summary,
  required PatientResultDetail detail,
  int topLimit = 5,
}) {
  final contexts = detail.snapshotContexts;
  if (contexts.isEmpty) return null;

  final figures = contexts
      .map((context) => _buildFigurePanel(context, topLimit: topLimit))
      .toList()
    ..sort(
      (a, b) => _parentalFigureOrder(a.label).compareTo(
        _parentalFigureOrder(b.label),
      ),
    );

  if (figures.every((figure) => !figure.hasScores)) {
    return ClinicalParentalDashboard(
      responseId: summary.id,
      questionnaireCode: summary.questionnaireCode,
      questionnaireName: summary.questionnaireName,
      completedAt: summary.completedAt ?? detail.completedAt,
      figures: figures,
    );
  }

  return ClinicalParentalDashboard(
    responseId: summary.id,
    questionnaireCode: summary.questionnaireCode,
    questionnaireName: summary.questionnaireName,
    completedAt: summary.completedAt ?? detail.completedAt,
    figures: figures,
  );
}

ClinicalParentalFigurePanel _buildFigurePanel(
  SnapshotContextResult context, {
  required int topLimit,
}) {
  return ClinicalParentalFigurePanel(
    id: context.id,
    key: context.key,
    label: context.label,
    answerCount: context.answerCount,
    totalQuestions: context.totalQuestions,
    completionRatio: context.completionRatio,
    topScores: extractTopSchemaRowsFromSchemas(
      context.schemas,
      limit: topLimit,
    ),
    summaryLine: _buildFigureSummaryLine(context),
  );
}

String? _buildFigureSummaryLine(SnapshotContextResult context) {
  final average = context.summary.averageScore;
  if (average != null) {
    return 'Média geral ${average.toStringAsFixed(2)}';
  }
  final answered = context.summary.answeredItems;
  if (answered != null && answered > 0) {
    return '$answered itens apurados';
  }
  return null;
}

List<ClinicalDashboardScoreRow> extractTopSchemaRowsFromSchemas(
  List<ScoringSchemaResult> schemas, {
  int limit = 8,
}) {
  final rows = schemas.map(_rowFromSchema).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
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

int _parentalFigureOrder(String label) {
  switch (label) {
    case 'Mãe':
      return 0;
    case 'Pai':
      return 1;
    default:
      return 2;
  }
}
