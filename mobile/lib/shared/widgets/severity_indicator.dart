import 'package:flutter/material.dart';

import '../../core/theme/app_radius.dart';
import '../../core/theme/app_severity.dart';
import '../../core/theme/app_spacing.dart';

/// Badge de severidade clínica: ícone + rótulo sobre fundo tonalizado.
///
/// Nunca comunica severidade apenas por cor — o ícone e o texto fazem
/// parte do significado.
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({
    super.key,
    required this.severity,
    this.label,
    this.compact = false,
  });

  /// Constrói a partir da `color_key` do backend.
  SeverityBadge.fromColorKey(
    String? colorKey, {
    super.key,
    this.label,
    this.compact = false,
  }) : severity = AppSeverity.fromColorKey(colorKey);

  final AppSeverity severity;

  /// Rótulo vindo do instrumento; se nulo usa o padrão do nível.
  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim().isNotEmpty == true
        ? label!
        : severity.defaultLabel;

    return Semantics(
      label: 'Severidade: $text',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? AppSpacing.xs : AppSpacing.sm,
          vertical: compact ? 2 : AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: severity.container,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: severity.color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              severity.icon,
              size: compact ? 12 : 14,
              color: severity.onContainer,
            ),
            SizedBox(width: compact ? 3 : AppSpacing.xxs),
            Text(
              text,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: severity.onContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ponto de severidade para contextos densos (nós do mapa mental, listas).
///
/// Use somente quando o rótulo textual estiver visível ao lado ou no
/// detalhe imediato; caso contrário prefira [SeverityBadge].
class SeverityDot extends StatelessWidget {
  const SeverityDot({
    super.key,
    required this.severity,
    this.size = 10,
  });

  SeverityDot.fromColorKey(
    String? colorKey, {
    super.key,
    this.size = 10,
  }) : severity = AppSeverity.fromColorKey(colorKey);

  final AppSeverity severity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Severidade ${severity.defaultLabel}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: severity.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: severity.onContainer.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
    );
  }
}

/// Barra de progresso/escore colorida por severidade.
class SeverityBar extends StatelessWidget {
  const SeverityBar({
    super.key,
    required this.value,
    required this.severity,
    this.minHeight = 8,
  });

  SeverityBar.fromColorKey({
    super.key,
    required this.value,
    required String? colorKey,
    this.minHeight = 8,
  }) : severity = AppSeverity.fromColorKey(colorKey);

  /// Valor normalizado 0..1.
  final double value;
  final AppSeverity severity;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(minHeight),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: minHeight,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: severity.hasSeverity
            ? severity.color
            : theme.colorScheme.primary,
      ),
    );
  }
}
