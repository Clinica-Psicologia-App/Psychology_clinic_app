import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/homologation_ui.dart';
import '../../../profile/domain/profile_role.dart';
import '../../domain/mental_map_clinical_core.dart';
import '../../domain/mental_map_history_links.dart';
import '../../domain/mental_map_score_highlight.dart';
import '../../domain/mental_map_goal_summary.dart';
import '../../domain/mental_map_problem_summary.dart';
import '../../domain/mental_map_therapy_plan.dart';
import '../mental_map_navigation_targets.dart';

enum MentalMapFormulationTab { nucleus, history, plan }

class MentalMapFormulationTabs extends StatefulWidget {
  const MentalMapFormulationTabs({
    super.key,
    required this.clinicalCore,
    required this.historyLinks,
    required this.therapyPlan,
    required this.role,
    this.patientId,
  });

  final MentalMapClinicalCore clinicalCore;
  final MentalMapHistoryLinks historyLinks;
  final MentalMapTherapyPlan therapyPlan;
  final ProfileRole role;
  final String? patientId;

  @override
  State<MentalMapFormulationTabs> createState() =>
      _MentalMapFormulationTabsState();
}

class _MentalMapFormulationTabsState extends State<MentalMapFormulationTabs> {
  MentalMapFormulationTab _selected = MentalMapFormulationTab.nucleus;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.layers_outlined,
              title: 'Camadas da formulação',
              subtitle: 'Núcleo clínico, história/vínculos e plano terapêutico',
            ),
            const SizedBox(height: 12),
            _FormulationTabBar(
              selected: _selected,
              onSelected: (tab) => setState(() => _selected = tab),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_selected) {
                MentalMapFormulationTab.nucleus => MentalMapClinicalCoreSection(
                    key: const ValueKey('tab-nucleus'),
                    core: widget.clinicalCore,
                    role: widget.role,
                    patientId: widget.patientId,
                  ),
                MentalMapFormulationTab.history => MentalMapHistoryLinksSection(
                    key: const ValueKey('tab-history'),
                    history: widget.historyLinks,
                    role: widget.role,
                    patientId: widget.patientId,
                  ),
                MentalMapFormulationTab.plan => MentalMapTherapyPlanSection(
                    key: const ValueKey('tab-plan'),
                    plan: widget.therapyPlan,
                    role: widget.role,
                    patientId: widget.patientId,
                  ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FormulationTabBar extends StatelessWidget {
  const _FormulationTabBar({
    required this.selected,
    required this.onSelected,
  });

  final MentalMapFormulationTab selected;
  final ValueChanged<MentalMapFormulationTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = const [
      _FormulationTabButton(
        tab: MentalMapFormulationTab.nucleus,
        label: 'Nucleo',
        icon: Icons.psychology_outlined,
      ),
      _FormulationTabButton(
        tab: MentalMapFormulationTab.history,
        label: 'Historia',
        icon: Icons.timeline_outlined,
      ),
      _FormulationTabButton(
        tab: MentalMapFormulationTab.plan,
        label: 'Plano',
        icon: Icons.flag_outlined,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: tabs
            .map(
              (tab) => Expanded(
                child: _FormulationTabItem(
                  button: tab,
                  selected: selected == tab.tab,
                  onSelected: onSelected,
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _FormulationTabButton {
  const _FormulationTabButton({
    required this.tab,
    required this.label,
    required this.icon,
  });

  final MentalMapFormulationTab tab;
  final String label;
  final IconData icon;
}

class _FormulationTabItem extends StatelessWidget {
  const _FormulationTabItem({
    required this.button,
    required this.selected,
    required this.onSelected,
  });

  final _FormulationTabButton button;
  final bool selected;
  final ValueChanged<MentalMapFormulationTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () => onSelected(button.tab),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected
                  ? Theme.of(context).colorScheme.secondary
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(button.icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                button.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MentalMapClinicalCoreSection extends StatelessWidget {
  const MentalMapClinicalCoreSection({
    super.key,
    required this.core,
    required this.role,
    this.patientId,
  });

  final MentalMapClinicalCore core;
  final ProfileRole role;
  final String? patientId;

  @override
  Widget build(BuildContext context) {
    if (!core.hasContent) {
      return const HomologationEmptyPanel(
        icon: Icons.psychology_outlined,
        title: 'Núcleo clínico vazio',
        message:
            'Conclua YSQ/YAMI e registre problemas para preencher esta camada.',
        hint: 'Os dados exibidos vêm dos instrumentos e registros existentes.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 640;
        final schemaPanel = _InstrumentScorePanel(
          title: 'Esquemas (YSQ)',
          completedAt: core.ysqCompletedAt,
          highlights: core.topSchemas,
          emptyMessage: 'Nenhum resultado YSQ disponível.',
        );
        final modePanel = _InstrumentScorePanel(
          title: 'Modos (YAMI)',
          completedAt: core.yamiCompletedAt,
          highlights: core.topModes,
          emptyMessage: 'Nenhum resultado YAMI disponível.',
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (useTwoColumns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: schemaPanel),
                  const SizedBox(width: 12),
                  Expanded(child: modePanel),
                ],
              )
            else ...[
              schemaPanel,
              const SizedBox(height: 12),
              modePanel,
            ],
            const SizedBox(height: 12),
            _ActiveProblemsPanel(problems: core.topProblemsByIntensity),
            if (core.hasAttachment || core.hasCoping) ...[
              const SizedBox(height: 12),
              if (core.hasAttachment)
                _InstrumentScorePanel(
                  title: 'Estilos de apego',
                  completedAt: core.attachmentCompletedAt,
                  highlights: core.attachmentStyles,
                  emptyMessage: 'Instrumento de apego pendente.',
                  compact: true,
                ),
              if (core.hasCoping) ...[
                const SizedBox(height: 12),
                _InstrumentScorePanel(
                  title: 'Estilos de enfrentamento',
                  completedAt: core.copingCompletedAt,
                  highlights: core.copingStyles,
                  emptyMessage: 'YCI/YRAI pendente.',
                  compact: true,
                ),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              'Esquemas e modos provêm de instrumentos; problemas são '
              'registrados pelo paciente/equipe. Sem relações inferidas.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _route(
                  MentalMapNavigationTargets.clinicalDashboard(
                    role: role,
                    patientId: patientId,
                  ),
                  context,
                ),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Abrir dashboard clínico'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InstrumentScorePanel extends StatelessWidget {
  const _InstrumentScorePanel({
    required this.title,
    required this.highlights,
    required this.emptyMessage,
    this.completedAt,
    this.compact = false,
  });

  final String title;
  final List<MentalMapScoreHighlight> highlights;
  final String emptyMessage;
  final DateTime? completedAt;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final rows = highlights.where((h) => h.score != null).toList();
    final maxScore = rows.isEmpty
        ? 10.0
        : rows.map((r) => r.score!).reduce((a, b) => a > b ? a : b);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerLowest
            .withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (completedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Última aplicação: ${loc.formatFullDate(completedAt!.toLocal())}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            if (rows.isEmpty)
              Text(
                emptyMessage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...rows.asMap().entries.map(
                    (entry) => _MentalMapProgressScoreRow(
                      highlight: entry.value,
                      maxScore: maxScore <= 0 ? 10 : maxScore,
                      rank: compact ? null : entry.key + 1,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _MentalMapProgressScoreRow extends StatelessWidget {
  const _MentalMapProgressScoreRow({
    required this.highlight,
    required this.maxScore,
    required this.color,
    this.rank,
  });

  final MentalMapScoreHighlight highlight;
  final double maxScore;
  final Color color;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final score = highlight.score ?? 0;
    final progress = (score / maxScore).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (rank != null) ...[
                CircleAvatar(
                  radius: 11,
                  backgroundColor: color.withValues(alpha: 0.1),
                  child: Text(
                    '$rank',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  highlight.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                highlight.displayScore,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              color: color,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveProblemsPanel extends StatelessWidget {
  const _ActiveProblemsPanel({required this.problems});

  final List<MentalMapProblemSummary> problems;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .errorContainer
            .withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Problemas ativos (por intensidade)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            if (problems.isEmpty)
              Text(
                'Nenhum problema ativo registrado.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else
              ...problems.map((problem) {
                final intensity = problem.intensity;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          problem.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (intensity != null)
                        Text(
                          '$intensity/10',
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class MentalMapHistoryLinksSection extends StatelessWidget {
  const MentalMapHistoryLinksSection({
    super.key,
    required this.history,
    required this.role,
    this.patientId,
  });

  final MentalMapHistoryLinks history;
  final ProfileRole role;
  final String? patientId;

  @override
  Widget build(BuildContext context) {
    if (!history.hasContent) {
      return Column(
        children: [
          const HomologationEmptyPanel(
            icon: Icons.timeline_outlined,
            title: 'História e vínculos vazios',
            message: 'Registre eventos, genograma e instrumentos de vínculo.',
            hint: 'Use a linha do tempo e o genograma na trilha.',
          ),
          if (_route(
            MentalMapNavigationTargets.timeline(
              role: role,
              patientId: patientId,
            ),
            context,
          )
              case final open?)
            TextButton.icon(
              onPressed: open,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir linha do tempo'),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TimelinePanel(
          events: history.timelineEvents,
          onOpen: _route(
            MentalMapNavigationTargets.timeline(
                role: role, patientId: patientId),
            context,
          ),
        ),
        const SizedBox(height: 12),
        _GenogramPanel(
          history: history,
          onOpen: _route(
            MentalMapNavigationTargets.genogram(
                role: role, patientId: patientId),
            context,
          ),
        ),
        if (history.hasParentalFigures) ...[
          const SizedBox(height: 12),
          _ParentalPanel(
            figures: history.parentalFigures,
            onOpen: _route(
              MentalMapNavigationTargets.clinicalDashboard(
                role: role,
                patientId: patientId,
              ),
              context,
            ),
          ),
        ],
        if (history.hasAttachment) ...[
          const SizedBox(height: 12),
          _AttachmentBadge(styleLabel: history.topAttachmentStyle!),
        ],
        if (history.sensitiveItemCount > 0) ...[
          const SizedBox(height: 12),
          HomologationInfoBanner(
            title: 'Itens sensíveis',
            icon: Icons.lock_outline,
            message:
                '${history.sensitiveItemCount} item(ns) sensível(is) nesta camada. '
                'Detalhes completos nos módulos de origem.',
          ),
        ],
      ],
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  const _TimelinePanel({
    required this.events,
    this.onOpen,
  });

  final List<MentalMapTimelineHighlight> events;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return _LayerPanel(
      title: 'Linha do tempo',
      emptyMessage: 'Nenhum evento registrado.',
      onOpen: onOpen,
      openLabel: 'Ver timeline completa',
      child: events.isEmpty
          ? null
          : Column(
              children: events
                  .map(
                    (event) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        event.isSensitive ? Icons.lock_outline : Icons.circle,
                        size: event.isSensitive ? 20 : 10,
                        color: event.isSensitive
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                        event.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        [
                          event.dateLabel,
                          if (event.emotionalImpact != null)
                            'Impacto ${event.emotionalImpact}/10',
                          if (event.subtitleLine != null) event.subtitleLine,
                        ].join(' · '),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _GenogramPanel extends StatelessWidget {
  const _GenogramPanel({
    required this.history,
    this.onOpen,
  });

  final MentalMapHistoryLinks history;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return _LayerPanel(
      title: 'Genograma',
      emptyMessage: 'Genograma ainda não preenchido.',
      onOpen: onOpen,
      openLabel: 'Ver genograma',
      headerSuffix:
          '${history.peopleCount} pessoa(s) · ${history.relationshipCount} relação(ões)',
      child: history.genogramPeople.isEmpty &&
              history.genogramRelationships.isEmpty
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final person in history.genogramPeople)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (person.isSensitive)
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        if (person.isSensitive) const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            person.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (person.isDeceased)
                          Text(
                            'Falecido',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                for (final relationship in history.genogramRelationships)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        if (relationship.isSensitive)
                          Icon(
                            Icons.lock_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        if (relationship.isSensitive) const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            relationship.displayLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _ParentalPanel extends StatelessWidget {
  const _ParentalPanel({
    required this.figures,
    this.onOpen,
  });

  final List<MentalMapParentalFigureHighlight> figures;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return _LayerPanel(
      title: 'Estilos parentais (por figura)',
      onOpen: onOpen,
      openLabel: 'Ver dashboard parentais',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final figure in figures)
            Chip(
              avatar: const Icon(Icons.family_restroom_outlined, size: 18),
              label: Text('${figure.figureLabel}: ${figure.dominantStyle}'),
            ),
        ],
      ),
    );
  }
}

class _AttachmentBadge extends StatelessWidget {
  const _AttachmentBadge({required this.styleLabel});

  final String styleLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.favorite_border),
        title: const Text('Apego'),
        subtitle: Text(styleLabel),
      ),
    );
  }
}

class MentalMapTherapyPlanSection extends StatelessWidget {
  const MentalMapTherapyPlanSection({
    super.key,
    required this.plan,
    required this.role,
    this.patientId,
  });

  final MentalMapTherapyPlan plan;
  final ProfileRole role;
  final String? patientId;

  @override
  Widget build(BuildContext context) {
    if (!plan.hasContent) {
      return Column(
        children: [
          const HomologationEmptyPanel(
            icon: Icons.flag_outlined,
            title: 'Plano terapêutico vazio',
            message:
                'Defina objetivos e faça check-ins para acompanhar o plano.',
            hint: 'Objetivos e problemas aparecem lado a lado, sem inferência.',
          ),
          if (_route(
            MentalMapNavigationTargets.therapyGoals(
              role: role,
              patientId: patientId,
            ),
            context,
          )
              case final open?)
            TextButton.icon(
              onPressed: open,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir objetivos'),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (plan.hasGoals || plan.hasProblems)
          LayoutBuilder(
            builder: (context, constraints) {
              final sideBySide = constraints.maxWidth >= 560;
              final goalsPanel = _GoalsPanel(goals: plan.activeGoals);
              final problemsPanel = _PlanProblemsPanel(
                problems: plan.activeProblems,
              );

              if (sideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: goalsPanel),
                    const SizedBox(width: 12),
                    Expanded(child: problemsPanel),
                  ],
                );
              }
              return Column(
                children: [
                  goalsPanel,
                  const SizedBox(height: 12),
                  problemsPanel,
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        _CheckInPlanPanel(
          plan: plan,
          onOpen: _route(
            MentalMapNavigationTargets.checkIns(
                role: role, patientId: patientId),
            context,
          ),
        ),
        if (plan.resources.hasContent) ...[
          const SizedBox(height: 12),
          _ResourcesPanel(
            resources: plan.resources,
            onOpen: _route(
              MentalMapNavigationTargets.therapyResources(
                role: role,
                patientId: patientId,
              ),
              context,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          'Objetivos e problemas são exibidos por proximidade visual, '
          'sem relação causal inferida.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _GoalsPanel extends StatelessWidget {
  const _GoalsPanel({required this.goals});

  final List<MentalMapGoalSummary> goals;

  @override
  Widget build(BuildContext context) {
    return _LayerPanel(
      title: 'Objetivos ativos',
      emptyMessage: 'Nenhum objetivo ativo.',
      child: goals.isEmpty
          ? null
          : Column(
              children: goals
                  .map(
                    (goal) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.radio_button_unchecked,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      title: Text(goal.title),
                      subtitle: goal.targetDateLabel != null
                          ? Text('Meta: ${goal.targetDateLabel}')
                          : null,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _PlanProblemsPanel extends StatelessWidget {
  const _PlanProblemsPanel({required this.problems});

  final List<MentalMapProblemSummary> problems;

  @override
  Widget build(BuildContext context) {
    return _LayerPanel(
      title: 'Problemas ativos',
      emptyMessage: 'Nenhum problema ativo.',
      child: problems.isEmpty
          ? null
          : Column(
              children: problems
                  .map(
                    (problem) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.report_problem_outlined,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(problem.title),
                      subtitle: Text(problem.statusLabel),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _CheckInPlanPanel extends StatelessWidget {
  const _CheckInPlanPanel({
    required this.plan,
    this.onOpen,
  });

  final MentalMapTherapyPlan plan;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final latest = plan.latestCheckIn;

    return _LayerPanel(
      title: 'Check-in — últimos 7 dias',
      emptyMessage: 'Nenhum check-in registrado.',
      onOpen: onOpen,
      openLabel: 'Ver check-ins',
      child: !plan.hasCheckIns
          ? null
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (plan.sparkline.showChart) ...[
                  MentalMapCheckInSparklineChart(sparkline: plan.sparkline),
                  const SizedBox(height: 12),
                ] else
                  Text(
                    'Registre mais check-ins para ver a tendência.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                if (latest != null)
                  Text(
                    [
                      if (latest.moodScore != null) 'Humor ${latest.moodScore}',
                      if (latest.anxietyScore != null)
                        'Ansiedade ${latest.anxietyScore}',
                      if (latest.energyScore != null)
                        'Energia ${latest.energyScore}',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
    );
  }
}

class _ResourcesPanel extends StatelessWidget {
  const _ResourcesPanel({
    required this.resources,
    this.onOpen,
  });

  final MentalMapResourcesSummary resources;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return _LayerPanel(
      title: 'Recursos terapêuticos',
      onOpen: onOpen,
      openLabel: 'Ver biblioteca',
      child: Text(
        '${resources.releasedCount} liberado(s) · '
        '${resources.completedCount} concluído(s)',
      ),
    );
  }
}

class MentalMapCheckInSparklineChart extends StatelessWidget {
  const MentalMapCheckInSparklineChart({
    super.key,
    required this.sparkline,
  });

  final MentalMapCheckInSparkline sparkline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SparklineRow(
          label: 'Humor',
          points: sparkline.moodPoints,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _SparklineRow(
          label: 'Ansiedade',
          points: sparkline.anxietyPoints,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 8),
        _SparklineRow(
          label: 'Energia',
          points: sparkline.energyPoints,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }
}

class _SparklineRow extends StatelessWidget {
  const _SparklineRow({
    required this.label,
    required this.points,
    required this.color,
  });

  final String label;
  final List<double?> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 32,
            child: CustomPaint(
              painter: _SparklinePainter(
                points: points,
                color: color,
                maxValue: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({
    required this.points,
    required this.color,
    required this.maxValue,
  });

  final List<double?> points;
  final Color color;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final stepX = points.length <= 1 ? 0.0 : size.width / (points.length - 1);
    Offset? previous;

    for (var i = 0; i < points.length; i++) {
      final value = points[i];
      if (value == null) {
        previous = null;
        continue;
      }

      final x = stepX * i;
      final y = size.height - ((value / maxValue) * size.height);

      canvas.drawCircle(Offset(x, y), 2.5, dotPaint);

      if (previous != null) {
        canvas.drawLine(previous, Offset(x, y), paint);
      }
      previous = Offset(x, y);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
  }
}

class _LayerPanel extends StatelessWidget {
  const _LayerPanel({
    required this.title,
    this.emptyMessage,
    this.headerSuffix,
    this.child,
    this.onOpen,
    this.openLabel = 'Ver detalhes',
  });

  final String title;
  final String? emptyMessage;
  final String? headerSuffix;
  final Widget? child;
  final VoidCallback? onOpen;
  final String openLabel;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (headerSuffix != null)
                  Text(
                    headerSuffix!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (child == null && emptyMessage != null)
              Text(
                emptyMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            else if (child != null)
              child!,
            if (onOpen != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(openLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

VoidCallback? _route(String? path, BuildContext context) {
  if (path == null) return null;
  return () => context.push(path);
}
