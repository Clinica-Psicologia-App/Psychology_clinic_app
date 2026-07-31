import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/scoring_domain_result.dart';
import '../../domain/scoring_item_result.dart';
import '../../domain/scoring_schema_result.dart';
import '../../domain/scoring_severity.dart';
import '../../domain/scoring_snapshot.dart';
import '../../domain/scoring_summary.dart';

class ScoringStructuredDisclaimerBanner extends StatelessWidget {
  const ScoringStructuredDisclaimerBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colorScheme.onTertiaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloco principal da apuração estruturada (summary, domínios, esquemas, itens).
class ScoringDemoSection extends StatelessWidget {
  const ScoringDemoSection({
    super.key,
    required this.scoring,
    this.snapshotVersion,
    this.canAdjust = false,
    this.pendingSchemaScores,
    this.onSchemaAdjust,
  });

  final ScoringSnapshot scoring;
  final String? snapshotVersion;
  final bool canAdjust;
  final Map<String, double?>? pendingSchemaScores;
  final void Function(ScoringSchemaResult)? onSchemaAdjust;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetaInfoRow(
          snapshotVersion: snapshotVersion ?? ScoringSnapshot.demoVersion,
          scoring: scoring,
        ),
        if (!canAdjust && scoring.summary.hasContent) ...[
          const SizedBox(height: 10),
          _SummaryCard(summary: scoring.summary),
        ],
        if (scoring.domains.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _GroupSectionTitle('Domínios'),
          ...scoring.domains.map(
            (d) => _DomainCard(
              domain: d,
              scaleMin: scoring.scaleMin,
              scaleMax: scoring.scaleMax,
            ),
          ),
        ],
        if (scoring.schemas.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _GroupSectionTitle('Esquemas'),
          ...scoring.schemas.map(
            (s) => _SchemaCard(
              schema: s,
              canAdjust: canAdjust,
              pendingScore: pendingSchemaScores?[s.id],
              onAdjust:
                  onSchemaAdjust != null ? () => onSchemaAdjust!(s) : null,
              scaleMin: scoring.scaleMin,
              scaleMax: scoring.scaleMax,
            ),
          ),
        ],
        if (!canAdjust && scoring.items.isNotEmpty) ...[
          const SizedBox(height: 14),
          const _GroupSectionTitle('Itens respondidos'),
          ...scoring.items.map((i) => _ScoringItemCard(item: i)),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Severity helpers
// ---------------------------------------------------------------------------

Color _severityColor(ScoringSeverity? severity, BuildContext context) {
  if (severity == null || !severity.hasLabel) {
    return Theme.of(context).colorScheme.outline;
  }
  final l = severity.label.toLowerCase();
  if (l.contains('ativado') ||
      l.contains('alto') ||
      l.contains('severo') ||
      l.contains('grave')) {
    return const Color(0xFFE24B4A);
  }
  if (l.contains('médio') || l.contains('medio') || l.contains('moderado')) {
    return const Color(0xFFBA7517);
  }
  if (l.contains('leve') || l.contains('baixo')) {
    return const Color(0xFF639922);
  }
  if (l.contains('mínimo') || l.contains('minimo') || l.contains('minimal')) {
    return const Color(0xFF0F6E56);
  }
  return Theme.of(context).colorScheme.outline;
}

// ---------------------------------------------------------------------------
// Meta info — linha compacta no topo
// ---------------------------------------------------------------------------

class _MetaInfoRow extends StatelessWidget {
  const _MetaInfoRow({required this.snapshotVersion, required this.scoring});

  final String snapshotVersion;
  final ScoringSnapshot scoring;

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      'DEMO · $snapshotVersion',
      if (scoring.scoringMethod != null) scoring.scoringMethod!,
      if (scoring.scaleMin != null && scoring.scaleMax != null)
        'Escala ${scoring.scaleMin}–${scoring.scaleMax}',
    ];
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: chips
          .map(
            (c) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                c,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary card — compacto (apenas visão de leitura)
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ScoringSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = <_StatEntry>[
      if (summary.averageScore != null)
        _StatEntry('Média geral', summary.averageScore!.toStringAsFixed(2)),
      if (summary.answeredItems != null)
        _StatEntry('Itens', '${summary.answeredItems}'),
      if (summary.rawScore != null)
        _StatEntry('Soma bruta', summary.rawScore!.toStringAsFixed(0)),
      if (summary.maxPossibleScore != null)
        _StatEntry(
            'Máx. possível', summary.maxPossibleScore!.toStringAsFixed(0)),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo geral',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: items
                  .map(
                    (e) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.label,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        Text(
                          e.value,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatEntry {
  const _StatEntry(this.label, this.value);
  final String label;
  final String value;
}

// ---------------------------------------------------------------------------
// Schema card — design compacto com faixa de severidade
// ---------------------------------------------------------------------------

class _SchemaCard extends StatelessWidget {
  const _SchemaCard({
    required this.schema,
    this.canAdjust = false,
    this.pendingScore,
    this.onAdjust,
    this.scaleMin,
    this.scaleMax,
  });

  final ScoringSchemaResult schema;
  final bool canAdjust;
  final double? pendingScore;
  final VoidCallback? onAdjust;
  final int? scaleMin;
  final int? scaleMax;

  double? get _effectiveScore =>
      pendingScore ?? schema.professionalAverageScore;

  double? _progress(double displayScore) {
    final mn = scaleMin?.toDouble();
    final mx = scaleMax?.toDouble();
    if (mn == null || mx == null || mx <= mn) return null;
    return ((displayScore - mn) / (mx - mn)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final strip = _severityColor(schema.severity, context);
    final effectiveScore = _effectiveScore;
    final baseScore = schema.averageScore;
    final displayScore = effectiveScore ?? baseScore;
    final progress = displayScore != null ? _progress(displayScore) : null;
    final hasAdjust = effectiveScore != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: strip),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  schema.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  schema.code,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (hasAdjust && baseScore != null)
                                Text(
                                  baseScore.toStringAsFixed(2),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              Text(
                                displayScore?.toStringAsFixed(2) ?? '-',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          hasAdjust ? AppColors.purple : strip,
                                      height: 1.1,
                                    ),
                              ),
                              if (scaleMax != null)
                                Text(
                                  '/$scaleMax',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              hasAdjust ? AppColors.purple : strip,
                            ),
                            minHeight: 5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (schema.severity != null &&
                              schema.severity!.hasLabel)
                            _SeverityBadge(
                              label: schema.severity!.label,
                              color: strip,
                            )
                          else
                            Text(
                              'Sem classificação',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          const Spacer(),
                          if (hasAdjust)
                            _StatusPill(
                              label: pendingScore != null
                                  ? 'Pendente'
                                  : 'Validado',
                              color: AppColors.purple,
                            ),
                          if (canAdjust) ...[
                            if (hasAdjust) const SizedBox(width: 6),
                            _AdjustPill(
                              label: hasAdjust ? 'Editar' : 'Ajustar',
                              onTap: onAdjust,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Domain card — similar ao schema mas sem ajuste
// ---------------------------------------------------------------------------

class _DomainCard extends StatelessWidget {
  const _DomainCard({
    required this.domain,
    this.scaleMin,
    this.scaleMax,
  });

  final ScoringDomainResult domain;
  final int? scaleMin;
  final int? scaleMax;

  double? _progress() {
    final mn = scaleMin?.toDouble();
    final mx = scaleMax?.toDouble();
    final score = domain.averageScore;
    if (mn == null || mx == null || mx <= mn || score == null) {
      return null;
    }
    return ((score - mn) / (mx - mn)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final strip = _severityColor(domain.severity, context);
    final progress = _progress();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: strip),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  domain.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  domain.code,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                domain.averageScore?.toStringAsFixed(2) ?? '-',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: strip,
                                      height: 1.1,
                                    ),
                              ),
                              if (scaleMax != null)
                                Text(
                                  '/$scaleMax',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      if (progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(strip),
                            minHeight: 5,
                          ),
                        ),
                      ],
                      if (domain.severity != null &&
                          domain.severity!.hasLabel) ...[
                        const SizedBox(height: 8),
                        _SeverityBadge(
                          label: domain.severity!.label,
                          color: strip,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item card (leitura, sem redesign necessário)
// ---------------------------------------------------------------------------

class _ScoringItemCard extends StatelessWidget {
  const _ScoringItemCard({required this.item});

  final ScoringItemResult item;

  @override
  Widget build(BuildContext context) {
    final schemaLabel = item.schemaName ?? item.schemaCode;
    final domainLabel = item.domainName ?? item.domainCode;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.questionId != null)
              Text(
                'Pergunta',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            if (item.answerValue != null)
              _InfoRow(
                label: 'Resposta',
                value: item.answerValue!.toStringAsFixed(0),
              ),
            if (item.adjustedScore != null)
              _InfoRow(
                label: 'Score ajustado',
                value: item.adjustedScore!.toStringAsFixed(2),
              ),
            if (item.weightedScore != null)
              _InfoRow(
                label: 'Ponderado',
                value: item.weightedScore!.toStringAsFixed(2),
              ),
            if (schemaLabel != null)
              _InfoRow(label: 'Esquema', value: schemaLabel),
            if (domainLabel != null)
              _InfoRow(label: 'Domínio', value: domainLabel),
            if (item.reverseScore)
              Text(
                'Reverse scoring aplicado',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AdjustPill extends StatelessWidget {
  const _AdjustPill({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.purple.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.straighten_outlined,
              size: 13,
              color: AppColors.purple,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.purple,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSectionTitle extends StatelessWidget {
  const _GroupSectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
