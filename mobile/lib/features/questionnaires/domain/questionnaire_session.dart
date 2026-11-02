import 'questionnaire.dart';
import 'questionnaire_question.dart';
import 'questionnaire_response_context.dart';

/// Sessão ativa após `start-questionnaire`.
class QuestionnaireSession {
  const QuestionnaireSession({
    required this.responseId,
    required this.patientId,
    required this.questionnaire,
    required this.questions,
    this.contexts = const [],
  });

  final String responseId;
  final String patientId;
  final Questionnaire questionnaire;
  final List<QuestionnaireQuestion> questions;
  final List<QuestionnaireResponseContext> contexts;

  /// Mesma sessão com o questionário do catálogo (que traz os textos do
  /// paciente, ausentes na resposta da função de início).
  QuestionnaireSession withQuestionnaire(Questionnaire catalog) =>
      QuestionnaireSession(
        responseId: responseId,
        patientId: patientId,
        questionnaire: catalog,
        questions: questions,
        contexts: contexts,
      );

  factory QuestionnaireSession.fromStartResponse(
    Map<String, dynamic> data,
    String patientId,
  ) {
    final response = Map<String, dynamic>.from(data['response'] as Map);
    final questionnaire = Questionnaire.fromJson(
        Map<String, dynamic>.from(data['questionnaire'] as Map));
    final questions = (data['questions'] as List? ?? [])
        .map(
          (q) => QuestionnaireQuestion.fromJson(
            Map<String, dynamic>.from(q as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final contexts = (data['contexts'] as List? ?? [])
        .map(
          (c) => QuestionnaireResponseContext.fromJson(
            Map<String, dynamic>.from(c as Map),
          ),
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return QuestionnaireSession(
      responseId: response['id'] as String,
      patientId: patientId,
      questionnaire: questionnaire,
      questions: questions,
      contexts: contexts,
    );
  }

  int get totalQuestions => questions.length;

  bool get hasContexts => contexts.isNotEmpty;
}
