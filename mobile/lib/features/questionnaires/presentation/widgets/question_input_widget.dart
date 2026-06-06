import 'package:flutter/material.dart';

import '../../domain/question_answer_type.dart';
import '../../domain/questionnaire_question.dart';

class QuestionInputWidget extends StatelessWidget {
  const QuestionInputWidget({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final QuestionnaireQuestion question;
  final int? value;
  final ValueChanged<int> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    if (!question.answerType.supportsNumericSubmission) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Perguntas em texto ainda não estão disponíveis nesta versão do app.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
      );
    }

    final values = question.scaleValues;
    final min = question.scaleMin ?? values.first;
    final max = question.scaleMax ?? values.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.answerType == QuestionAnswerType.numericScale &&
            values.length > 2) ...[
          Text(
            value?.toString() ?? '—',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          Slider(
            value: (value ?? min).toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: value?.toString(),
            onChanged: (v) => onChanged(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$min', style: Theme.of(context).textTheme.bodySmall),
              Text('$max', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ] else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: values.map((v) {
              final selected = value == v;
              return ChoiceChip(
                label: Text(question.answerLabelFor(v)),
                selected: selected,
                onSelected: (_) => onChanged(v),
              );
            }).toList(),
          ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
