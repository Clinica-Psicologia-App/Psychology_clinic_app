import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/schema_activation.dart';
import '../../domain/scoring_schema_result.dart';
import '../../domain/scoring_snapshot.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Horizontal bar chart showing all schema scores.
/// ● = auto-activated (score ≥ 4.0), ◎ = psi-activated.
class SchemaBarChartSection extends StatelessWidget {
  const SchemaBarChartSection({
    super.key,
    required this.scoring,
    required this.activations,
    this.showLegend = true,
  });

  final ScoringSnapshot scoring;
  final List<SchemaActivation> activations;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final schemas = [...scoring.schemas];
    if (schemas.isEmpty) return const SizedBox.shrink();

    schemas.sort(
      (a, b) => (b.averageScore ?? 0).compareTo(a.averageScore ?? 0),
    );

    final scaleMin = (scoring.scaleMin ?? 1).toDouble();
    final scaleMax = (scoring.scaleMax ?? 6).toDouble();
    final psiCodes = {for (final a in activations) a.schemaCode};

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Pontuação por esquema',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...schemas.map(
              (s) => _SchemaBarRow(
                schema: s,
                scaleMin: scaleMin,
                scaleMax: scaleMax,
                isPsiActivated: psiCodes.contains(s.code),
              ),
            ),
            const SizedBox(height: 8),
            _ThresholdNote(),
            if (showLegend) ...[
              const SizedBox(height: 8),
              const _SymbolLegend(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SchemaBarRow extends StatelessWidget {
  const _SchemaBarRow({
    required this.schema,
    required this.scaleMin,
    required this.scaleMax,
    required this.isPsiActivated,
  });

  final ScoringSchemaResult schema;
  final double scaleMin;
  final double scaleMax;
  final bool isPsiActivated;

  bool get _isAutoActivated =>
      (schema.averageScore ?? 0) >= kSchemaActivationThreshold;

  Color _barColor() {
    if (_isAutoActivated) return const Color(0xFFE24B4A);
    if (isPsiActivated) return AppColors.purple;
    return const Color(0xFF0F6E56);
  }

  String _symbol() {
    if (_isAutoActivated) return '●';
    if (isPsiActivated) return '◎';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final avg = schema.averageScore;
    final range = scaleMax - scaleMin;
    final progress = (avg != null && range > 0)
        ? ((avg - scaleMin) / range).clamp(0.0, 1.0)
        : 0.0;
    final color = _barColor();
    final symbol = _symbol();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 10,
            child: symbol.isEmpty
                ? null
                : Text(
                    symbol,
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 116,
            child: Text(
              schema.name,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(
              avg?.toStringAsFixed(1) ?? '-',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdNote extends StatelessWidget {
  const _ThresholdNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 130),
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Limiar de ativação: 4.0',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.orange.shade700,
                fontSize: 10,
              ),
        ),
      ],
    );
  }
}

class _SymbolLegend extends StatelessWidget {
  const _SymbolLegend();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _LegendItem(
            symbol: '●',
            color: Color(0xFFE24B4A),
            label: 'Auto-ativado (score ≥ 4)',
          ),
          _LegendItem(
            symbol: '◎',
            color: AppColors.purple,
            label: 'Ativado pelo psicólogo',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.symbol,
    required this.color,
    required this.label,
  });

  final String symbol;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          symbol,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
