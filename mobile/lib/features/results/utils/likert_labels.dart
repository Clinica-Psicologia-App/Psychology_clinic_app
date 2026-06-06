import '../../questionnaires/domain/question_answer_type.dart';

/// Rótulos legíveis para valores Likert (MVP — escala 1–6 do seed).
String likertLabel(int value, {int? scaleMin, int? scaleMax}) {
  if (scaleMin == 1 && scaleMax == 6) {
    switch (value) {
      case 1:
        return '1 — Nunca';
      case 2:
        return '2 — Raramente';
      case 3:
        return '3 — Às vezes';
      case 4:
        return '4 — Frequentemente';
      case 5:
        return '5 — Quase sempre';
      case 6:
        return '6 — Sempre';
    }
  }
  return '$value';
}

String formatAnswerLabel({
  required QuestionAnswerType answerType,
  required double? value,
  int? scaleMin,
  int? scaleMax,
}) {
  if (value == null) return 'Sem resposta';

  final intValue = value.round();

  switch (answerType) {
    case QuestionAnswerType.likertScale:
      return likertLabel(intValue, scaleMin: scaleMin, scaleMax: scaleMax);
    case QuestionAnswerType.numericScale:
    case QuestionAnswerType.singleChoice:
      if (scaleMin != null && scaleMax != null) {
        return likertLabel(intValue, scaleMin: scaleMin, scaleMax: scaleMax);
      }
      return intValue.toString();
    case QuestionAnswerType.text:
      return value.toString();
  }
}
