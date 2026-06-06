import 'answered_question.dart';
import 'category_result.dart';
import 'patient_response_summary.dart';
import 'questionnaire_response_status.dart';
import 'snapshot_context_result.dart';
import 'scoring_snapshot.dart';

/// Detalhe completo de uma resposta (staff).
class PatientResultDetail {
  const PatientResultDetail({
    required this.id,
    required this.patientId,
    required this.questionnaireId,
    required this.questionnaireCode,
    required this.questionnaireName,
    this.questionnaireDescription,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.reviewedAt,
    this.reviewedByName,
    this.reviewNotes,
    required this.answers,
    required this.categoryResults,
  });

  final String id;
  final String patientId;
  final String questionnaireId;
  final String questionnaireCode;
  final String questionnaireName;
  final String? questionnaireDescription;
  final QuestionnaireResponseStatus status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? reviewedAt;
  final String? reviewedByName;
  final String? reviewNotes;
  final List<AnsweredQuestion> answers;
  final List<CategoryResult> categoryResults;

  bool get hasResults => categoryResults.isNotEmpty;
  bool get isReviewed => reviewedAt != null;

  bool get isParentalStyles =>
      questionnaireCode.trim().toUpperCase() == 'PARENTAL_STYLES_V1';

  bool get requiresTherapistReview {
    if (isReviewed) return false;
    for (final result in categoryResults) {
      if ((result.classification ?? '').trim().toLowerCase() ==
          'pending_review') {
        return true;
      }
    }
    return false;
  }

  int get answeredCount => answers.where((a) => a.hasAnswer).length;

  List<CategoryResult> get sortedCategoryResults {
    final items = [...categoryResults];
    items.sort((a, b) {
      final figureCompare = _parentalFigureOrder(a.parentalFigureLabel)
          .compareTo(_parentalFigureOrder(b.parentalFigureLabel));
      if (figureCompare != 0) return figureCompare;

      final labelCompare = a.shortCategoryLabel.compareTo(b.shortCategoryLabel);
      if (labelCompare != 0) return labelCompare;

      return (a.categoryCode ?? '').compareTo(b.categoryCode ?? '');
    });
    return items;
  }

  /// Primeiro snapshot com motor DEMO (`scoring-demo-1`) entre as categorias.
  ScoringSnapshot? get scoringDemo {
    for (final result in categoryResults) {
      final scoring = result.snapshot.scoring;
      if (result.snapshot.isScoringDemo && scoring != null) {
        return scoring;
      }
    }
    return null;
  }

  bool get hasScoringDemo => scoringDemo != null;

  List<SnapshotContextResult> get snapshotContexts {
    for (final result in categoryResults) {
      if (result.snapshot.contexts.isNotEmpty) {
        return result.snapshot.contexts;
      }
    }
    return const [];
  }

  String? get snapshotVersion {
    for (final result in categoryResults) {
      final v = result.snapshot.version;
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  factory PatientResultDetail.fromJson(Map<String, dynamic> json) {
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

    final answersRaw = json['questionnaire_answers'] as List? ?? [];
    final answers = answersRaw
        .map(
          (a) => AnsweredQuestion.fromJson(Map<String, dynamic>.from(a as Map)),
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    final resultsRaw = json['questionnaire_results'] as List? ?? [];
    final results = resultsRaw
        .map(
          (r) => CategoryResult.fromJson(Map<String, dynamic>.from(r as Map)),
        )
        .toList();

    return PatientResultDetail(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      questionnaireId:
          qMap['id'] as String? ?? json['questionnaire_id'] as String,
      questionnaireCode: qMap['code'] as String? ?? '—',
      questionnaireName: qMap['name'] as String? ?? 'Questionário',
      questionnaireDescription: qMap['description'] as String?,
      status: QuestionnaireResponseStatus.fromString(
        json['status'] as String? ?? 'draft',
      ),
      startedAt: _parseDateTime(json['started_at']),
      completedAt: _parseDateTime(json['completed_at']),
      reviewedAt: _parseDateTime(json['reviewed_at']),
      reviewedByName: reviewedByName,
      reviewNotes: json['review_notes'] as String?,
      answers: answers,
      categoryResults: results,
    );
  }

  PatientResponseSummary toSummary() {
    return PatientResponseSummary(
      id: id,
      questionnaireId: questionnaireId,
      questionnaireCode: questionnaireCode,
      questionnaireName: questionnaireName,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      reviewedAt: reviewedAt,
      reviewedByName: reviewedByName,
      reviewNotes: reviewNotes,
      answerCount: answeredCount,
      hasResults: hasResults,
      resultsCount: categoryResults.length,
    );
  }
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

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
