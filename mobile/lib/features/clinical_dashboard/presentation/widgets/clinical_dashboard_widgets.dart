import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/clinical_kpi_chip.dart';
import '../../../../shared/widgets/homologation_ui.dart';
import 'clinical_dashboard_shared_widgets.dart';
import '../../../patient_problems/domain/patient_problem_status.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../results/domain/schema_activation.dart';
import '../../../results/providers/results_providers.dart';
import '../../../therapy_goals/domain/therapy_goal_status.dart';
import '../../domain/clinical_case_summary.dart';
import '../../domain/clinical_dashboard_callouts.dart';
import '../../domain/clinical_dashboard_data.dart';
import '../../domain/clinical_dashboard_score_row.dart';
import '../../domain/clinical_instrument_dashboard.dart';
import '../../domain/clinical_parental_dashboard.dart';
import '../../domain/consolidated_domain_group.dart';
import '../../domain/consolidated_schema_row.dart';
import '../clinical_dashboard_routes.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class ClinicalDashboardDisclaimerBanner extends StatelessWidget {
  const ClinicalDashboardDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomologationInfoBanner(
      title: 'Validação clínica',
      icon: Icons.verified_outlined,
      message: 'Dashboard em validação clínica. Use como apoio visual, '
          'não como diagnóstico. A interpretação é responsabilidade '
          'do profissional.',
    );
  }
}

class InstrumentDashboardCard extends StatefulWidget {
  const InstrumentDashboardCard({
    super.key,
    required this.title,
    required this.panel,
    this.icon = Icons.bar_chart_outlined,
    this.isStaff = false,
    this.patientId,
    this.role,
  });

  final String title;
  final ClinicalInstrumentDashboard panel;
  final IconData icon;
  final bool isStaff;
  final String? patientId;
  final ProfileRole? role;

  @override
  State<InstrumentDashboardCard> createState() =>
      _InstrumentDashboardCardState();
}

class _InstrumentDashboardCardState extends State<InstrumentDashboardCard> {
  bool _showAllScores = false;
  bool _showDomains = false;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final panel = widget.panel;
    final scoresShown = _showAllScores ? panel.allScores : panel.topScores;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomologationSectionHeader(
              icon: widget.icon,
              title: widget.title,
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
                message: 'O snapshot desta aplicação não contém esquemas ou '
                    'modos estruturados para exibir.',
              )
            else ...[
              Text(
                _showAllScores
                    ? 'Todos os scores (ordem decrescente)'
                    : 'Principais scores (ordem decrescente)',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              ...scoresShown.asMap().entries.map(
                    (entry) => HorizontalScoreBar(
                      rank: entry.key + 1,
                      row: entry.value,
                      maxScore: panel.barMaxScore,
                    ),
                  ),
              if (panel.hasMoreScores) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _showAllScores = !_showAllScores),
                  icon: Icon(
                    _showAllScores ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(
                    _showAllScores
                        ? 'Ver menos scores'
                        : 'Ver todos (${panel.allScores.length})',
                  ),
                ),
              ],
              if (panel.hasDomains) ...[
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => setState(() => _showDomains = !_showDomains),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Domínios clínicos (${panel.domainRows.length})',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        Icon(
                          _showDomains ? Icons.expand_less : Icons.expand_more,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showDomains) ...[
                  const SizedBox(height: 8),
                  ...panel.domainRows.asMap().entries.map(
                        (entry) => HorizontalScoreBar(
                          rank: entry.key + 1,
                          row: entry.value,
                          maxScore: panel.barMaxScore,
                        ),
                      ),
                ],
              ],
              if (widget.isStaff &&
                  widget.patientId != null &&
                  widget.role != null) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => context.push(
                      ClinicalDashboardRoutes.staffCompare(
                        role: widget.role!,
                        patientId: widget.patientId!,
                        questionnaireCode: panel.questionnaireCode,
                      ),
                    ),
                    icon: const Icon(Icons.compare_arrows_outlined, size: 18),
                    label: const Text('Histórico comparativo'),
                  ),
                ),
              ],
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
    return AnimatedClinicalScoreBar(
      row: row,
      maxScore: maxScore,
      rank: rank,
    );
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
    return ClayCard(
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

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.history,
              title: 'Histórico básico',
              subtitle: 'Últimas aplicações estruturadas concluídas',
            ),
            const SizedBox(height: 12),
            if (historyTiles.isEmpty)
              Text(
                'Nenhuma aplicação estruturada registrada para YSQ, YAMI ou apego.',
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
    return ClayCard(
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

class ClinicalCaseSummaryCard extends StatelessWidget {
  const ClinicalCaseSummaryCard({
    super.key,
    required this.summary,
  });

  final ClinicalCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final latestQuestionnaireLabel = summary.latestQuestionnaireAt != null
        ? loc.formatFullDate(summary.latestQuestionnaireAt!.toLocal())
        : 'Sem aplicação concluída';
    final latestCheckInLabel = summary.latestCheckIn != null
        ? '${loc.formatFullDate(summary.latestCheckIn!.checkedInAt.toLocal())} · '
            '${summary.latestCheckIn!.summaryLine}'
        : 'Nenhum check-in registrado';

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.health_and_safety_outlined,
              title: 'Resumo do caso',
              subtitle: 'Síntese clínica com base nos dados já registrados',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryChip(
                  label: 'Resultados estruturados',
                  value: '${summary.structuredResultCount}',
                ),
                _SummaryChip(
                  label: 'Problemas abertos',
                  value: '${summary.openProblemsCount}',
                ),
                _SummaryChip(
                  label: 'Objetivos ativos',
                  value: '${summary.activeGoalsCount}',
                ),
                _SummaryChip(
                  label: 'Eventos relevantes',
                  value: '${summary.relevantEventsCount}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SummaryLine(
              icon: Icons.quiz_outlined,
              label: 'Último questionário',
              value: latestQuestionnaireLabel,
            ),
            const SizedBox(height: 8),
            _SummaryLine(
              icon: Icons.monitor_heart_outlined,
              label: 'Último check-in',
              value: latestCheckInLabel,
            ),
            if (!summary.hasSummary)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Ainda não há dados suficientes para compor um resumo clínico do caso.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ClinicalCaseScoresCard extends StatelessWidget {
  const ClinicalCaseScoresCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rows,
    required this.emptyMessage,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<ClinicalDashboardScoreRow> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxScore = rows.isEmpty
        ? 6.0
        : rows.map((row) => row.score).reduce((a, b) => a > b ? a : b);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomologationSectionHeader(
              icon: icon,
              title: title,
              subtitle: subtitle,
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Text(
                emptyMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...rows.asMap().entries.map(
                    (entry) => HorizontalScoreBar(
                      rank: entry.key + 1,
                      row: entry.value,
                      maxScore: maxScore,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class ClinicalCaseProblemsGoalsCard extends StatelessWidget {
  const ClinicalCaseProblemsGoalsCard({
    super.key,
    required this.summary,
  });

  final ClinicalCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.flag_outlined,
              title: 'Problemas e objetivos',
              subtitle: 'Focos atuais e direção do tratamento',
            ),
            const SizedBox(height: 12),
            if (!summary.hasProblemsAndGoals)
              Text(
                'Nenhum problema ou objetivo ativo registrado até o momento.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              if (summary.highlightedProblems.isNotEmpty) ...[
                Text(
                  'Problemas em foco',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...summary.highlightedProblems.map(
                  (problem) => _CaseListTile(
                    icon: Icons.report_problem_outlined,
                    title: problem.title,
                    subtitle: [
                      problem.status.label,
                      if (problem.intensity != null)
                        'Intensidade ${problem.intensity}/10',
                      if (problem.category != null &&
                          problem.category!.isNotEmpty)
                        problem.category!,
                    ].join(' · '),
                  ),
                ),
              ],
              if (summary.highlightedGoals.isNotEmpty) ...[
                if (summary.highlightedProblems.isNotEmpty)
                  const SizedBox(height: 12),
                Text(
                  'Objetivos ativos',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...summary.highlightedGoals.map(
                  (goal) => _CaseListTile(
                    icon: Icons.track_changes_outlined,
                    title: goal.title,
                    subtitle: [
                      goal.status.label,
                      if (goal.targetDate != null)
                        'Meta ${MaterialLocalizations.of(context).formatFullDate(goal.targetDate!)}',
                    ].join(' · '),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class ClinicalCaseEventsCard extends StatelessWidget {
  const ClinicalCaseEventsCard({
    super.key,
    required this.summary,
  });

  final ClinicalCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.timeline_outlined,
              title: 'Eventos relevantes',
              subtitle: 'Linha do tempo com maior impacto registrado',
            ),
            const SizedBox(height: 12),
            if (!summary.hasRelevantEvents)
              Text(
                'Nenhum evento relevante registrado até o momento.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...summary.relevantEvents.map(
                (event) => _CaseListTile(
                  icon: event.isSensitive
                      ? Icons.visibility_off_outlined
                      : Icons.event_note_outlined,
                  title: event.title,
                  subtitle: [
                    event.dateLabel,
                    if (event.subtitleLine != null) event.subtitleLine!,
                  ].join(' · '),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    this.icon,
    this.animateFromZero = true,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool animateFromZero;

  @override
  Widget build(BuildContext context) {
    return ClinicalKpiChip(
      label: label,
      value: value,
      icon: icon,
      animateFromZero: animateFromZero && int.tryParse(value) != null,
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CaseListTile extends StatelessWidget {
  const _CaseListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class ClinicalExecutiveHeader extends StatelessWidget {
  const ClinicalExecutiveHeader({
    super.key,
    required this.summary,
  });

  final ClinicalCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final latestUpdateLabel = summary.latestClinicalUpdateAt != null
        ? loc.formatFullDate(summary.latestClinicalUpdateAt!.toLocal())
        : 'Sem atualização clínica registrada';
    final checkInLabel = summary.latestCheckIn != null
        ? summary.latestCheckIn!.summaryLine
        : 'Sem check-in';

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.patientName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Última atualização clínica: $latestUpdateLabel',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryChip(
                  label: 'Problemas ativos',
                  value: '${summary.openProblemsCount}',
                  icon: Icons.report_problem_outlined,
                ),
                _SummaryChip(
                  label: 'Objetivos ativos',
                  value: '${summary.activeGoalsCount}',
                  icon: Icons.flag_outlined,
                ),
                _SummaryChip(
                  label: 'Resultados',
                  value: '${summary.structuredResultCount}',
                  icon: Icons.analytics_outlined,
                ),
                _SummaryChip(
                  label: 'Último check-in',
                  value: checkInLabel,
                  icon: Icons.monitor_heart_outlined,
                  animateFromZero: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClinicalPriorityGrid extends StatelessWidget {
  const ClinicalPriorityGrid({
    super.key,
    required this.summary,
  });

  final ClinicalCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HomologationSectionHeader(
          icon: Icons.priority_high_outlined,
          title: 'Prioridades clínicas',
          subtitle: 'Destaques dos instrumentos e focos registrados',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final crossAxisCount = width >= 560 ? 2 : 1;
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: crossAxisCount == 2 ? 1.35 : 1.15,
              children: [
                _PriorityMiniCard(
                  title: 'Top esquemas YSQ',
                  icon: Icons.psychology_outlined,
                  rows: summary.topSchemas,
                  emptyMessage: 'Sem YSQ concluído',
                ),
                _PriorityMiniCard(
                  title: 'Top modos YAMI',
                  icon: Icons.self_improvement_outlined,
                  rows: summary.topModes,
                  emptyMessage: 'Sem YAMI concluído',
                ),
                _PriorityMiniCard(
                  title: 'Estilos de apego',
                  icon: Icons.favorite_border,
                  rows: summary.topAttachment,
                  emptyMessage: 'Sem apego concluído',
                ),
                _PriorityMiniCard(
                  title: 'Enfrentamento',
                  icon: Icons.shield_outlined,
                  rows: summary.topCoping,
                  emptyMessage: 'Sem YCI/YRAI concluído',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PriorityMiniCard extends StatelessWidget {
  const _PriorityMiniCard({
    required this.title,
    required this.icon,
    required this.rows,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final List<ClinicalDashboardScoreRow> rows;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxScore = rows.isEmpty
        ? 6.0
        : rows.map((row) => row.score).reduce((a, b) => a > b ? a : b);

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (rows.isEmpty)
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    emptyMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: rows
                      .take(3)
                      .map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: HorizontalScoreBar(
                            row: row,
                            maxScore: maxScore,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ClinicalRecentSignalsCard extends StatelessWidget {
  const ClinicalRecentSignalsCard({
    super.key,
    required this.summary,
  });

  final ClinicalCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final hasCheckIn = summary.latestCheckIn != null;
    final hasEvents = summary.hasRelevantEvents;
    final hasProblems = summary.highlightedProblems.isNotEmpty;
    final isEmpty = !hasCheckIn && !hasEvents && !hasProblems;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.monitor_heart_outlined,
              title: 'Sinais recentes',
              subtitle: 'Check-in, eventos e problemas mais intensos',
            ),
            const SizedBox(height: 12),
            if (isEmpty)
              Text(
                'Nenhum sinal recente registrado.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              if (hasCheckIn) ...[
                _SummaryLine(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Último check-in',
                  value:
                      '${loc.formatFullDate(summary.latestCheckIn!.checkedInAt.toLocal())} · '
                      '${summary.latestCheckIn!.summaryLine}',
                ),
                const SizedBox(height: 8),
              ],
              if (hasEvents) ...[
                Text(
                  'Eventos relevantes',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                ...summary.relevantEvents.take(3).map(
                      (event) => _CaseListTile(
                        icon: event.isSensitive
                            ? Icons.visibility_off_outlined
                            : Icons.event_note_outlined,
                        title: event.title,
                        subtitle: [
                          event.dateLabel,
                          if (event.emotionalImpact != null)
                            'Impacto ${event.emotionalImpact}/10',
                        ].join(' · '),
                      ),
                    ),
                const SizedBox(height: 8),
              ],
              if (hasProblems) ...[
                Text(
                  'Problemas mais intensos',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                ...summary.highlightedProblems.map(
                  (problem) => _CaseListTile(
                    icon: Icons.report_problem_outlined,
                    title: problem.title,
                    subtitle: [
                      problem.status.label,
                      if (problem.intensity != null)
                        'Intensidade ${problem.intensity}/10',
                    ].join(' · '),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class ClinicalDashboardCalloutsSection extends StatelessWidget {
  const ClinicalDashboardCalloutsSection({
    super.key,
    required this.callouts,
  });

  final List<ClinicalDashboardCallout> callouts;

  @override
  Widget build(BuildContext context) {
    if (callouts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.tips_and_updates_outlined,
              title: 'Orientações',
              subtitle: 'Próximos passos sugeridos sem interpretação clínica',
            ),
            const SizedBox(height: 12),
            ...callouts.map(
              (callout) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _iconForCallout(callout.kind),
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(callout.message)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCallout(ClinicalDashboardCalloutKind kind) {
    switch (kind) {
      case ClinicalDashboardCalloutKind.missingYsq:
      case ClinicalDashboardCalloutKind.missingYami:
        return Icons.quiz_outlined;
      case ClinicalDashboardCalloutKind.missingCheckIn:
        return Icons.monitor_heart_outlined;
    }
  }
}

class ParentalStylesDashboardSection extends StatefulWidget {
  const ParentalStylesDashboardSection({
    super.key,
    required this.dashboard,
  });

  final ClinicalParentalDashboard dashboard;

  @override
  State<ParentalStylesDashboardSection> createState() =>
      _ParentalStylesDashboardSectionState();
}

class _ParentalStylesDashboardSectionState
    extends State<ParentalStylesDashboardSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final dashboard = widget.dashboard;
    final loc = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final figures = dashboard.figures;

    if (figures.isEmpty) {
      return const ClinicalDashboardEmptyInstrumentCard(
        title: 'Estilos parentais',
        message:
            'Nenhuma resposta de estilos parentais concluída com figuras registradas.',
        icon: Icons.family_restroom_outlined,
      );
    }

    final safeIndex = _selectedIndex.clamp(0, figures.length - 1);
    final selected = figures[safeIndex];
    final maxScore = selected.topScores.isEmpty
        ? 6.0
        : selected.topScores
            .map((row) => row.score)
            .reduce((a, b) => a > b ? a : b);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.family_restroom_outlined,
              title: 'Estilos parentais',
              subtitle: 'Resultados separados por figura parental',
            ),
            if (dashboard.completedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Concluído em ${loc.formatFullDate(dashboard.completedAt!.toLocal())}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < figures.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: i == figures.length - 1 ? 0 : 8,
                      ),
                      child: ChoiceChip(
                        label: Text(figures[i].label),
                        selected: safeIndex == i,
                        onSelected: (_) => setState(() => _selectedIndex = i),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              selected.label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selected.answeredItemsLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (selected.summaryLine != null) ...[
              const SizedBox(height: 4),
              Text(
                selected.summaryLine!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!selected.hasScores)
              Text(
                'Esta figura não possui scores estruturados no snapshot.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...selected.topScores.map(
                (row) => HorizontalScoreBar(
                  row: row,
                  maxScore: maxScore,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ClinicalInstrumentDetailsSection extends StatelessWidget {
  const ClinicalInstrumentDetailsSection({
    super.key,
    required this.data,
    this.isStaff = false,
    this.patientId,
    this.role,
  });

  final ClinicalDashboardData data;
  final bool isStaff;
  final String? patientId;
  final ProfileRole? role;

  @override
  Widget build(BuildContext context) {
    return ExpandableDashboardSection(
      title: 'Detalhes por instrumento',
      subtitle: 'YSQ, YAMI, apego, parentais, YCI e YRAI',
      icon: Icons.bar_chart_outlined,
      initiallyExpanded: false,
      child: Column(
        children: [
          if (data.ysq != null)
            InstrumentDashboardCard(
              title: 'Esquemas - YSQ',
              panel: data.ysq!,
              icon: Icons.psychology_outlined,
              isStaff: isStaff,
              patientId: patientId,
              role: role,
            )
          else
            const ClinicalDashboardEmptyInstrumentCard(
              title: 'Esquemas - YSQ',
              message:
                  'Nenhuma resposta YSQ concluída com snapshot estruturado.',
              icon: Icons.psychology_outlined,
            ),
          if (data.yami != null)
            InstrumentDashboardCard(
              title: 'Modos - YAMI',
              panel: data.yami!,
              icon: Icons.self_improvement_outlined,
              isStaff: isStaff,
              patientId: patientId,
              role: role,
            )
          else
            const ClinicalDashboardEmptyInstrumentCard(
              title: 'Modos - YAMI',
              message:
                  'Nenhuma resposta YAMI concluída com snapshot estruturado.',
              icon: Icons.self_improvement_outlined,
            ),
          if (data.parental != null && data.parental!.figures.isNotEmpty)
            ParentalStylesDashboardSection(dashboard: data.parental!)
          else
            const ClinicalDashboardEmptyInstrumentCard(
              title: 'Estilos parentais',
              message:
                  'Nenhuma resposta de estilos parentais concluída. Aplique o '
                  'instrumento na trilha selecionando as figuras parentais.',
              icon: Icons.family_restroom_outlined,
            ),
          if (data.attachment != null)
            InstrumentDashboardCard(
              title: 'Estilos de apego',
              panel: data.attachment!,
              icon: Icons.favorite_border,
              isStaff: isStaff,
              patientId: patientId,
              role: role,
            )
          else
            const ClinicalDashboardEmptyInstrumentCard(
              title: 'Estilos de apego',
              message:
                  'Nenhuma resposta de apego concluída com snapshot estruturado.',
              icon: Icons.favorite_border,
            ),
          if (data.yci != null)
            InstrumentDashboardCard(
              title: 'Enfrentamento - YCI',
              panel: data.yci!,
              icon: Icons.shield_outlined,
              isStaff: isStaff,
              patientId: patientId,
              role: role,
            )
          else
            const ClinicalDashboardEmptyInstrumentCard(
              title: 'Enfrentamento - YCI',
              message:
                  'Nenhuma resposta YCI concluída com snapshot estruturado.',
              icon: Icons.shield_outlined,
            ),
          if (data.yrai != null)
            InstrumentDashboardCard(
              title: 'Enfrentamento - YRAI',
              panel: data.yrai!,
              icon: Icons.shield_outlined,
              isStaff: isStaff,
              patientId: patientId,
              role: role,
            )
          else
            const ClinicalDashboardEmptyInstrumentCard(
              title: 'Enfrentamento - YRAI',
              message:
                  'Nenhuma resposta YRAI concluída com snapshot estruturado.',
              icon: Icons.shield_outlined,
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PERFIL ESQUEMÁTICO CONSOLIDADO
// Card principal do Dashboard Clínico: todos os esquemas de todos os
// instrumentos numa visão única, dividida em Ativados × Não ativados.
// ═══════════════════════════════════════════════════════════════════════════

class ConsolidatedSchemaProfileCard extends ConsumerWidget {
  const ConsolidatedSchemaProfileCard({
    super.key,
    required this.data,
    required this.isStaff,
    this.onActivationChanged,
  });

  final ClinicalDashboardData data;
  final bool isStaff;

  /// Chamado após qualquer ativação/desativação para que a página
  /// invalide o provider e recarregue a lista consolidada.
  final VoidCallback? onActivationChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!data.hasConsolidatedSchemas) return const SizedBox.shrink();

    final activated = data.activatedSchemas;
    final domains = data.consolidatedDomains;
    final modes = data.consolidatedModes;
    final theme = Theme.of(context);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho tonal ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.surfaceTintBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .07),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.schema_outlined,
                    size: 18,
                    color: AppColors.moduleQuestionnaires,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Perfil Esquemático Consolidado',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                      ),
                      Text(
                        'Agrupado por domínio · ordem clínica',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _SchemaCountBadge(
                  count: activated.length,
                  color: AppColors.error,
                  label: 'ativos',
                ),
              ],
            ),
          ),

          // ── Dica de interação (só para o psicólogo) ────────────────────
          if (isStaff)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.touch_app_outlined,
                        size: 13, color: AppColors.purple),
                  ),
                  const SizedBox(width: 5),
                  // Expanded: sem ele a dica estoura o Row quando a fonte do
                  // sistema está ampliada ou a tela é estreita.
                  Expanded(
                    child: Text(
                      'Toque em qualquer esquema para ativar ou desativar',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.purple.withValues(alpha: 0.75),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Corpo: um bloco por domínio, em ordem canônica ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final domain in domains)
                  _DomainSection(
                    domain: domain,
                    isStaff: isStaff,
                    onActivationChanged: onActivationChanged,
                  ),
                // Modos do YAMI não pertencem aos domínios de Young — bloco
                // próprio no fim.
                if (!modes.isEmpty)
                  _ModeSection(
                    modes: modes,
                    isStaff: isStaff,
                    onActivationChanged: onActivationChanged,
                  ),
              ],
            ),
          ),

          // ── Legenda (somente para pacientes) ───────────────────────────
          if (!isStaff)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _LegendItem(symbol: '●', label: 'Ativado pelo sistema'),
                  _LegendItem(
                    symbol: '◎',
                    label: 'Ativado pelo profissional',
                    color: AppColors.purple,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bloco de domínio ────────────────────────────────────────────────────────

/// Uma cor por domínio. O esquema ativado aparece na cor do seu domínio; o não
/// ativado fica cinza. A cor identifica o domínio — não a severidade —, então
/// o contraste colorido × cinza é o que comunica ativação.
const List<Color> _kDomainColors = [
  Color(0xFF7C6A9C), // I  — Desconexão e rejeição
  Color(0xFF2E7D6B), // II — Autonomia e desempenho prejudicados
  Color(0xFFA6743C), // III — Limites prejudicados
  Color(0xFF4A6FA5), // IV — Orientação para o outro
  Color(0xFF9C5A6B), // V  — Hipervigilância e inibição
];

Color _domainColor(int order) =>
    _kDomainColors[order.clamp(0, _kDomainColors.length - 1)];

class _DomainSection extends StatelessWidget {
  const _DomainSection({
    required this.domain,
    required this.isStaff,
    this.onActivationChanged,
  });

  final ConsolidatedDomainGroup domain;
  final bool isStaff;
  final VoidCallback? onActivationChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _domainColor(domain.order);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Trilha lateral na cor do domínio — separa os blocos sem gastar
            // altura extra com bordas/padding de cartão.
            Container(
              width: 3,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          '${domain.numeral} · ${domain.name}',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          domain.coreNeed,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Leitura do domínio: quantos ativaram sobre o total.
                      // Não é nota nem ranking — domínios não competem entre
                      // si.
                      Text(
                        domain.activationLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              domain.hasActivated ? color : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Ordem canônica de Young, já aplicada em
                  // buildConsolidatedDomainGroups — não reordenar por score
                  // aqui: dentro do domínio a sequência é clínica, validada
                  // com a psicóloga responsável.
                  ...domain.schemas.map(
                    (schema) => _SchemaBarRow(
                      schema: schema,
                      domainColor: color,
                      isStaff: isStaff,
                      onActivationChanged: onActivationChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modos do YAMI — fora dos domínios de Young, que só organizam esquemas.
class _ModeSection extends StatelessWidget {
  const _ModeSection({
    required this.modes,
    required this.isStaff,
    this.onActivationChanged,
  });

  final ConsolidatedModeGroup modes;
  final bool isStaff;
  final VoidCallback? onActivationChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 9),
            child: Row(
              children: [
                const Icon(
                  Icons.theater_comedy_outlined,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Modos esquemáticos',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                Text(
                  '${modes.activatedCount} de ${modes.rows.length} ativados',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...modes.rows.map(
            (mode) => _SchemaBarRow(
              schema: mode,
              domainColor: AppColors.turquoise,
              isStaff: isStaff,
              onActivationChanged: onActivationChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Linha de esquema: nome, barra em escala do instrumento com a linha de corte
/// desenhada, e score. A linha de corte torna a ativação autoevidente — quem
/// cruza, ativou —, o que dispensa ordenar por score para enxergar o padrão.
class _SchemaBarRow extends ConsumerWidget {
  const _SchemaBarRow({
    required this.schema,
    required this.domainColor,
    required this.isStaff,
    this.onActivationChanged,
  });

  final ConsolidatedSchemaRow schema;
  final Color domainColor;
  final bool isStaff;
  final VoidCallback? onActivationChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activated = schema.isActivated;
    final color = activated ? domainColor : AppColors.disabled;
    final cutFraction =
        (kSchemaActivationThreshold / schema.barMax).clamp(0.0, 1.0);

    Widget row = Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ativado manualmente pelo profissional ganha marca própria.
          if (schema.isPsiActivated)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.adjust, size: 10, color: AppColors.purple),
            ),
          Expanded(
            child: Text(
              schema.name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: activated ? AppColors.navy : AppColors.textMuted,
                fontWeight: activated ? FontWeight.w600 : FontWeight.w400,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 74,
            child: _ThresholdBar(
              fraction: schema.barFraction,
              cutFraction: cutFraction,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Text(
              schema.score.toStringAsFixed(1),
              textAlign: TextAlign.right,
              style: theme.textTheme.labelSmall?.copyWith(
                color: activated ? color : AppColors.textMuted,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    if (isStaff) {
      row = InkWell(
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => _ConsolidatedActivationSheet(
            schema: schema,
            onChanged: onActivationChanged,
          ),
        ),
        borderRadius: BorderRadius.circular(6),
        child: row,
      );
    }

    return row;
  }
}

/// Barra com trilho e marca vertical no limiar de ativação.
class _ThresholdBar extends StatelessWidget {
  const _ThresholdBar({
    required this.fraction,
    required this.cutFraction,
    required this.color,
  });

  final double fraction;
  final double cutFraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 9,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: (width * fraction).clamp(0.0, width),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              // Marca do limiar (4.0): referência fixa em todas as barras.
              Positioned(
                left: (width * cutFraction).clamp(0.0, width - 1),
                top: -2,
                bottom: -2,
                width: 1.4,
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.textSecondary),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Sheet de ativação consolidada ───────────────────────────────────────────

class _ConsolidatedActivationSheet extends ConsumerStatefulWidget {
  const _ConsolidatedActivationSheet({
    required this.schema,
    this.onChanged,
  });

  final ConsolidatedSchemaRow schema;
  final VoidCallback? onChanged;

  @override
  ConsumerState<_ConsolidatedActivationSheet> createState() =>
      _ConsolidatedActivationSheetState();
}

class _ConsolidatedActivationSheetState
    extends ConsumerState<_ConsolidatedActivationSheet> {
  late final TextEditingController _obsController;
  bool _saving = false;

  bool get _isActivated => widget.schema.isActivated;
  bool get _isPsiActivated => widget.schema.isPsiActivated;

  @override
  void initState() {
    super.initState();
    _obsController = TextEditingController(
      text: widget.schema.psiObservation ?? '',
    );
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(
              manageSchemaActivationProvider(widget.schema.responseId).notifier)
          .activate(
            widget.schema.code,
            widget.schema.name,
            observation: _obsController.text.trim().isEmpty
                ? null
                : _obsController.text.trim(),
          );
      widget.onChanged?.call();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(
              manageSchemaActivationProvider(widget.schema.responseId).notifier)
          .deactivate(widget.schema.code);
      widget.onChanged?.call();
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAutoActivated = widget.schema.isAutoActivated;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _isActivated ? '●' : '◎',
                style: TextStyle(
                  color: isAutoActivated ? AppColors.error : AppColors.purple,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isPsiActivated
                      ? 'Editar ativação'
                      : isAutoActivated
                          ? 'Esquema ativo (sistema)'
                          : 'Ativar esquema',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.schema.name,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Score: ${widget.schema.score.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          if (widget.schema.instrumentName != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.schema.instrumentName!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (!isAutoActivated) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _obsController,
              decoration: const InputDecoration(
                labelText: 'Observação clínica (opcional)',
                hintText: 'Justificativa ou nota clínica para esta ativação',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_isPsiActivated)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _deactivate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Desativar'),
                    ),
                  ),
                if (_isPsiActivated) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isPsiActivated ? 'Salvar' : 'Ativar'),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ativado automaticamente pelo sistema (score ≥ 4.0).',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _SchemaCountBadge extends StatelessWidget {
  const _SchemaCountBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.symbol,
    required this.label,
    this.color = AppColors.error,
  });

  final String symbol;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          symbol,
          style: TextStyle(color: color, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      ],
    );
  }
}
