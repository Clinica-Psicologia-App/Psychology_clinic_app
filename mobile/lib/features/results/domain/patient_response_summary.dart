import 'questionnaire_response_status.dart';

/// Item da listagem de respostas de um paciente.
class PatientResponseSummary {
  const PatientResponseSummary({
    required this.id,
    required this.questionnaireId,
    required this.questionnaireCode,
    required this.questionnaireName,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.reviewedAt,
    this.reviewedByName,
    this.reviewNotes,
    required this.answerCount,
    required this.hasResults,
    required this.resultsCount,
  });

  final String id;
  final String questionnaireId;
  final String questionnaireCode;
  final String questionnaireName;
  final QuestionnaireResponseStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? reviewedAt;
  final String? reviewedByName;
  final String? reviewNotes;
  final int answerCount;
  final bool hasResults;
  final int resultsCount;

  bool get isReviewed => reviewedAt != null;

  factory PatientResponseSummary.fromJson(Map<String, dynamic> json) {
    final questionnaire = json['questionnaire'];
    Map<String, dynamic> qMap = {};
    if (questionnaire is Map) {
      qMap = Map<String, dynamic>.from(questionnaire);
    }
    final reviewedBy = json['reviewed_by'];
    String? reviewedByName;
    if (reviewedBy is Map) {
      reviewedByName = reviewedBy['full_name'] as String?;
    }

    return PatientResponseSummary(
      id: json['id'] as String,
      questionnaireId:
          qMap['id'] as String? ?? json['questionnaire_id'] as String,
      questionnaireCode: qMap['code'] as String? ?? '-',
      questionnaireName: qMap['name'] as String? ?? 'Questionário',
      status: QuestionnaireResponseStatus.fromString(
        json['status'] as String? ?? 'draft',
      ),
      startedAt: _parseDateTime(json['started_at']),
      completedAt: _parseDateTime(json['completed_at']),
      reviewedAt: _parseDateTime(json['reviewed_at']),
      reviewedByName: reviewedByName,
      reviewNotes: json['review_notes'] as String?,
      answerCount: _embeddedCount(json['questionnaire_answers']),
      hasResults: _embeddedCount(json['questionnaire_results']) > 0,
      resultsCount: _embeddedCount(json['questionnaire_results']),
    );
  }
}

int _embeddedCount(dynamic embedded) {
  if (embedded is List) {
    if (embedded.isEmpty) return 0;
    final first = embedded.first;
    if (first is Map && first.containsKey('count')) {
      return _asInt(first['count']) ?? 0;
    }
    return embedded.length;
  }
  if (embedded is Map && embedded.containsKey('count')) {
    return _asInt(embedded['count']) ?? 0;
  }
  return 0;
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
