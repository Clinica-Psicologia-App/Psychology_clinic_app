import 'question_answer_type.dart';

class QuestionnaireQuestion {
  const QuestionnaireQuestion({
    required this.id,
    required this.code,
    required this.text,
    required this.orderIndex,
    required this.answerType,
    this.scaleMin,
    this.scaleMax,
  });

  final String id;
  final String code;
  final String text;
  final int orderIndex;
  final QuestionAnswerType answerType;
  final int? scaleMin;
  final int? scaleMax;

  factory QuestionnaireQuestion.fromJson(Map<String, dynamic> json) {
    return QuestionnaireQuestion(
      id: json['id'] as String,
      code: json['code'] as String,
      text: json['text'] as String,
      orderIndex: json['order_index'] as int? ?? 0,
      answerType: QuestionAnswerType.fromString(
        json['answer_type'] as String? ?? 'likert_scale',
      ),
      scaleMin: json['scale_min'] as int?,
      scaleMax: json['scale_max'] as int?,
    );
  }

  List<int> get scaleValues {
    final min = scaleMin ?? 1;
    final max = scaleMax ?? min;
    if (max < min) return [min];
    return List.generate(max - min + 1, (i) => min + i);
  }

  String answerLabelFor(int value) {
    if (answerType == QuestionAnswerType.singleChoice &&
        scaleMin == 0 &&
        scaleMax == 1) {
      return value == 1 ? 'Sim' : 'Não';
    }
    return '$value';
  }

  String? validateAnswer(int? value) {
    if (value == null) return 'Selecione uma resposta';
    if (!answerType.supportsNumericSubmission) {
      return 'Tipo de pergunta não suportado nesta versão';
    }
    final min = scaleMin;
    final max = scaleMax;
    if (min != null && value < min) {
      return 'Valor mínimo: $min';
    }
    if (max != null && value > max) {
      return 'Valor máximo: $max';
    }
    return null;
  }
}
