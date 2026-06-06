import '../../questionnaires/domain/question_answer_type.dart';
import '../utils/likert_labels.dart';

/// Pergunta com resposta gravada (detalhe).
class AnsweredQuestion {
  const AnsweredQuestion({
    required this.questionId,
    required this.code,
    required this.text,
    required this.orderIndex,
    required this.answerType,
    this.scaleMin,
    this.scaleMax,
    this.answerValue,
    this.contextLabel,
  });

  final String questionId;
  final String code;
  final String text;
  final int orderIndex;
  final QuestionAnswerType answerType;
  final int? scaleMin;
  final int? scaleMax;
  final double? answerValue;
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
      questionId: q['id'] as String? ?? json['question_id'] as String,
      code: q['code'] as String? ?? '—',
      text: q['text'] as String? ?? '',
      orderIndex: q['order_index'] as int? ?? 0,
      answerType: QuestionAnswerType.fromString(
        q['answer_type'] as String? ?? 'likert_scale',
      ),
      scaleMin: q['scale_min'] as int?,
      scaleMax: q['scale_max'] as int?,
      answerValue: _num(json['answer_value']),
      contextLabel: contextLabel,
    );
  }

  String get answerDisplayLabel => formatAnswerLabel(
        answerType: answerType,
        value: answerValue,
        scaleMin: scaleMin,
        scaleMax: scaleMax,
      );

  bool get hasAnswer => answerValue != null;
}

double? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
