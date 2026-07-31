import '../../questionnaires/domain/question_answer_type.dart';
import '../utils/likert_labels.dart';

/// Pergunta com resposta gravada (detalhe).
class AnsweredQuestion {
  const AnsweredQuestion({
    required this.answerId,
    required this.questionId,
    required this.code,
    required this.text,
    required this.orderIndex,
    required this.answerType,
    this.scaleMin,
    this.scaleMax,
    this.answerValue,
    this.professionalValue,
    this.professionalNote,
    this.contextLabel,
  });

  /// Id da linha de resposta (questionnaire_answers.id) — chave dos ajustes
  /// da régua (em instrumentos parentais a mesma pergunta repete por figura).
  final String answerId;
  final String questionId;
  final String code;
  final String text;
  final int orderIndex;
  final QuestionAnswerType answerType;
  final int? scaleMin;
  final int? scaleMax;
  final double? answerValue;

  /// Nota validada pelo psicólogo ao "passar a régua" (null = sem ajuste).
  final double? professionalValue;

  /// Observação do psicólogo sobre o item.
  final String? professionalNote;
  final String? contextLabel;

  factory AnsweredQuestion.fromJson(Map<String, dynamic> json) {
    final question = json['question'];
    Map<String, dynamic> q = {};
    if (question is Map) {
      q = Map<String, dynamic>.from(question);
    }
    final responseContext = json['response_context'];
    String? contextLabel;
    if (responseContext is Map) {
      contextLabel = responseContext['context_label'] as String?;
    }

    return AnsweredQuestion(
      answerId: json['id'] as String? ?? '',
      questionId: q['id'] as String? ?? json['question_id'] as String,
      code: q['code'] as String? ?? '-',
      text: q['text'] as String? ?? '',
      orderIndex: q['order_index'] as int? ?? 0,
      answerType: QuestionAnswerType.fromString(
        q['answer_type'] as String? ?? 'likert_scale',
      ),
      scaleMin: q['scale_min'] as int?,
      scaleMax: q['scale_max'] as int?,
      answerValue: _num(json['answer_value']),
      professionalValue: _num(json['professional_value']),
      professionalNote: json['professional_note'] as String?,
      contextLabel: contextLabel,
    );
  }

  String get answerDisplayLabel => formatAnswerLabel(
        answerType: answerType,
        value: answerValue,
        scaleMin: scaleMin,
        scaleMax: scaleMax,
      );

  String get professionalDisplayLabel => formatAnswerLabel(
        answerType: answerType,
        value: professionalValue,
        scaleMin: scaleMin,
        scaleMax: scaleMax,
      );

  bool get hasAnswer => answerValue != null;

  /// Item ajustado na régua (nota do psicólogo difere da do paciente).
  bool get hasAdjustment =>
      professionalValue != null && professionalValue != answerValue;

  /// Valor que vale para o resultado validado.
  double? get effectiveValue => professionalValue ?? answerValue;
}

double? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
