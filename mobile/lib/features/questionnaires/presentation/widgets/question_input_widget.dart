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

/// Escala Likert curta (ex.: 1–6) como um TRILHO contínuo com gradiente:
/// as paradas ficam sobre um trilho que evolui de "Menos" → "Mais", e a
/// seleção vira uma pílula preenchida e maior. Comunica o contínuo da escala.
class _SegmentedScale extends StatelessWidget {
  const _SegmentedScale({
    required this.values,
    required this.value,
    required this.onChanged,
  });

  final List<int> values;
  final int? value;
  final ValueChanged<int> onChanged;

  // Largura fixa de cada parada — mantém os centros estáveis (a pílula cresce
  // dentro do slot), o que alinha o trilho com as pontas.
  static const _slot = 48.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      children: [
        SizedBox(
          height: 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Trilho com gradiente, entre os centros da 1ª e da última parada.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: _slot / 2),
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary.withValues(alpha: 0.22),
                        scheme.primary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: values
                    .map((v) => _ScaleStop(
                          slot: _slot,
                          label: '$v',
                          selected: value == v,
                          onTap: () => onChanged(v),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _anchor(theme, 'Menos'),
            _anchor(theme, 'Mais'),
          ],
        ),
      ],
    );
  }

  Widget _anchor(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      );
}

/// Uma parada do trilho — círculo pequeno quando não selecionado, pílula
/// preenchida e maior quando selecionado, com um "brilho" (anel que pulsa)
/// ao ser escolhida.
class _ScaleStop extends StatefulWidget {
  const _ScaleStop({
    required this.slot,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final double slot;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ScaleStop> createState() => _ScaleStopState();
}

class _ScaleStopState extends State<_ScaleStop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(covariant _ScaleStop old) {
    super.didUpdateWidget(old);
    // Pulso do anel só quando passa a ser o selecionado.
    if (!old.selected && widget.selected && AppAnimations.shouldAnimate(context)) {
      _ring.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = widget.selected;
    final diameter = selected ? 46.0 : 34.0;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Opção ${widget.label}',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: widget.slot,
          height: 58,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Brilho: anel que expande e some ao selecionar.
                AnimatedBuilder(
                  animation: _ring,
                  builder: (context, child) {
                    if (_ring.isDismissed) return const SizedBox.shrink();
                    final t = Curves.easeOut.transform(_ring.value);
                    return Opacity(
                      opacity: (1 - t) * 0.55,
                      child: Container(
                        width: 46 + t * 28,
                        height: 46 + t * 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: scheme.primary, width: 2),
                        ),
                      ),
                    );
                  },
                ),
                AnimatedContainer(
                  duration: AppAnimations.resolve(context, AppAnimations.fast),
                  curve: AppAnimations.standardCurve,
                  width: diameter,
                  height: diameter,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? scheme.primary : scheme.surface,
                    border: Border.all(
                      color: selected ? scheme.primary : theme.dividerColor,
                      width: selected ? 2 : 1.4,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: AnimatedDefaultTextStyle(
                    duration:
                        AppAnimations.resolve(context, AppAnimations.fast),
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                    child: Text(widget.label),
                  ),
                ),
              ],
            ),
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
