import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../domain/questionnaire_question.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Limite acima do qual a escala usa slider em vez de botões segmentados.
const _segmentedThreshold = 7;

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
    final theme = Theme.of(context);

    if (!question.answerType.supportsNumericSubmission) {
      return ClayCard(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Perguntas em texto ainda não estão disponíveis nesta versão do app.',
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
        ),
      );
    }

    final values = question.scaleValues;
    final isBinary =
        values.length == 2 && question.scaleMin == 0 && question.scaleMax == 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isBinary)
          _BinaryChoice(
            question: question,
            value: value,
            onChanged: onChanged,
          )
        else if (values.length <= _segmentedThreshold)
          _SegmentedScale(
            values: values,
            value: value,
            onChanged: onChanged,
          )
        else
          _SliderScale(
            question: question,
            values: values,
            value: value,
            onChanged: onChanged,
          ),
        AnimatedSize(
          duration: AppAnimations.resolve(context, AppAnimations.fast),
          curve: AppAnimations.standardCurve,
          child: errorText == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Botões segmentados para escalas Likert curtas (ex.: 1–6).
class _SegmentedScale extends StatelessWidget {
  const _SegmentedScale({
    required this.values,
    required this.value,
    required this.onChanged,
  });

  final List<int> values;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: values.map((v) {
            final selected = value == v;
            return _ScaleButton(
              label: '$v',
              selected: selected,
              onTap: () => onChanged(v),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Menos',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Mais',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Opção $label',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimations.resolve(context, AppAnimations.fast),
          curve: AppAnimations.standardCurve,
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: selected ? scheme.primary : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.28),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: AppAnimations.resolve(context, AppAnimations.fast),
            style: theme.textTheme.titleMedium!.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

/// Duas opções amplas para perguntas Sim/Não.
class _BinaryChoice extends StatelessWidget {
  const _BinaryChoice({
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final QuestionnaireQuestion question;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BinaryCard(
            label: question.answerLabelFor(1),
            icon: Icons.check_circle_outline,
            selected: value == 1,
            onTap: () => onChanged(1),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BinaryCard(
            label: question.answerLabelFor(0),
            icon: Icons.cancel_outlined,
            selected: value == 0,
            onTap: () => onChanged(0),
          ),
        ),
      ],
    );
  }
}

class _BinaryCard extends StatelessWidget {
  const _BinaryCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppAnimations.resolve(context, AppAnimations.fast),
          curve: AppAnimations.standardCurve,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.10)
                : scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? scheme.primary : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 30,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selected ? scheme.primary : scheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slider refinado para escalas longas (mais de 7 valores).
class _SliderScale extends StatelessWidget {
  const _SliderScale({
    required this.question,
    required this.values,
    required this.value,
    required this.onChanged,
  });

  final QuestionnaireQuestion question;
  final List<int> values;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final min = question.scaleMin ?? values.first;
    final max = question.scaleMax ?? values.last;

    return Column(
      children: [
        AnimatedContainer(
          duration: AppAnimations.resolve(context, AppAnimations.fast),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color:
                value == null ? scheme.surfaceContainerHighest : scheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            value?.toString() ?? '—',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: value == null ? scheme.onSurfaceVariant : scheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
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
            Text('$min', style: theme.textTheme.bodySmall),
            Text('$max', style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}
