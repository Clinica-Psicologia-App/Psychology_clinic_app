import 'questionnaire_patient_status.dart';

class QuestionnaireAssignment {
  const QuestionnaireAssignment({
    required this.id,
    required this.patientId,
    required this.questionnaireId,
    required this.questionnaireName,
    required this.questionnaireCode,
    required this.assignedByName,
    required this.assignedAt,
    this.message,
    this.responseId,
    this.responseStatus,
  });

  final String id;
  final String patientId;
  final String questionnaireId;
  final String questionnaireName;
  final String questionnaireCode;
  final String assignedByName;
  final DateTime assignedAt;
  final String? message;
  final String? responseId;

  /// null → pendente, draft → em andamento, completed → concluído
  final QuestionnairePatientStatus? responseStatus;

  bool get isPending => responseId == null;
  bool get isInProgress => responseStatus == QuestionnairePatientStatus.draft;
  bool get isCompleted =>
      responseStatus == QuestionnairePatientStatus.completed;

  factory QuestionnaireAssignment.fromJson(Map<String, dynamic> json) {
    final questionnaire = json['questionnaire'] as Map<String, dynamic>? ?? {};
    final assignedBy = json['assigned_by'] as Map<String, dynamic>? ?? {};
    final response = json['response'] as Map<String, dynamic>?;

    QuestionnairePatientStatus? responseStatus;
    if (response != null) {
      final statusStr = response['status'] as String?;
      if (statusStr == 'completed') {
        responseStatus = QuestionnairePatientStatus.completed;
      } else if (statusStr == 'draft') {
        responseStatus = QuestionnairePatientStatus.draft;
      }
    }

    return QuestionnaireAssignment(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      questionnaireId: json['questionnaire_id'] as String,
      questionnaireName: questionnaire['name'] as String? ?? '',
      questionnaireCode: questionnaire['code'] as String? ?? '',
      assignedByName: assignedBy['full_name'] as String? ?? '',
      assignedAt: DateTime.parse(json['assigned_at'] as String),
      message: json['message'] as String?,
      responseId: json['response_id'] as String?,
      responseStatus: responseStatus,
    );
  }
}
