import 'package:flutter/material.dart';

import '../../domain/scoring_domain_result.dart';
import '../../domain/scoring_item_result.dart';
import '../../domain/scoring_schema_result.dart';
import '../../domain/scoring_severity.dart';
import '../../domain/scoring_snapshot.dart';
import '../../domain/scoring_summary.dart';

/// Banner de aviso conforme o questionário (DEMO vs clínico estruturado).
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
  });

  final ScoringSnapshot scoring;
  final String? snapshotVersion;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoringMetaCard(
          snapshotVersion: snapshotVersion ?? ScoringSnapshot.demoVersion,
          scoring: scoring,
        ),
        if (scoring.summary.hasContent) ...[
          const SizedBox(height: 12),
          _SummaryCard(summary: scoring.summary),
        ],
        if (scoring.domains.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _GroupSectionTitle('Domínios'),
          ...scoring.domains.map((d) => _DomainCard(domain: d)),
        ],
        if (scoring.schemas.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _GroupSectionTitle('Esquemas'),
          ...scoring.schemas.map((s) => _SchemaCard(schema: s)),
        ],
        if (scoring.items.isNotEmpty) ...[
          const SizedBox(height: 16),
          const _GroupSectionTitle('Itens respondidos'),
          ...scoring.items.map((i) => _ScoringItemCard(item: i)),
        ],
      ],
    );
  }
}

class _ScoringMetaCard extends StatelessWidget {
  const _ScoringMetaCard({
    required this.snapshotVersion,
    required this.scoring,
  });

  final String snapshotVersion;
  final ScoringSnapshot scoring;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apuração DEMO',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _InfoRow(label: 'Versão do snapshot', value: snapshotVersion),
            if (scoring.questionnaireVersionLabel != null)
              _InfoRow(
                label: 'Versão do questionário',
                value: scoring.questionnaireVersionLabel!,
              ),
            if (scoring.scoringMethod != null)
              _InfoRow(label: 'Método', value: scoring.scoringMethod!),
            if (scoring.scaleMin != null && scoring.scaleMax != null)
              _InfoRow(
                label: 'Escala',
                value: '${scoring.scaleMin} a ${scoring.scaleMax}',
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ScoringSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo geral',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (summary.answeredItems != null)
              _InfoRow(
                label: 'Itens respondidos',
                value: '${summary.answeredItems}',
              ),
            if (summary.weightedScore != null)
              _InfoRow(
                label: 'Pontuação ponderada',
                value: summary.weightedScore!.toStringAsFixed(2),
              ),
            if (summary.averageScore != null)
              _InfoRow(
                label: 'Média',
                value: summary.averageScore!.toStringAsFixed(2),
              ),
            if (summary.rawScore != null)
              _InfoRow(
                label: 'Soma bruta (ajustada)',
                value: summary.rawScore!.toStringAsFixed(2),
              ),
            if (summary.maxPossibleScore != null)
              _InfoRow(
                label: 'Máximo possível',
                value: summary.maxPossibleScore!.toStringAsFixed(2),
              ),
          ],
        ),
      ),
    );
  }
}

class _DomainCard extends StatelessWidget {
  const _DomainCard({required this.domain});

  final ScoringDomainResult domain;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _GroupScoreBody(
          title: domain.name,
          subtitle: domain.code,
          rawScore: domain.rawScore,
          weightedScore: domain.weightedScore,
          averageScore: domain.averageScore,
          answeredItems: domain.answeredItems,
          severity: domain.severity,
        ),
      ),
    );
  }
}

class _SchemaCard extends StatelessWidget {
  const _SchemaCard({required this.schema});

  final ScoringSchemaResult schema;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _GroupScoreBody(
          title: schema.name,
          subtitle: schema.code,
          rawScore: schema.rawScore,
          weightedScore: schema.weightedScore,
          averageScore: schema.averageScore,
          answeredItems: schema.answeredItems,
          severity: schema.severity,
        ),
      ),
    );
  }
}

class _GroupScoreBody extends StatelessWidget {
  const _GroupScoreBody({
    required this.title,
    required this.subtitle,
    this.rawScore,
    this.weightedScore,
    this.averageScore,
    this.answeredItems,
    this.severity,
  });

  final String title;
  final String subtitle;
  final double? rawScore;
  final double? weightedScore;
  final double? averageScore;
  final int? answeredItems;
  final ScoringSeverity? severity;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        if (severity != null && severity!.hasLabel)
          _SeverityChip(severity: severity!),
        if (averageScore != null)
          _InfoRow(label: 'Média', value: averageScore!.toStringAsFixed(2)),
        if (weightedScore != null)
          _InfoRow(
            label: 'Pontuação ponderada',
            value: weightedScore!.toStringAsFixed(2),
          ),
        if (answeredItems != null)
          _InfoRow(label: 'Itens', value: '$answeredItems'),
        if (rawScore != null)
          _InfoRow(label: 'Soma bruta', value: rawScore!.toStringAsFixed(2)),
        if (severity == null || !severity!.hasLabel)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Severidade não classificada',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severity});

  final ScoringSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Chip(
        avatar: const Icon(Icons.flag_outlined, size: 18),
        label: Text('Severidade DEMO: ${severity.label}'),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

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
