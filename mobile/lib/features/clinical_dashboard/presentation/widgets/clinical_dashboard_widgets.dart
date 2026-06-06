import 'package:flutter/material.dart';

import '../../../../shared/widgets/homologation_ui.dart';
import '../../domain/clinical_dashboard_score_row.dart';
import '../../domain/clinical_instrument_dashboard.dart';

class ClinicalDashboardDisclaimerBanner extends StatelessWidget {
  const ClinicalDashboardDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomologationInfoBanner(
      title: 'Validação clínica',
      icon: Icons.verified_outlined,
      message:
          'Dashboard em validação clínica. Use como apoio visual, '
          'não como diagnóstico. A interpretação é responsabilidade '
          'do profissional.',
    );
  }
}

class InstrumentDashboardCard extends StatelessWidget {
  const InstrumentDashboardCard({
    super.key,
    required this.title,
    required this.panel,
    this.icon = Icons.bar_chart_outlined,
  });

  final String title;
  final ClinicalInstrumentDashboard panel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomologationSectionHeader(
              icon: icon,
              title: title,
              subtitle: panel.questionnaireCode,
            ),
            if (panel.completedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_available_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Concluído em ${loc.formatFullDate(panel.completedAt!.toLocal())}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            if (panel.isEmpty)
              const HomologationEmptyPanel(
                icon: Icons.analytics_outlined,
                title: 'Sem scores nesta resposta',
                message:
                    'O snapshot desta aplicação não contém esquemas ou '
                    'modos estruturados para exibir.',
              )
            else ...[
              Text(
                'Principais scores (ordem decrescente)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...panel.topScores.asMap().entries.map(
                    (entry) => HorizontalScoreBar(
                      rank: entry.key + 1,
                      row: entry.value,
                      maxScore: panel.barMaxScore,
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class HorizontalScoreBar extends StatelessWidget {
  const HorizontalScoreBar({
    super.key,
    required this.row,
    required this.maxScore,
    this.rank,
  });

  final ClinicalDashboardScoreRow row;
  final double maxScore;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeMax = maxScore > 0 ? maxScore : 1.0;
    final fraction = (row.score / safeMax).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (rank != null) ...[
                CircleAvatar(
                  radius: 12,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '$rank',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (row.code.isNotEmpty)
                      Text(
                        row.code,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                row.score.toStringAsFixed(2),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: _barColor(theme, row),
            ),
          ),
          if (row.hasSeverity)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Severidade: ${row.severityLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _barColor(ThemeData theme, ClinicalDashboardScoreRow row) {
    final key = row.severityColorKey?.toLowerCase();
    switch (key) {
      case 'green':
        return Colors.green.shade600;
      case 'yellow':
      case 'amber':
        return Colors.amber.shade700;
      case 'orange':
        return Colors.orange.shade700;
      case 'red':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.primary;
    }
  }
}

class ClinicalDashboardEmptyInstrumentCard extends StatelessWidget {
  const ClinicalDashboardEmptyInstrumentCard({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.quiz_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: HomologationEmptyPanel(
          icon: icon,
          title: title,
          message: message,
          hint: 'Conclua o questionário correspondente na trilha.',
        ),
      ),
    );
  }
}

class ClinicalDashboardHistoryCard extends StatelessWidget {
  const ClinicalDashboardHistoryCard({
    super.key,
    required this.historyTiles,
  });

  final List<Widget> historyTiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.history,
              title: 'Histórico básico',
              subtitle: 'Últimas aplicações YSQ e YAMI concluídas',
            ),
            const SizedBox(height: 12),
            if (historyTiles.isEmpty)
              Text(
                'Nenhuma aplicação YSQ/YAMI registrada.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...historyTiles,
          ],
        ),
      ),
    );
  }
}

class ClinicalDashboardFutureSectionCard extends StatelessWidget {
  const ClinicalDashboardFutureSectionCard({
    super.key,
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomologationSectionHeader(
              icon: icon,
              title: title,
            ),
            const SizedBox(height: 12),
            const Text('Disponível em versão futura.'),
          ],
        ),
      ),
    );
  }
}
